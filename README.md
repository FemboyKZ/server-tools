# FKZ Server tools

A collection of tools to help with running the FKZ CS2KZ servers.

## gameinfo.gi edit script

Basic shell script to check if metamod entry exist and if not add into gameinfo.gi automatically.

Default folder is set for using with a server using LinuxGSM.

### Automatic Checks usage

1. Download and upload `gameinfo.sh` to your Server.
2. Run `sudo apt-get install dos2unix`, incase you don't already have it.
3. Run `chmod +x gameinfo.sh` to make the file executable if already isn't.
4. You can run the script with `./gameinfo.sh`.

You probably want it to run on a cronjob. Run `crontab -e` to edit the cronjob. Then add the following line:

```txt
* * * * * su - user -c '/home/user/gameinfo.sh' > /dev/null 2>&1    # run every minute, replace `user` with your server's username
```

Close and save the cronjob.

### Issues

If you get an error with \r not being recognized, run `dos2unix /path/to/gameinfo.sh`.

## Autoupdate CS2KZ

Shell script to check for new commits to [CS2KZ](https://github.com/KZGlobalTeam/cs2kz-metamod), then merge those changes to local branch, build, and copy to gameserver folders.

Default folder is set for using with a server using LinuxGSM.

### Automatic Updates

1. Download and upload `cs2kz-autoupdate.sh` to your Server.
2. Run `chmod +x cs2kz-autoupdate.sh` to make the file executable if already isn't.
3. You can run the script with `./cs2kz-autoupdate.sh`.

You probably want it to run on a cronjob. Run `crontab -e` to edit the cronjob, then add the following line:

```txt
* * * * * su - user -c '/home/user/cs2kz-autoupdate.sh' > /dev/null 2>&1    # run every minute, replace `user` with your server's username
```
