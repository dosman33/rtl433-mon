# rtl433-mon
![HTML formatted rtl_433 log](/rtl433-mon_html.jpg)

# What is this?

If you have an rtl_433 rig running somewhere with interesting signals showing up every day, this is a fun way to keep up with the activity in your vicinity. This is a set of scripts for doing simple logging, HTML-ifying, and some very simple state monitoring of rtl_433 data. It's not intended to be a heavy hitting Graphana/full stack deal, just some simple Unix shell scripts to easily keep an eye on what data your rtl_433 rig is pulling in every day, along with automatic daily log rotation.

## column-reduce.sh
At present time, rtl_433 csv logging has over 170 columns. This script takes your csv output log and cuts out the empty columns while maintaing padded fields for rows with empty fields in the same log. This way the csv header is still correct for every column but you loose all unused columns. Redirect output to save it to a new log.

## rtl433-html.sh  
This takes your rtl_433 csv log and generates an HTML-tabled version. It uses column-reduce.sh to make the log easier to view in a browser.

## rtl433-restart.sh 
Call this from cron after midnight to cut a new rtl_433 csv log daily. This is useful to combine with rtl433-html.sh to get daily summaries.

## rtl433-updatedb.sh
This is not working yet, still being developed. It creates a state database of signals found each day that can be referenced in the future to provide more context to signals. It ties to the ID field which seems to be the most consistant unique identifier for signals I've seen so far. So, this CSV DB will contain the very first date/time a device was seen, number of times it's been seen ever, and a manually editable field to name this device. So, if you positively id a TPMS device to a vehicles owner, the DB will reflect this for reference. The intent is for rtl433-html.sh to be able to include this in the HTML-ified output for easy reference.


## Environment
My environment is an RPi3 with a Nooelec RTLSDR, these scripts are rather generic unix fare so they should work on any similar environement. It's assumed you will be running Apache2 or a similar web server for serving the html output files. You'll need to make port 80 or 443 open to your web client somehow. An ssh tunnel works well if you are running on an RPi and don't want to open it up to the world.


## Installation
You will need rtl_433 installed and working from here: https://github.com/merbanan/rtl_433

These scripts:
Download them somewhere. Each script has internal comments on recommended cron settings. You'll need to setup some directories under your webroot. Assuming your're not running these scripts as root (please just don't) you'll also need the permission changes:
```
apt-get update; apt-get install apache2
mkdir -p /var/www/html/rtl433/csv
chgrp pi /var/www/html/rtl433
chmod 775 /var/www/html/rtl433
chgrp pi /var/www/html/rtl433/csv
chmod 775 /var/www/html/rtl433/csv
```
