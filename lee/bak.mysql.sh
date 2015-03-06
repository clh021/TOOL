#!/bin/bash
#备份mysql数据库
#ntpdata asia.pool.ntp.org &> /dev/null
#同步系统时间
date=$(date +%y%m%d)
#把当前时间按照年月日格式赋予变量date
size=$(du -sh /var/lib/mysql)
#统计mysql数据库的大小，并把大小赋予size变量
if [ -d /tmp/dbbak ]
	then
		echo 'Date : $date!' > /tmp/dbbak/dbinfo.txt
		echo "Data size : $size " >> /tmp/dbbak/dbinfo.txt
		cd /tmp/dbbak
		tar -zcf mysql-lib-$date.tar.gz /var/lib/mysql dbinfo.txt &> /dev/null
		rm -rf /tmp/dbbak/dbinfo.txt
	else
		mkdir /tmp/dbbak
		cd /tmp/dbbak
		tar -zcf mysql-lib-$date.tar.gz /var/lib/mysql dbinfo.txt &> /dev/null
		rm -rf /tmp/dbbak/dbinfo.txt
fi

