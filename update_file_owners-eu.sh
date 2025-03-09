#!/bin/bash

# MISC

sudo find /home/webmaster -not -user webmaster -not -group webmaster -print -exec chown webmaster:webmaster {} \;
sudo find /var/www -not -user webmaster -not -group webmaster -not -path '/var/www/files.femboy.kz/cs2/demos*' -not -path '/var/www/files.femboy.kz/cs2/maps*' -not -path '/var/www/files.femboy.kz/cs2/workshop*' -not -path '/var/www/files.femboy.kz/cscl/replays*' -not -path '/var/www/files.femboy.kz/fastdl/replays*' -print -exec chown webmaster:webmaster {} \;

sudo find /home/web-misc -not -user web-misc -not -group web-misc -print -exec chown web-misc:web-misc {} \;

sudo find /home/steam -not -user steam -not -group steam -print -exec chown steam:steam {} \;

# DISCORD

sudo find /home/discord-fkz-1 -not -user discord-fkz-1 -not -group discord-fkz-1 -print -exec chown discord-fkz-1:discord-fkz-1 {} \;

sudo find /home/discord-fkz-2 -not -user discord-fkz-2 -not -group discord-fkz-2 -print -exec chown discord-fkz-2:discord-fkz-2 {} \;

sudo find /home/discord-fkz-3 -not -user discord-fkz-3 -not -group discord-fkz-3 -print -exec chown discord-fkz-3:discord-fkz-3 {} \;

# MC

sudo find /home/mc-dot-1 -not -user mc-dot-1 -not -group mc-dot-1 -print -exec chown mc-dot-1:mc-dot-1 {} \;

sudo find /home/mc-iwaki-1 -not -user mc-iwaki-1 -not -group mc-iwaki-1 -print -exec chown mc-iwaki-1:mc-iwaki-1 {} \;

# CS2

sudo find /home/cs2-fkz-1 -not -user cs2-fkz-1 -not -group cs2-fkz-1 -print -exec chown cs2-fkz-1:cs2-fkz-1 {} \;
sudo find /var/www/files.femboy.kz/cs2/demos/fkz-1 -not -user cs2-fkz-1 -not -group cs2-fkz-1 -print -exec chown cs2-fkz-1:cs2-fkz-1 {} \;
sudo find /var/www/files.femboy.kz/cs2/maps -not -user cs2-fkz-1 -not -group cs2-fkz-1 -print -exec chown cs2-fkz-1:cs2-fkz-1 {} \;
sudo find /var/www/files.femboy.kz/cs2/workshop -not -user cs2-fkz-1 -not -group cs2-fkz-1 -print -exec chown cs2-fkz-1:cs2-fkz-1 {} \;

sudo find /home/cs2-fkz-2 -not -user cs2-fkz-2 -not -group cs2-fkz-2 -print -exec chown cs2-fkz-2:cs2-fkz-2 {} \;
sudo find /var/www/files.femboy.kz/cs2/demos/fkz-2 -not -user cs2-fkz-2 -not -group cs2-fkz-2 -print -exec chown cs2-fkz-2:cs2-fkz-2 {} \;

sudo find /home/cs2-fkz-3 -not -user cs2-fkz-3 -not -group cs2-fkz-3 -print -exec chown cs2-fkz-3:cs2-fkz-3 {} \;
sudo find /var/www/files.femboy.kz/cs2/demos/fkz-3 -not -user cs2-fkz-3 -not -group cs2-fkz-3 -print -exec chown cs2-fkz-3:cs2-fkz-3 {} \;

sudo find /home/cs2-fkz-4 -not -user cs2-fkz-4 -not -group cs2-fkz-4 -print -exec chown cs2-fkz-4:cs2-fkz-4 {} \;
sudo find /var/www/files.femboy.kz/cs2/demos/fkz-4 -not -user cs2-fkz-4 -not -group cs2-fkz-4 -print -exec chown cs2-fkz-4:cs2-fkz-4 {} \;

sudo find /home/cs2-fkz-5 -not -user cs2-fkz-5 -not -group cs2-fkz-5 -print -exec chown cs2-fkz-5:cs2-fkz-5 {} \;
sudo find /var/www/files.femboy.kz/cs2/demos/fkz-5 -not -user cs2-fkz-5 -not -group cs2-fkz-5 -print -exec chown cs2-fkz-5:cs2-fkz-5 {} \;

sudo find /home/cs2-fkz-api -not -user cs2-fkz-api -not -group cs2-fkz-api -print -exec chown cs2-fkz-api:cs2-fkz-api {} \;

# CSGO

sudo find /home/csgo-fkz-1 -not -user csgo-fkz-1 -not -group csgo-fkz-1 -print -exec chown csgo-fkz-1:csgo-fkz-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/fkz-1 -not -user csgo-fkz-1 -not -group csgo-fkz-1 -print -exec chown csgo-fkz-1:csgo-fkz-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/fkz-1 -not -user csgo-fkz-1 -not -group csgo-fkz-1 -print -exec chown csgo-fkz-1:csgo-fkz-1 {} \;

sudo find /home/csgo-fkz-2 -not -user csgo-fkz-2 -not -group csgo-fkz-2 -print -exec chown csgo-fkz-2:csgo-fkz-2 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/fkz-2 -not -user csgo-fkz-2 -not -group csgo-fkz-2 -print -exec chown csgo-fkz-2:csgo-fkz-2 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/fkz-2 -not -user csgo-fkz-2 -not -group csgo-fkz-2 -print -exec chown csgo-fkz-2:csgo-fkz-2 {} \;

sudo find /home/csgo-fkz-3 -not -user csgo-fkz-3 -not -group csgo-fkz-3 -print -exec chown csgo-fkz-3:csgo-fkz-3 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/fkz-3 -not -user csgo-fkz-3 -not -group csgo-fkz-3 -print -exec chown csgo-fkz-3:csgo-fkz-3 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/fkz-3 -not -user csgo-fkz-3 -not -group csgo-fkz-3 -print -exec chown csgo-fkz-3:csgo-fkz-3 {} \;

sudo find /home/csgo-luf-1 -not -user csgo-luf-1 -not -group csgo-luf-1 -print -exec chown csgo-luf-1:csgo-luf-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/luf-1 -not -user csgo-luf-1 -not -group csgo-luf-1 -print -exec chown csgo-luf-1:csgo-luf-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/luf-1 -not -user csgo-luf-1 -not -group csgo-luf-1 -print -exec chown csgo-luf-1:csgo-luf-1 {} \;

sudo find /home/csgo-nikita-1 -not -user csgo-nikita-1 -not -group csgo-nikita-1 -print -exec chown csgo-nikita-1:csgo-nikita-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/nikita-1 -not -user csgo-nikita-1 -not -group csgo-nikita-1 -print -exec chown csgo-nikita-1:csgo-nikita-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/nikita-1 -not -user csgo-nikita-1 -not -group csgo-nikita-1 -print -exec chown csgo-nikita-1:csgo-nikita-1 {} \;

sudo find /home/csgo-salad-1 -not -user csgo-salad-1 -not -group csgo-salad-1 -print -exec chown csgo-salad-1:csgo-salad-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/fruity-1 -not -user csgo-salad-1 -not -group csgo-salad-1 -print -exec chown csgo-salad-1:csgo-salad-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/fruity-1 -not -user csgo-salad-1 -not -group csgo-salad-1 -print -exec chown csgo-salad-1:csgo-salad-1 {} \;

sudo find /home/csgo-salad-2 -not -user csgo-salad-2 -not -group csgo-salad-2 -print -exec chown csgo-salad-2:csgo-salad-2 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/fruity-2 -not -user csgo-salad-2 -not -group csgo-salad-2 -print -exec chown csgo-salad-2:csgo-salad-2 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/fruity-2 -not -user csgo-salad-2 -not -group csgo-salad-2 -print -exec chown csgo-salad-2:csgo-salad-2 {} \;

sudo find /home/csgo-somali-1 -not -user csgo-somali-1 -not -group csgo-somali-1 -print -exec chown csgo-somali-1:csgo-somali-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/somali-1 -not -user csgo-somali-1 -not -group csgo-somali-1 -print -exec chown csgo-somali-1:csgo-somali-1 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/somali-1 -not -user csgo-somali-1 -not -group csgo-somali-1 -print -exec chown csgo-somali-1:csgo-somali-1 {} \;

sudo find /home/csgo-somali-2 -not -user csgo-somali-2 -not -group csgo-somali-2 -print -exec chown csgo-somali-2:csgo-somali-2 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/gokz/somali-2 -not -user csgo-somali-2 -not -group csgo-somali-2 -print -exec chown csgo-somali-2:csgo-somali-2 {} \;
sudo find /var/www/files.femboy.kz/fastdl/replays/kztimer/somali-2 -not -user csgo-somali-2 -not -group csgo-somali-2 -print -exec chown csgo-somali-2:csgo-somali-2 {} \;

# CSCL

sudo find /home/cscl-fkz-1 -not -user cscl-fkz-1 -not -group cscl-fkz-1 -print -exec chown cscl-fkz-1:cscl-fkz-1 {} \;
sudo find /var/www/files.femboy.kz/cscl/replays/gokz/fkz-1 -not -user cscl-fkz-1 -not -group cscl-fkz-1 -print -exec chown cscl-fkz-1:cscl-fkz-1  {} \;
sudo find /var/www/files.femboy.kz/cscl/replays/kztimer/fkz-1 -not -user cscl-fkz-1 -not -group cscl-fkz-1 -print -exec chown cscl-fkz-1:cscl-fkz-1  {} \;

sudo find /home/cscl-fkz-2 -not -user cscl-fkz-2 -not -group cscl-fkz-2 -print -exec chown cscl-fkz-2:cscl-fkz-2 {} \;
sudo find /var/www/files.femboy.kz/cscl/replays/gokz/fkz-2 -not -user cscl-fkz-2 -not -group cscl-fkz-2 -print -exec chown cscl-fkz-2:cscl-fkz-2  {} \;
sudo find /var/www/files.femboy.kz/cscl/replays/kztimer/fkz-2 -not -user cscl-fkz-2 -not -group cscl-fkz-2 -print -exec chown cscl-fkz-2:cscl-fkz-2  {} \;

sudo find /home/cscl-fkz-3 -not -user cscl-fkz-3 -not -group cscl-fkz-3 -print -exec chown cscl-fkz-3:cscl-fkz-3 {} \;
sudo find /var/www/files.femboy.kz/cscl/replays/gokz/fkz-3 -not -user cscl-fkz-3 -not -group cscl-fkz-3 -print -exec chown cscl-fkz-3:cscl-fkz-3  {} \;
sudo find /var/www/files.femboy.kz/cscl/replays/kztimer/fkz-3 -not -user cscl-fkz-3 -not -group cscl-fkz-3 -print -exec chown cscl-fkz-3:cscl-fkz-3  {} \;

echo "Ownership check and update complete."
