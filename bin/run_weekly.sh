#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl weekly_medals.pl >> /tmp/weekly_medals.log 2>> /tmp/weekly_medals.log
perl trelvestian/reset_essentia_veins.pl
perl clean_up_battle_log.pl
