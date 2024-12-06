#!/bin/bash

CONFIG_FILE=config.json
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE=config.example.json
fi

DISCORD_WEBHOOK=$(jq -r '.lgsm_update.webhook_url' "$CONFIG_FILE")
ENABLE_LOGGING=$(jq -r '.lgsm_update.enable_logging' "$CONFIG_FILE")
ENABLE_LOGGING=${ENABLE_LOGGING,,}
LOG_FILE=$(jq -r '.lgsm_update.log_file' "$CONFIG_FILE")

AUTO_UPDATE=$(jq -r '.lgsm_update.auto_update' "$CONFIG_FILE")
AUTO_UPDATE=${AUTO_UPDATE,,}

OUTPUT_FILE="server-status-lgsm-temp.json"
UPDATED_SERVERS="updated-servers-lgsm-temp.json"
CHECK_INTERVAL=$(jq -r '.lgsm_update.update_check_interval' "$CONFIG_FILE")
CHECK_USER=$(jq -r '.lgsm_update.update_check_user' "$CONFIG_FILE")

GAME=$(jq -r '.lgsm_update.game' "$CONFIG_FILE")

if [ -z "$GAME" ]; then
    GAME="cs2"
fi

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
    echo "[]" > "$UPDATED_SERVERS"
fi

query_server() {
    local user="$1"
    local address="${2:-"192.168.1.8:27015"}"
    local type="${3:-local}"
    local ip="${address%:*}"
    local port="${address##*:}"
    local ssh_key="${4:-}"
    local ssh_port="${5:-22}"
    local ssh_address="${6:-$ip}"
    local ssh_pass="${7:-}"

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
        
        if [[ "$AUTO_UPDATE" == "true" ]]; then
            if [[ "$type" == "local" ]]; then
                log "Updating local server: $address"
                sudo -iu "$user" /home/"$user"/"$GAME"server update
                if [ $? -eq 0 ]; then
                    log "Update completed successfully"
                else
                    log "Update encountered an error"
                fi
            elif [[ "$type" == "remote_key" ]]; then
                log "Updating remote server with SSH key auth: $address"
                if [ -z "$ssh_key" ]; then
                    log "SSH key not provided for remote server. Skipping update."
                    return 1
                fi
                ssh -i "$ssh_key" -p "$ssh_port" "$user@$ssh_address" "sudo -iu "$user" /home/"$user"/"$GAME"server update"
                if [ $? -eq 0 ]; then
                    log "Update completed successfully"
                else
                    log "Update encountered an error"
                fi
            elif [[ "$type" == "remote_pass" ]]; then
                log "Updating remote server with password auth: $address"
                if ! command -v sshpass &> /dev/null; then
                    log "sshpass could not be found, please install it."
                    return 1
                fi
                sshpass -p "$ssh_pass" ssh -p "$ssh_port" "$user@$ssh_address" "sudo -iu "$user" /home/"$user"/"$GAME"server update"
                if [ $? -eq 0 ]; then
                    log "Update completed successfully"
                else
                    log "Update encountered an error"
                fi
            fi
        fi
    elif [[ "$server_status" == "EMPTY" ]]; then
        log "Server $address is EMPTY"
        jq -n \
            --arg server "$address" \
            --arg status "EMPTY" \
            '{"server": $server, "status": $status}' >> "$OUTPUT_FILE"
        echo "," >> "$OUTPUT_FILE"

        if [[ "$AUTO_UPDATE" == "true" ]]; then
            if [[ "$type" == "local" ]]; then
                log "Updating local server: $address"
                sudo -iu "$user" /home/"$user"/"$GAME"server update
                if [ $? -eq 0 ]; then
                    log "Update completed successfully"
                else
                    log "Update encountered an error"
                fi
            elif [[ "$type" == "remote_key" ]]; then
                log "Updating remote server with SSH key auth: $address"
                if [ -z "$ssh_key" ]; then
                    log "SSH key not provided for remote server. Skipping update."
                    return 1
                fi
                ssh -i "$ssh_key" -p "$ssh_port" "$user@$ssh_address" "cd /home/"$user" && ./"$GAME"server update"
                if [ $? -eq 0 ]; then
                    log "Update completed successfully"
                else
                    log "Update encountered an error"
                fi
            elif [[ "$type" == "remote_pass" ]]; then
                log "Updating remote server with password auth: $address"
                if ! command -v sshpass &> /dev/null; then
                    log "sshpass could not be found, please install it."
                    return 1
                fi
                sshpass -p "$ssh_pass" ssh -p "$ssh_port" "$user@$ssh_address" "cd /home/"$user" && ./"$GAME"server update"
                if [ $? -eq 0 ]; then
                    log "Update completed successfully"
                else
                    log "Update encountered an error"
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
    local servers=($(jq -c '.lgsm_update.servers_to_update[]' "$CONFIG_FILE"))

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
            user=$(echo "$server" | jq -r '.user')
            address=$(echo "$server" | jq -r '.address')
            type=$(echo "$server" | jq -r '.type')
            ip="${address%:*}"
            port="${address##*:}"
            ssh_key=$(echo "$server" | jq -r '.ssh_key // empty')
            ssh_port=$(echo "$server" | jq -r '.ssh_port // "22"')
            ssh_address=$(echo "$server" | jq -r '.ssh_address // $ip')
            ssh_pass=$(echo "$server" | jq -r '.ssh_pass // empty')

            if jq -e --arg server "$address" '. | index($server)' "$UPDATED_SERVERS" > /dev/null; then
                log "Server $address already updated. Skipping."
                continue
            fi

            query_server "$user" "$address" "$type" "$ssh_key" "$ssh_port" "$ssh_address" "$ssh_pass"
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

check_for_new_updates () {
    while true; do
        if [ "$UPDATE_TRIGGERED" = true ]; then
            log "Update triggered. Pausing check for new updates until all servers are updated."
            sleep "$CHECK_INTERVAL"
            continue
        fi

        check_update_command=$(sudo -iu $CHECK_USER /home/$CHECK_USER/"$GAME"server check-update)

        local_build=$(echo "$check_update_command" | grep "Local build" | sed -E 's/.*Local build: ([0-9]+).*/\1/')
        remote_build=$(echo "$check_update_command" | grep "Remote build" | sed -E 's/.*Remote build: ([0-9]+).*/\1/')

        if [[ -z "$local_build" || -z "$remote_build" ]]; then
            echo "Error: Unable to extract build versions from the output."
            exit 1
        fi

        if [ "$local_build" -eq "$remote_build" ]; then
            log "No update available. Local build: $local_build, Remote build: $remote_build"
        else
            log "Update available! Local build: $local_build, Remote build: $remote_build"
            UPDATE_TRIGGERED=true
            monitor_servers
        fi

        sleep "$CHECK_INTERVAL"
    done
}

log "Starting Check for CS2 Updates... Checking every $CHECK_INTERVAL seconds..."
check_for_new_updates
