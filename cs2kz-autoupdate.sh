#!/bin/bash

CONFIG_FILE=config.json
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE=config.example.json
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

USERNAME=$(jq -r '.cs2kz_autoupdate.username' "$CONFIG_FILE")

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

cd "$REPO_DIR" || { echo "Repository not found at \`$REPO_DIR\`"; exit 1; }

if ! git remote -v | grep -q "upstream"; then
  echo "Upstream repository not configured"
  exit 1
fi

if ! git fetch upstream; then
  echo "Error fetching from upstream repository"
  git remote add upstream "$UPSTREAM_REPO"
  exit 1
fi

NEW_COMMITS=$(git rev-list HEAD..upstream/$UPSTREAM_BRANCH --count)

if [ "$NEW_COMMITS" -gt 0 ]; then
    echo "Found $NEW_COMMITS new commit(s). Attempting to merge changes..."
    send_discord_notification_embed \
        "⚠️ New Upstream Changes" \
        "Found $NEW_COMMITS new commit(s) in upstream \`$UPSTREAM_BRANCH\`. Attempting to merge changes..." \
        $BLUE

    if ! git checkout "$LOCAL_BRANCH"; then
        echo "Error Checking Out Branch"
        send_discord_notification_embed \
            "❌ Error Checking Out Branch" \
            "Error checking out branch \`$LOCAL_BRANCH\`" \
            $RED
        exit 1
    fi
    
    if ! git merge -m "Automated merge of upstream/$UPSTREAM_BRANCH" --username "$USERNAME" --no-ff --strategy=recursive --strategy-option=ours -S upstream/"$UPSTREAM_BRANCH"; then
        echo "Error merging upstream changes"
        exit 1
    fi
    
    if ! git push origin "$LOCAL_BRANCH"; then
        echo "Error pushing changes"
        send_discord_notification_embed \
            "❌ Error Pushing Changes" \
            "Error pushing changes to upstream \`$UPSTREAM_BRANCH\`" \
            $RED
        exit 1
    fi

    if [ $? -eq 0 ]; then
        echo "Merge and push successful. Checking for specific file changes..."
        
        FILES_CHANGED=false
        for FILE in "${FILES_TO_CHECK[@]}"; do
            if git diff --name-only HEAD..upstream/"$UPSTREAM_BRANCH" | grep -q "$FILE"; then
                FILES_CHANGED=true
                echo "Detected changes to $FILE."
            fi
        done
        
        echo "Starting build process..."
        bash -c "cd build && python3 ../configure.py && ambuild;"
        
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
                        echo "Destination directory \`$DEST_DIR\` does not exist. Skipping..."
                        continue
                    fi
                    
                    echo "Copying build results to \`$DEST_DIR\`..."
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
    exit 0
fi

echo "$(date) - $0 - $(cat /dev/stdout)" >> "$LOG_FILE"
exit 0
