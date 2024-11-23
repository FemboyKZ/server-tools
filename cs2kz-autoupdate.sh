#!/bin/bash

# Define variables
LOCAL_BRANCH="fkz-auto"     # Replace with your local branch name
UPSTREAM_BRANCH="dev"       # Replace with the upstream branch name

# Replace with your build command
BUILD_COMMAND="cd build && python3 ../configure.py && ambuild"

# Replace with the path to your local repo
REPO_DIR="/home/web-misc/server-tools/cs2kz-metamod/"

# Replace with the path to your build results directory
BUILD_RESULTS_DIR="${REPO_DIR}/build/package/addons/cs2kz/"

# Replace with the destination directory for build results
DEST_DIRS=(
    "/home/cs2-fkz-1/serverfiles/game/csgo/addons/cs2kz:cs2-fkz-1"
    "/home/cs2-fkz-2/serverfiles/game/csgo/addons/cs2kz:cs2-fkz-2"
    "/home/cs2-fkz-3/serverfiles/game/csgo/addons/cs2kz:cs2-fkz-3"
    "/home/cs2-fkz-5/serverfiles/game/csgo/addons/cs2kz:cs2-fkz-5"
)

# Replace with the list of specific files to monitor for changes, leave empty if not needed
FILES_TO_CHECK=("cs2kz-server-config.txt" "cs2kz.cfg" "kz_mode_ckz.cpp" "kz_mode_ckz.h")

# Logs & Discord webhook
DISCORD_WEBHOOK="https://discord.com/api/webhooks/your_webhook_id/your_webhook_token"
LOG_FILE="/var/log/cs2kz-autoupdate.log"

# Colors
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

cd "$REPO_DIR" || { echo "Repository not found at $REPO_DIR"; exit 1; }
git fetch upstream
NEW_COMMITS=$(git rev-list HEAD..upstream/$UPSTREAM_BRANCH --count)

if [ "$NEW_COMMITS" -gt 0 ]; then
    echo "Found $NEW_COMMITS new commit(s). Merging changes..."
    send_discord_notification_embed \
        "⚠️ New Upstream Changes" \
        "Found $NEW_COMMITS new commit(s) in upstream \`$UPSTREAM_BRANCH\`. Merging changes..." \
        $BLUE
    
    git checkout "$LOCAL_BRANCH"
    git pull

    if [ $? -eq 0 ]; then
        echo "Merge successful. Checking for specific file changes..."
        send_discord_notification_embed \
            "✔️ Merge Successful" \
            "Merge successful for branch \`$LOCAL_BRANCH\` with upstream \`$UPSTREAM_BRANCH\`. Checking for specific file changes..." \
            $GREEN
        
        FILES_CHANGED=false
        for FILE in "${FILES_TO_CHECK[@]}"; do
            if git diff --name-only HEAD~1 | grep -q "$FILE"; then
                FILES_CHANGED=true
                echo "Detected changes to $FILE."
            fi
        done
        
        echo "Starting build process..."
        $BUILD_COMMAND
        
        if [ $? -eq 0 ]; then
            echo "Build completed successfully."
            send_discord_notification_embed \
                "✔️ Build Successful" \
                "Build successful for branch \`$LOCAL_BRANCH\`. Uploading build results..." \
                $GREEN

            if [ "$FILES_CHANGED" = false ]; then
                echo "No changes detected in specified files. Copying build results to all destinations..."
                
                for DEST_DIR in "${DEST_DIRS[@]}"; do
                    if [ ! -d "$DEST_DIR" ]; then
                        echo "Destination directory $DEST_DIR does not exist. Skipping..."
                        continue
                    fi
                    
                    echo "Copying build results to $DEST_DIR..."
                    for DEST_DIR in "${DEST_DIRS[@]}"; do
                        USER=$(echo "$DEST_DIR" | cut -d: -f2)
                        DIR=$(echo "$DEST_DIR" | cut -d: -f1)
                        sudo rsync -a --delete --chown=$USER:$USER "$BUILD_RESULTS_DIR/" "$DIR/"
                    done
                    if [ $? -eq 0 ]; then
                        echo "Build results successfully copied to all destinations."
                    else
                        echo "Failed to copy build results to all destinations."
                    fi
                done
                
                echo "All build results have been copied."
            else
                echo "Specified files have changed. Build results will not be copied."
                send_discord_notification_embed \
                    "⚠️ Monitored Files Changed" \
                    "Monitored files were modified in the upstream changes. Build results were not copied." \
                    $YELLOW
            fi
        else
            echo "Build failed!"
            send_discord_notification_embed \
                "❌ Build Failed" \
                "The build for branch \`$LOCAL_BRANCH\` failed after merging upstream \`$UPSTREAM_BRANCH\`." \
                $RED
            exit 1
        fi
    else
        echo "Merge failed. Please resolve conflicts manually."
        send_discord_notification_embed \
            "❌ Merge Conflict" \
            "Merge failed for branch \`$LOCAL_BRANCH\` with upstream \`$UPSTREAM_BRANCH\`. Manual intervention required." \
            $RED
        exit 1
    fi
else
    echo "No new commits found. Repository is up-to-date."
fi

# Log the output
echo "$(date) - $0 - $(cat /dev/stdout)" >> "$LOG_FILE"
