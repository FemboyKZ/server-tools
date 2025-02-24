# FKZ Server tools

A collection of tools to help with running the FKZ CS2KZ servers.

These tools are WIP and wiki for them is missing/incomplete!!!

## Autoupdate CS2KZ

Shell script to check for new commits to [CS2KZ](https://github.com/KZGlobalTeam/cs2kz-metamod), then merge those changes to local branch, build, and copy to gameserver folders.

Default folder is set for using with a server using LinuxGSM.

### Pre-requisites

Install the following packages:

```bash
sudo apt-get update && sudo apt-get install -y git dos2unix python3 python3-pip
sudo apt-get install lftp sshpass jq rsync tmux

pip3 install a2s
```

Create and fill out the configuration file.

```bash
cp config.example.json config.json && nano config.json
```

Example configuration file:

```json
{
  "cs2kz_autoupdate": {
    "webhook_url": "https://discord.com/api/webhooks/id/token",             # Discord webhook URL
    "repo_dir": "/home/user/server-tools/cs2kz-metamod/",                   # Directory of CS2KZ repo
    "upstream_repo": "git@github.com:KZGlobalTeam/cs2kz-metamod",           # Upstream CS2KZ repo
    "upstream_branch": "dev",                                               # Upstream CS2KZ branch
    "local_branch": "dev",                                                  # Local CS2KZ branch
    "files_to_check": ["cs2kz-server-config.txt", "cs2kz.cfg"],             # List of files to check for changes (relative to repo_dir)
    "enable_logging": true,                                                 # Toggle logging
    "log_file": "/home/user/server-tools/cs2kz-autoupdate.log",             # Log file
    "build_log_file": "/home/user/server-tools/cs2kz-autoupdate-build.log", # Build log file
    "update_check_interval": 300,                                           # Update check interval in seconds
    "enable_builds": true,                                                  # Toggle builds
    "auto_update": false,                                                   # Toggle auto updates
    "servers_to_update": [                                                  # List of servers to update, 4 types of servers are supported
      {
        # Local server
        "folder": "/home/localuser/serverfiles/game/csgo/addons/cs2kz/",
        "user": "localuser",
        "address": "192.168.1.1:27015",
        "type": "local"
      },
      {
        # Remote server with SSH key
        "folder": "/home/remoteuser1/serverfiles/game/csgo/addons/cs2kz/",
        "user": "remoteuser1",
        "address": "192.168.1.2:27015",
        "type": "remote_key",
        "ssh_key": "/path/to/private_key",
        "ssh_port": "22",
        "ssh_address": "192.168.1.2"
      },
      {
        # Remote server with SSH using password
        "folder": "/home/remoteuser2/serverfiles/game/csgo/addons/cs2kz/",
        "user": "remoteuser2",
        "address": "192.168.1.2:27015",
        "type": "remote_pass",
        "ssh_port": "22",
        "ssh_address": "192.168.1.2",
        "ssh_pass": "your_ssh_password"
      },
      {
        # Remote server with FTP using password
        "folder": "/addons/cs2kz/",
        "user": "remoteuser3",
        "address": "192.168.1.2:27015",
        "type": "remote_ftp",
        "ssh_port": "21",
        "ssh_address": "192.168.1.2",
        "ssh_pass": "your_ssh_password"
      }
    ],
  },
  ...
}
```

Run the following commands to set up the script:

```bash
chmod +x cs2kz-autoupdate.sh                # Make the script executable
dos2unix cs2kz-autoupdate.sh                # Make sure the file is in Unix format
tmux new -d 'bash cs2kz-autoupdate.sh'      # Run the script in the background
```

## LGSM Autoupdater

Shell script to check for CS2 updates and automatically update local and remote servers that use LGSM.

### Setup

Install the following packages:

```bash
sudo apt-get update && sudo apt-get install -y git dos2unix python3 python3-pip
sudo apt-get install lftp sshpass jq rsync tmux

pip3 install a2s
```

Create and fill out the configuration file.

```bash
cp config.example.json config.json && nano config.json
```

Example configuration file:

```json
{
  ...
  "lgsm_update": {
    "webhook_url": "https://discord.com/api/webhooks/id/token",             # Discord webhook URL
    "enable_logging": true,                                                 # Toggle logging
    "log_file": "/home/user/server-tools/cs2-lgsm-autoupdate.log",          # Log file
    "update_check_interval": 300,                                           # Update check interval in seconds
    "update_check_user": "localuser",                                       # User to check for updates
    "auto_update": true,                                                    # Toggle auto updates (false for log only)
    "game": "cs2",                                                          # Game to update (only tested with cs2)
    "servers_to_update": [                                                  # List of servers to update
      {
        # Local server
        "user": "localuser",
        "address": "192.168.1.1:27015",
        "type": "local"
      },
      {
        # Remote server with SSH key
        "user": "remoteuser1",
        "address": "192.168.1.2:27015",
        "type": "remote_key",
        "ssh_key": "/path/to/private_key",
        "ssh_port": "22",
        "ssh_address": "192.168.1.2"
      },
      {
        # Remote server with SSH using password
        "user": "remoteuser2",
        "address": "192.168.1.2:27015",
        "type": "remote_pass",
        "ssh_port": "22",
        "ssh_address": "192.168.1.2",
        "ssh_pass": "your_ssh_password"
      }
    ]
  }
}
```

Run the following commands to set up the script:

```bash
chmod +x lgsm-update.sh                # Make the script executable
dos2unix lgsm-update.sh                # Make sure the file is in Unix format
tmux new -d 'bash lgsm-update.sh'      # Run the script in the background
```

## gameinfo.gi edit script

Basic shell script to check if metamod entry exist and if not add into gameinfo.gi automatically.

Default folder is set for using with a server using LinuxGSM.

### Automatic Checks usage

1. Download and upload `gameinfo.sh` to your Server.
2. Run `sudo apt-get install dos2unix`, incase you don't already have it.
3. Run `chmod +x gameinfo.sh` to make the file executable if already isn't.
4. Run `dos2unix gameinfo.sh` to make sure the file is in Unix format.
5. You can run the script with `./gameinfo.sh`.

You probably want it to run on a cronjob. Run `crontab -e` to edit the cronjob. Then add the following line:

```txt
* * * * * su - user -c 'bash /home/user/gameinfo.sh' > /dev/null 2>&1    # run every minute, replace `user` with your server's username
```

Close and save the cronjob.

## Issues

If you get an error with \r not being recognized, run `dos2unix /path/to/script.sh`
