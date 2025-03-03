#!/bin/bash

CONFIG_FILE=config.json
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE=config.example.json
fi

LOCAL_BRANCH=$(jq -r '.cs2kz_autoupdate.local_branch' "$CONFIG_FILE")
UPSTREAM_BRANCH=$(jq -r '.cs2kz_autoupdate.upstream_branch' "$CONFIG_FILE")
UPSTREAM_REPO=$(jq -r '.cs2kz_autoupdate.upstream_repo' "$CONFIG_FILE")

REPO_DIR=$(jq -r '.cs2kz_autoupdate.repo_dir' "$CONFIG_FILE")
UPLOAD_FOLDER="$REPO_DIR/build/package/addons/cs2kz/"

FILES_TO_CHECK=$(jq -r '.cs2kz_autoupdate.files_to_check[]' "$CONFIG_FILE")

DISCORD_WEBHOOK=$(jq -r '.cs2kz_autoupdate.webhook_url' "$CONFIG_FILE")
ENABLE_LOGGING=$(jq -r '.cs2kz_autoupdate.enable_logging' "$CONFIG_FILE")
ENABLE_LOGGING=${ENABLE_LOGGING,,}
LOG_FILE=$(jq -r '.cs2kz_autoupdate.log_file' "$CONFIG_FILE")
BUILD_LOG_FILE=$(jq -r '.cs2kz_autoupdate.build_log_file' "$CONFIG_FILE")

AUTO_UPDATE=$(jq -r '.cs2kz_autoupdate.auto_update' "$CONFIG_FILE")
AUTO_UPDATE=${AUTO_UPDATE,,}

ENABLE_BUILDS=$(jq -r '.cs2kz_autoupdate.enable_builds' "$CONFIG_FILE")
ENABLE_BUILDS=${ENABLE_BUILDS,,}
OUTPUT_FILE="server-status-kz-temp.json"
UPDATED_SERVERS="updated-servers-kz-temp.json"
CHECK_INTERVAL=$(jq -r '.cs2kz_autoupdate.update_check_interval' "$CONFIG_FILE")

ALL_SERVERS_UPDATED=false
UPDATE_TRIGGERED=false

RED=16711680
YELLOW=16776960
GREEN=65280
BLUE=255

log() {
    if [ "$ENABLE_LOGGING" = true ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    fi
}

if ! command -v jq &> /dev/null; then
    log "jq could not be found, please install it."
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    log "Configuration file not found!"
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE" || { log "Failed to create log file at \`$LOG_FILE\`"; exit 1; }
fi

if [ ! -f "$BUILD_LOG_FILE" ]; then
    touch "$BUILD_LOG_FILE" || { log "Failed to create build log file at \`$BUILD_LOG_FILE\`"; exit 1; }
fi

exec > >(while read -r line; do log "$line"; done) 2>&1

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

    if [ -n "$DISCORD_WEBHOOK" ] && [ "$DISCORD_WEBHOOK" != "null" ]; then
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X POST -d "$payload" "$DISCORD_WEBHOOK")
        if [ "$response" -eq 204 ]; then
            log "Successfully posted log to Discord."
        else
            log "Failed to post log to Discord. HTTP response code: $response" >&2
        fi
    fi
}

if [ -z "$UPDATED_SERVERS" ]; then
    touch "$UPDATED_SERVERS"
    echo "[]" > "$UPDATED_SERVERS"
fi

run_lftp_mirror() {
    local user="$1"
    local address="$2"
    local password="$3"
    local folder="$4"
    local remote_folder="$5"

    lftp -u "$user","$password" "$address" <<EOF
mirror -R "$folder" "$remote_folder"
bye
EOF
}

query_server() {
    local folder="${1:-}"
    local user="${2:-}"
    local address="${3:-"192.168.1.8:27015"}"
    local type="${4:-local}"
    local ip="${address%:*}"
    local port="${address##*:}"
    local ssh_key="${5:-}" 
    local ssh_port="${6:-22}"
    local ssh_address="${7:-$ip}"
    local ssh_pass="${8:-}" 

    echo "Checking server: $address"

    PYTHON_OUTPUT=$(python3 query_server.py "$ip" "$port")
    if [ $? -ne 0 ]; then
        log "Failed to query server $address"
        return 1
    fi

    server_status=$(echo "$PYTHON_OUTPUT" | jq -r '.status')
    if [ $? -ne 0 ]; then
        log "Failed to parse JSON response for server $address"
        return 1
    fi

    if [[ "$server_status" == "OFFLINE" ]]; then
        log "Server $address is OFFLINE"
        jq -n \
            --arg server "$address" \
            --arg status "OFFLINE" \
            '{"server": $server, "status": $status}' >> "$OUTPUT_FILE"
        echo "," >> "$OUTPUT_FILE"
        return 1
    elif [[ "$server_status" == "EMPTY" ]]; then
        log "Server $address is EMPTY"
        jq -n \
            --arg server "$address" \
            --arg status "EMPTY" \
            '{"server": $server, "status": $status}' >> "$OUTPUT_FILE"
        echo "," >> "$OUTPUT_FILE"

        if [[ "$AUTO_UPDATE" == "true" ]]; then
            if [[ "$type" == "local" ]]; then
                log "Uploading to local server: $address"
                sudo rsync -avz --delete --chown="$user:$user" "$UPLOAD_FOLDER" "$folder"
                if [ $? -eq 0 ]; then
                    log "rsync completed successfully"
                else
                    log "rsync encountered an error"
                fi
            elif [[ "$type" == "remote_key" ]]; then
                log "Uploading to remote server via ssh, authorizing with ssh key: $address"
                if [ -z "$ssh_key" ]; then
                    log "SSH key not provided for remote server. Skipping update."
                    return 1
                fi
                rsync -avz -e "ssh -i $ssh_key -p $ssh_port" "$UPLOAD_FOLDER" "$user@$ssh_address:$folder"
                ssh -i "$ssh_key" -p "$ssh_port" "$user@$ssh_address" "chown -R $user:$user $folder"
                if [ $? -eq 0 ]; then
                    log "rsync completed successfully"
                else
                    log "rsync encountered an error"
                fi
            elif [[ "$type" == "remote_pass" ]]; then
                log "Uploading to remote server via ssh, authorizing with password: $address"
                if ! command -v sshpass &> /dev/null; then
                    log "sshpass could not be found, please install it."
                    return 1
                fi
                sshpass -p "$ssh_pass" rsync -avz -e "ssh -p $ssh_port" "$UPLOAD_FOLDER" "$user@$ssh_address:$folder"
                sshpass -p "$ssh_pass" ssh -p "$ssh_port" "$user@$ssh_address" "chown -R $user:$user $folder"
                if [ $? -eq 0 ]; then
                    log "rsync completed successfully"
                else
                    log "rsync encountered an error"
                fi
            elif [[ "$type" == "remote_ftp" ]]; then
                log "Uploading to FTP server: $address"
                if ! command -v lftp &> /dev/null; then
                    log "lftp could not be found, please install it."
                    return 1
                fi
                run_lftp_mirror "$user" "$ssh_address" "$ssh_pass" "$UPLOAD_FOLDER" "$folder"
                if [ $? -eq 0 ]; then
                    log "lftp mirror completed successfully"
                else
                    log "lftp mirror encountered an error"
                fi
            fi
        fi

        jq --arg server "$address" '. + [$server]' "$UPDATED_SERVERS" > "$UPDATED_SERVERS.tmp" && mv "$UPDATED_SERVERS.tmp" "$UPDATED_SERVERS"

    elif [[ "$server_status" == "ACTIVE" ]]; then
        log "Server $address is ACTIVE"
        jq -n \
            --arg server "$address" \
            --arg status "ACTIVE" \
            '{"server": $server, "status": $status}' >> "$OUTPUT_FILE"
        echo "," >> "$OUTPUT_FILE"
        return 2
    else
        log "Error: Unable to determine server status for $address"
        return 3
    fi
}

monitor_servers() {
    local servers=($(jq -c '.cs2kz_autoupdate.servers_to_update[]' "$CONFIG_FILE"))

    if [ "${#servers[@]}" -eq 0 ]; then
        log "No servers specified in config file. Skipping server monitoring."
        return 1
    fi

    while true; do
        if [ "$ALL_SERVERS_UPDATED" = true ]; then
            log "All servers have been updated. Stopping server monitoring."
            break
        fi

        echo "[" > "$OUTPUT_FILE"

        for server in "${servers[@]}"; do
            folder=$(echo "$server" | jq -r '.folder')
            user=$(echo "$server" | jq -r '.user')
            address=$(echo "$server" | jq -r '.address')
            type=$(echo "$server" | jq -r '.type // "local"')
            ip="${address%:*}"
            port="${address##*:}"
            ssh_key=$(echo "$server" | jq -r '.ssh_key // empty')
            ssh_port=$(echo "$server" | jq -r '.ssh_port // "22"')
            ssh_address=$(echo "$server" | jq -r '.ssh_address // "$ip"')
            ssh_pass=$(echo "$server" | jq -r '.ssh_pass // empty')

            if jq -e --arg server "$address" '. | index($server)' "$UPDATED_SERVERS" > /dev/null; then
                log "Server $address already updated. Skipping."
                continue
            fi

            query_server "$folder" "$user" "$address" "$type" "$ssh_key" "$ssh_port" "$ssh_address" "$ssh_pass"
        done

        sed -i '$ s/,$//' "$OUTPUT_FILE"
        echo "]" >> "$OUTPUT_FILE"

        if [ "$(jq length "$UPDATED_SERVERS")" -eq "${#servers[@]}" ]; then
            ALL_SERVERS_UPDATED=true
            UPDATE_TRIGGERED=false
        fi

        log "Waiting $CHECK_INTERVAL seconds before rechecking..."
        sleep "$CHECK_INTERVAL"
    done
}

check_for_new_commits() {
    while true; do
        if [ "$UPDATE_TRIGGERED" = true ]; then
            log "Update triggered. Pausing check for new commits until all servers are updated."
            sleep "$CHECK_INTERVAL"
            continue
        fi

        cd "$REPO_DIR" || { 
            log "Repository not found at \`$REPO_DIR\`"
            exit 1
        }

        if ! git remote -v | grep -q "upstream"; then
            log "Upstream repository not configured, attempting to set URL..."
            if ! git remote set-url upstream "$UPSTREAM_REPO"; then
                log "Error setting upstream repository URL, attempting to add..."
                if ! git remote add upstream "$UPSTREAM_REPO"; then
                    log "Error adding upstream repository."
                    exit 1
                fi
            fi
        fi

        if ! git fetch upstream; then
            log "Error fetching from upstream repository."
            exit 1
        fi

        new_commits=$(git rev-list HEAD..upstream/"$UPSTREAM_BRANCH" --count)

        if [ "$new_commits" -gt 0 ]; then
            log "Found $new_commits new commit(s). Attempting to merge changes..."
            send_discord_notification_embed \
                "⚠️ New Upstream Changes" \
                "Found $new_commits new commit(s) in upstream \`$UPSTREAM_BRANCH\`. Attempting to merge changes..." \
                "$BLUE"

            if ! git checkout "$LOCAL_BRANCH"; then
                log "Error checking out branch."
                send_discord_notification_embed \
                    "❌ Error Checking Out Branch" \
                    "Error checking out branch \`$LOCAL_BRANCH\`" \
                    "$RED"
                exit 1
            fi

            if ! merge_commits=$(git merge -m "Automated merge of upstream/$UPSTREAM_BRANCH" \
                    --no-ff --strategy=recursive --strategy-option=ours -S \
                    upstream/"$UPSTREAM_BRANCH"); then
                log "Error merging upstream changes."
                send_discord_notification_embed \
                    "❌ Merge Conflict" \
                    "Merge failed for branch \`$LOCAL_BRANCH\` with upstream \`$UPSTREAM_BRANCH\`. Manual intervention required." \
                    "$RED"
                exit 1
            fi

            if ! git push origin "$LOCAL_BRANCH"; then
                log "Error pushing changes."
                send_discord_notification_embed \
                    "❌ Error Pushing Changes" \
                    "Error pushing changes to upstream \`$UPSTREAM_BRANCH\`" \
                    "$RED"
                exit 1
            fi

            log "Merge and push successful. Checking for specific file changes..."
            FILES_CHANGED=false
            for FILE in "${FILES_TO_CHECK[@]}"; do
                log "Checking for changes in file: $FILE"
                if echo "$merge_commits" | grep -q "$FILE"; then
                    FILES_CHANGED=true
                    log "Detected changes to $FILE."
                fi
            done

            if [ "$FILES_CHANGED" = true ]; then
                log "Specified files have changed. Further actions may be needed."
            else
                log "No changes detected in monitored files."
                log "Starting Build..."
                build_project
                UPDATE_TRIGGERED=true
            fi
        else
            log "No new commits found. Repository is up-to-date."
        fi

        sleep "$CHECK_INTERVAL"
    done
}

build_project() {
    cd "$REPO_DIR" || {
        log "Repository not found at \`$REPO_DIR\`"
        exit 1
    }

    cd build || {
        log "Build directory not found at \`$REPO_DIR/build\`"
        if mkdir build; then
            log "Build directory created at \`$REPO_DIR/build\`"
            cd build || exit 1
        else
            log "Failed to create build directory at \`$REPO_DIR/build\`"
            exit 1
        fi
    }

    if [ "$ENABLE_LOGGING" = true ]; then
        bash -c "python3 ../configure.py && ambuild;" >> "$BUILD_LOG_FILE" 2>&1
    else
        bash -c "python3 ../configure.py && ambuild;"
    fi

    if [ $? -eq 0 ]; then
        log "Build completed successfully."
        send_discord_notification_embed \
            "✔️ Build Successful" \
            "Build successful for branch \`$LOCAL_BRANCH\`. Free to upload build results." \
            "$GREEN"
        log "resetting updated server list..."
        echo "[]" > "$UPDATED_SERVERS"
        ALL_SERVERS_UPDATED=false
        log "Monitoring servers every $CHECK_INTERVAL seconds..."
        monitor_servers
    else
        log "Build failed."
        send_discord_notification_embed \
            "❌ Build Failed" \
            "Build failed for branch \`$LOCAL_BRANCH\`. Manual intervention required." \
            "$RED"
    fi
}   

log "Starting Check for Upstream Changes... Checking every $CHECK_INTERVAL seconds..."
check_for_new_commits
