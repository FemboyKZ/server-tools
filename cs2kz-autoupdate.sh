#!/bin/bash

if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it."
    exit 1
fi

CONFIG_FILE=config.json
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE=config.example.json
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found!"
    exit 1
fi

LOCAL_BRANCH=$(jq -r '.cs2kz_autoupdate.local_branch' "$CONFIG_FILE")
UPSTREAM_BRANCH=$(jq -r '.cs2kz_autoupdate.upstream_branch' "$CONFIG_FILE")
UPSTREAM_REPO=$(jq -r '.cs2kz_autoupdate.upstream_repo' "$CONFIG_FILE")

REPO_DIR=$(jq -r '.cs2kz_autoupdate.repo_dir' "$CONFIG_FILE")

FILES_TO_CHECK=$(jq -r '.cs2kz_autoupdate.files_to_check[]' "$CONFIG_FILE")

DISCORD_WEBHOOK=$(jq -r '.cs2kz_autoupdate.webhook_url' "$CONFIG_FILE")
ENABLE_LOGGING=$(jq -r '.cs2kz_autoupdate.enable_logging' "$CONFIG_FILE")
ENABLE_LOGGING=${ENABLE_LOGGING,,}
LOG_FILE=$(jq -r '.cs2kz_autoupdate.log_file' "$CONFIG_FILE")
BUILD_LOG_FILE=$(jq -r '.cs2kz_autoupdate.build_log_file' "$CONFIG_FILE")

UPLOAD_RESULTS=$(jq -r '.cs2kz_autoupdate.upload_results' "$CONFIG_FILE")
UPLOAD_RESULTS=${UPLOAD_RESULTS,,}

OUTPUT_FILE="server-status-temp.json"

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE" || { echo "Failed to create log file at \`$LOG_FILE\`"; exit 1; }
fi

if [ ! -f "$BUILD_LOG_FILE" ]; then
    touch "$BUILD_LOG_FILE" || { echo "Failed to create build log file at \`$BUILD_LOG_FILE\`"; exit 1; }
fi

log() {
    if [ "$ENABLE_LOGGING" = true ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$BUILD_LOG_FILE"
    fi
}

if [ "$ENABLE_LOGGING" = true ]; then
    exec > >(while read -r line; do log "$line"; done) 2>&1
fi

RED=16711680
YELLOW=16776960
GREEN=65280
BLUE=255

send_discord_notification_embed() {
    local title="$1"
    local description="$2"
    local color="$3"
    
    title=$(echo "$title" | sed 's/"/\\"/g')
    description=$(echo "$description" | sed 's/"/\\"/g')
    
    local payload="{
        \"embeds\": [{
            \"title\": \"$title\",
            \"description\": \"$description\",
            \"color\": $color
        }]
    }"

    if [ "$ENABLE_LOGGING" = true ] && [ -n "$DISCORD_WEBHOOK" ] && [ "$DISCORD_WEBHOOK" != "null" ]; then
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X POST -d "$payload" "$DISCORD_WEBHOOK")
        if [ "$response" -eq 200 ]; then
            log "Successfully posted log to Discord."
        else
            log "Failed to post log to Discord. HTTP response code: $response" >&2
        fi
    fi
}


query_server() {
    local server="$1"

    QSTAT_OUTPUT=$(qstat -a2s "$server")

    if [[ -z "$QSTAT_OUTPUT" || "$QSTAT_OUTPUT" =~ -- ]]; then
        jq -n \
            --arg server "$server" \
            --arg status "OFFLINE" \
            '{"server": $server, "status": $status}' >> "$OUTPUT_FILE"
        echo "," >> "$OUTPUT_FILE"
        return
    fi

    SERVER_INFO=$(echo "$QSTAT_OUTPUT" | tail -n 1)
    PLAYERS=$(echo "$SERVER_INFO" | awk '{print $2}')

    CURRENT_PLAYERS=$(echo "$PLAYERS" | cut -d'/' -f1)

    if [[ "$CURRENT_PLAYERS" -eq 0 ]]; then
        STATUS="EMPTY"
    else
        STATUS="ACTIVE"
    fi

    jq -n \
        --arg server "$server" \
        --arg status "$STATUS" \
        '{"server": $server, "status": $status}' >> "$OUTPUT_FILE"
    echo "," >> "$OUTPUT_FILE"
}

log "Starting Check for Upstream Changes..."

cd "$REPO_DIR" || { log "Repository not found at \`$REPO_DIR\`"; exit 1; }

if ! git remote -v | grep -q "upstream"; then
  log "Upstream repository not configured, attempting to set URL..."
    if ! git remote set-url upstream "$UPSTREAM_REPO"; then
    log "Error setting upstream repository URL, attempting to add..."
    if ! git remote add upstream "$UPSTREAM_REPO"; then
      log "Error adding upstream repository"
      exit 1
    fi
  fi
fi

if ! git fetch upstream; then
  log "Error fetching from upstream repository."
  exit 1
fi

NEW_COMMITS=$(git rev-list HEAD..upstream/$UPSTREAM_BRANCH --count)

if [ "$NEW_COMMITS" -gt 0 ]; then
    log "Found $NEW_COMMITS new commit(s). Attempting to merge changes..."
    send_discord_notification_embed \
        "⚠️ New Upstream Changes" \
        "Found $NEW_COMMITS new commit(s) in upstream \`$UPSTREAM_BRANCH\`. Attempting to merge changes..." \
        "$BLUE"

    if ! git checkout "$LOCAL_BRANCH"; then
        log "Error Checking Out Branch"
        send_discord_notification_embed \
            "❌ Error Checking Out Branch" \
            "Error checking out branch \`$LOCAL_BRANCH\`" \
            "$RED"
        exit 1
    fi
    
    if ! git merge -m "Automated merge of upstream/$UPSTREAM_BRANCH" --no-ff --strategy=recursive --strategy-option=ours -S upstream/"$UPSTREAM_BRANCH"; then
        log "Error merging upstream changes"
        exit 1
    fi
    
    if ! git push origin "$LOCAL_BRANCH"; then
        log "Error pushing changes"
        send_discord_notification_embed \
            "❌ Error Pushing Changes" \
            "Error pushing changes to upstream \`$UPSTREAM_BRANCH\`" \
            "$RED"
        exit 1
    fi

    if [ $? -eq 0 ]; then
        log "Merge and push successful. Checking for specific file changes..."
        
        FILES_CHANGED=false
        for FILE in "${FILES_TO_CHECK[@]}"; do
            log "Checking for changes in file: $FILE"
            CHANGED_FILES=$(git diff --name-only HEAD..upstream/"$UPSTREAM_BRANCH")
            log "Changed files: $CHANGED_FILES"
            if echo "$CHANGED_FILES" | grep -q "$FILE"; then
                FILES_CHANGED=true
                log "Detected changes to $FILE."
            fi
        done
        
        log "Starting build process..."
        if [ "$ENABLE_LOGGING" = true ]; then
            bash -c "cd build && python3 ../configure.py && ambuild;" >> "$BUILD_LOG" 2>&1
        else
            bash -c "cd build && python3 ../configure.py && ambuild;"
        fi
        
        if [ $? -eq 0 ]; then
            log "Build completed successfully."
            send_discord_notification_embed \
                "✔️ Build Successful" \
                "Build successful for branch \`$LOCAL_BRANCH\`. Free to upload build results." \
                "$GREEN"

            if [ "$FILES_CHANGED" = false ]; then
                log "No changes detected in specified files. Free to upload build results."
                send_discord_notification_embed \
                    "🔄 No Changes Detected" \
                    "No changes detected in specified files. Free to upload build results." \
                    "$BLUE"

                if [ "$ENABLE_UPLOAD" = true ]; then
                    log "Uploads enabled. Uploading build results..."
                    jq -c '.cs2kz_autoupdate.servers_to_update[]' "$CONFIG_FILE" | while read -r server; do
                        folder=$(echo "$server" | jq -r '.folder')
                        user=$(echo "$server" | jq -r '.user')
                        address=$(echo "$server" | jq -r '.address')

                        if [ ! -f "$OUTPUT_FILE" ]; then
                            touch "$OUTPUT_FILE" || { echo "Failed to create output file at \`$OUTPUT_FILE\`"; exit 1; }
                        fi

                        echo "[" > "$OUTPUT_FILE"

                        for server in "${servers_to_update[@]}"; do
                            log "Updating server: $server"
                            query_server "$address"
                        done
                        sed -i '$ s/,$//' "$OUTPUT_FILE"
                        echo "]" >> "$OUTPUT_FILE"
                    done
                else
                    log "Uploads disabled. Skipping upload."
                fi
            else
                log "Specified files have changed. Build results will not be copied."
                send_discord_notification_embed \
                    "⚠️ Monitored Files Changed" \
                    "Monitored files were modified in the upstream changes. Build results should be manually checked." \
                    "$YELLOW"
            fi
        else
            log "Build failed!"
            send_discord_notification_embed \
                "❌ Build Failed" \
                "The build for branch \`$LOCAL_BRANCH\` failed after merging upstream \`$UPSTREAM_BRANCH\`." \
                "$RED"
            exit 1
        fi
    else
        log "Merge failed. Please resolve conflicts manually."
        send_discord_notification_embed \
            "❌ Merge Conflict" \
            "Merge failed for branch \`$LOCAL_BRANCH\` with upstream \`$UPSTREAM_BRANCH\`. Manual intervention required." \
            "$RED"
        exit 1
    fi
else
    log "No new commits found. Repository is up-to-date."
    exit 0
fi

exit 0
