# FKZ Server tools

A collection of tools to help with running the FKZ CS2KZ servers.

## gameinfo.gi edit script

Basic shell script to check if metamod entry exist and if not add into gameinfo.gi automatically.

Default folder is set for using with a server using LinuxGSM.

### Usage

1. Download and upload gameinfo.sh to your Server.
2. Run `sudo apt-get install dos2unix`, incase you don't already have it.
3. Run `chmod +x gameinfo.sh` to make the file executable if already isn't.
4. Run the script with `./gameinfo.sh`.
5. Free win?

### Automate Runs

1. Download and upload gameinfo.sh to your Servers.
2. Run `sudo apt-get install dos2unix`, incase you don't already have it.
3. Run `chmod +x gameinfo.sh` to make the file executable if already isn't.
4. Run `crontab -e` to edit the cronjob.
5. Add `*/35 * * * * su - user -c '/home/user/gameinfo.sh' > /dev/null 2>&1` to the cronjob, replace `user` with your server's username.
6. Close and save the cronjob.

### Issues

If you get an error with \r not being recognized, run `dos2unix /path/to/gameinfo.sh`.

## Autoupdate CS2KZ

Shell script to check for new commits to CS2KZ, then merge those changes to local branch, build, and copy to gameserver folders.

Default folder is set for using with a server using LinuxGSM.

### Usage

tba
