#!/bin/bash
port=$(nmap -sT 192.168.1.1 | grep tcp | grep http | awk '{print $2}')
if [ "$port"=="open" ];then
	echo "$(date) httpd is ok!" >> /tmp/autostart-acc.log
else
	/etc/rc.d/init.d/httpd start & /dev/null
	echo "$(date) restart httpd !!" >> /tmp/autostart-err.log
fi
