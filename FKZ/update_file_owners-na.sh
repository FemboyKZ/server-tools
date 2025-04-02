#!/bin/bash

# MISC

sudo find /home/webmaster -not -user webmaster -not -group webmaster -print -exec chown webmaster:webmaster {} \;
sudo find /var/www -not -user webmaster -not -group webmaster -not -path '/var/www/files-na.femboy.kz/cs2/demos*' -not -path '/var/www/files-na.femboy.kz/cs2/maps*' -not -path '/var/www/files-na.femboy.kz/cs2/workshop*' -not -path '/var/www/files-na.femboy.kz/cscl/replays*' -not -path '/var/www/files-na.femboy.kz/fastdl/replays*' -print -exec chown webmaster:webmaster {} \;

sudo find /home/web-listen -not -user web-listen -not -group web-listen -print -exec chown web-listen:web-listen {} \;

sudo find /home/debian -not -user debian -not -group debian -print -exec chown debian:debian {} \;

# DISCORD

# MC

sudo find /home/mineraft -not -user mineraft -not -group mineraft -print -exec chown mineraft:mineraft {} \;

# CS2

sudo find /home/cs2-fkz-1 -not -user cs2-fkz-1 -not -group cs2-fkz-1 -print -exec chown cs2-fkz-1:cs2-fkz-1 {} \;
sudo find /var/www/files-na.femboy.kz/cs2/demos/fkz-1 -not -user cs2-fkz-1 -not -group cs2-fkz-1 -print -exec chown cs2-fkz-1:cs2-fkz-1 {} \;
sudo find /var/www/files-na.femboy.kz/cs2/maps -not -user cs2-fkz-1 -not -group cs2-fkz-1 -print -exec chown cs2-fkz-1:cs2-fkz-1 {} \;
sudo find /var/www/files-na.femboy.kz/cs2/workshop -not -user cs2-fkz-1 -not -group cs2-fkz-1 -print -exec chown cs2-fkz-1:cs2-fkz-1 {} \;

sudo find /home/cs2-fkz-2 -not -user cs2-fkz-2 -not -group cs2-fkz-2 -print -exec chown cs2-fkz-2:cs2-fkz-2 {} \;
sudo find /var/www/files-na.femboy.kz/cs2/demos/fkz-2 -not -user cs2-fkz-2 -not -group cs2-fkz-2 -print -exec chown cs2-fkz-2:cs2-fkz-2 {} \;

sudo find /home/cs2-fkz-3 -not -user cs2-fkz-3 -not -group cs2-fkz-3 -print -exec chown cs2-fkz-3:cs2-fkz-3 {} \;
sudo find /var/www/files-na.femboy.kz/cs2/demos/fkz-3 -not -user cs2-fkz-3 -not -group cs2-fkz-3 -print -exec chown cs2-fkz-3:cs2-fkz-3 {} \;

# CSGO

sudo find /home/csgo-fkz-1 -not -user csgo-fkz-1 -not -group csgo-fkz-1 -print -exec chown csgo-fkz-1:csgo-fkz-1 {} \;
sudo find /var/www/files-na.femboy.kz/fastdl/replays/gokz/fkz-1 -not -user csgo-fkz-1 -not -group csgo-fkz-1 -print -exec chown csgo-fkz-1:csgo-fkz-1 {} \;
sudo find /var/www/files-na.femboy.kz/fastdl/replays/kztimer/fkz-1 -not -user csgo-fkz-1 -not -group csgo-fkz-1 -print -exec chown csgo-fkz-1:csgo-fkz-1 {} \;

sudo find /home/csgo-fkz-2 -not -user csgo-fkz-2 -not -group csgo-fkz-2 -print -exec chown csgo-fkz-2:csgo-fkz-2 {} \;
sudo find /var/www/files-na.femboy.kz/fastdl/replays/gokz/fkz-2 -not -user csgo-fkz-2 -not -group csgo-fkz-2 -print -exec chown csgo-fkz-2:csgo-fkz-2 {} \;
sudo find /var/www/files-na.femboy.kz/fastdl/replays/kztimer/fkz-2 -not -user csgo-fkz-2 -not -group csgo-fkz-2 -print -exec chown csgo-fkz-2:csgo-fkz-2 {} \;

# CSCL

sudo find /home/cscl-fkz-1 -not -user cscl-fkz-1 -not -group cscl-fkz-1 -print -exec chown cscl-fkz-1:cscl-fkz-1 {} \;
sudo find /var/www/files-na.femboy.kz/cscl/replays/gokz/fkz-1 -not -user cscl-fkz-1 -not -group cscl-fkz-1 -print -exec chown cscl-fkz-1:cscl-fkz-1 {} \;
sudo find /var/www/files-na.femboy.kz/cscl/replays/kztimer/fkz-1 -not -user cscl-fkz-1 -not -group cscl-fkz-1 -print -exec chown cscl-fkz-1:cscl-fkz-1 {} \;

sudo find /home/cscl-fkz-2 -not -user cscl-fkz-2 -not -group cscl-fkz-2 -print -exec chown cscl-fkz-2:cscl-fkz-2 {} \;
sudo find /var/www/files-na.femboy.kz/cscl/replays/gokz/fkz-2 -not -user cscl-fkz-2 -not -group cscl-fkz-2 -print -exec chown cscl-fkz-2:cscl-fkz-2 {} \;
sudo find /var/www/files-na.femboy.kz/cscl/replays/kztimer/fkz-2 -not -user cscl-fkz-2 -not -group cscl-fkz-2 -print -exec chown cscl-fkz-2:cscl-fkz-2 {} \;

echo "Ownership check and update complete."
