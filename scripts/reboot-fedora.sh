#!/bin/bash

# quiet workers
sudo kill -USR1 $(sudo initctl status opal-workers | grep /running | awk '{print $NF}')

# wait 2 minutes
sleep 120

# shutdown workers
sudo kill -TERM $(sudo initctl status opal-workers | grep /running | awk '{print $NF}')

# restart tomcat
sudo service tomcat7 restart

# restart workers
sudo initctl stop 'opal-workers'
sudo initctl start 'opal-workers'
echo $(date) >> /opt/reboot-log.txt
