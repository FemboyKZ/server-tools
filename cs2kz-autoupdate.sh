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
BUILD_RESULTS_DIR="${REPO_DIR}/build/package/addons/cs2kz/"
DEST_DIRS=$(jq -r '.cs2kz_autoupdate.destination_dirs[]' "$CONFIG_FILE")

FILES_TO_CHECK=$(jq -r '.cs2kz_autoupdate.files_to_check[]' "$CONFIG_FILE")
DISCORD_WEBHOOK=$(jq -r '.cs2kz_autoupdate.webhook_url' "$CONFIG_FILE")
LOG_FILE=$(jq -r '.cs2kz_autoupdate.log_file' "$CONFIG_FILE")

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE" || { log "Failed to create log file at \`$LOG_FILE\`"; exit 1; }
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

exec > >(while read -r line; do log "$line"; done) 2>&1

RED=16711680
YELLOW=16776960
GREEN=65280
BLUE=255

send_discord_notification_embed() {
    local title="$1"
    local description="$2"
    local color="$3"
    
    curl -H "Content-Type: application/json" -X POST -d "{
        \"embeds\": [{
            \"title\": \"$title\",
            \"description\": \"$description\",
            \"color\": $color
        }]
    }" "$DISCORD_WEBHOOK"
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
            if git diff --name-only HEAD..upstream/"$UPSTREAM_BRANCH" | grep -q "$FILE"; then
                FILES_CHANGED=true
                log "Detected changes to $FILE."
            fi
        done
        
        log "Starting build process..."
        bash -c "cd build && python3 ../configure.py && ambuild;"
        
        if [ $? -eq 0 ]; then
            log "Build completed successfully."
            send_discord_notification_embed \
                "✔️ Build Successful" \
                "Build successful for branch \`$LOCAL_BRANCH\`. Uploading build results..." \
                "$GREEN"

            if [ "$FILES_CHANGED" = false ]; then
                log "No changes detected in specified files. Copying build results to all destinations..."
                
                for DEST_DIR in "${DEST_DIRS[@]}"; do
                    if [ ! -d "$DEST_DIR" ]; then
                        log "Destination directory \`$DEST_DIR\` does not exist. Skipping..."
                        continue
                    fi
                    
                    log "Copying build results to \`$DEST_DIR\`..."
                    for DEST_DIR in "${DEST_DIRS[@]}"; do
                        USER=$(log "$DEST_DIR" | cut -d: -f2)
                        DIR=$(log "$DEST_DIR" | cut -d: -f1)
                        sudo rsync -a --delete --chown=$USER:$USER "$BUILD_RESULTS_DIR/" "$DIR/"
                    done
                    if [ $? -eq 0 ]; then
                        log "Build results successfully copied to all destinations."
                    else
                        log "Failed to copy build results to all destinations."
                    fi
                done
                
                log "All build results have been copied."
            else
                log "Specified files have changed. Build results will not be copied."
                send_discord_notification_embed \
                    "⚠️ Monitored Files Changed" \
                    "Monitored files were modified in the upstream changes. Build results were not copied." \
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
