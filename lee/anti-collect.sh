#!/bin/bash
#########################################################################
#
# File:         kickleech.sh
# Description:  ban leech by IP address with iptables on Apache log
# Language:     GNU Bourne-Again SHell
# Version:	1.2
# Date:		2010-6-9
# Blog:		blog.c1gstudio.com
# Author:	C1G
#########################################################################
#add contab
#crontab -e
#*/3 * * * * cd /opt/shell && /bin/sh ./kickleech.sh > /dev/null 2>&1


export LANG=uc_EN

V_DEBUGLOG=./kickleech.log
V_LOG=/opt/nginx/logs/blog.c1gstudio.com.log
V_TMPFILE=/opt/nginx/logs/kickleechtmp.log
V_IPTMPFILE=./kickleechip.log
V_TIMELIMIT=3
V_THRESHOLD=60
V_MAXIP=3
V_SAFEIP="192.168.0.15 222.147.111.3 222.236.154.162"
V_CODE='favicon.ico'
V_IPTABLES=1
V_HTTPPORT=80
V_IPTABLESFLUSHTIME="3 12 21 33 42 51"
V_REQUESTNUM=2
V_FINDNUM=''


echo =====`date`======== >> ${V_DEBUGLOG}

if [ $V_IPTABLES -eq 1 ]; then
	#add iptables
	if [ `/sbin/iptables -L KICKLEECH 2>&1 |grep -c 'No chain'` = 1 ]; then
		echo "New iptables chain " >> ${V_DEBUGLOG};
		/sbin/iptables -N KICKLEECH
		/sbin/iptables -I INPUT 1 -p tcp -m tcp --dport ${V_HTTPPORT} -j KICKLEECH
	fi
	#flush iptables
	V_CURRMINUTE=`date +%-M`
	for i in ${V_IPTABLESFLUSHTIME} ;do 
		if [ "$V_CURRMINUTE" = "$i" ]; then
			echo "Flush iptables " >> ${V_DEBUGLOG}
			/sbin/iptables -F KICKLEECH
			break;
		fi
	done	
fi


[ -f ${V_LOG} ] || { echo "Can not read ${V_LOG}" >> ${V_DEBUGLOG}; exit 1;}

#ouput log
echo "" > ${V_TMPFILE}

for ((i=${V_TIMELIMIT}-1;i>=0;i--))
do
	grep `date +'%d/%b/%Y:%H:%M' --date="-$i minute"` ${V_LOG}|egrep -vi 'spider|bot|Google|crawl|Yahoo' >> ${V_TMPFILE}
done

#get ip array
echo "" >${V_IPTMPFILE}
cat ${V_TMPFILE} |awk -vnvar="$V_THRESHOLD" '{a[$1]++}END{for (j in a) if(a[j]>nvar) print a[j],j}'|sort -rnk1 > ${V_IPTMPFILE}
i=0
let V_MAXIP=${V_MAXIP}-1
while read line
do
	echo $line >> ${V_DEBUGLOG}
	ALL_IP[$i]=`echo ${line}|cut -d" " -f2`
	if [ "$i" -eq "$V_MAXIP" ]; then 
		break;
	fi
	i=$(($i+1))
done < ${V_IPTMPFILE}


#check ip num
V_LENGTH=${#ALL_IP[*]}
if [ ${V_LENGTH} = 0 ]; then
	echo "None IP " >> ${V_DEBUGLOG};
	exit 1;
fi


for i in ${ALL_IP[*]}
do
	#check ip
	for j in ${V_SAFEIP} ;do 
		if [ "$j" = "$i" ]; then
		echo "Safe ip ${i}" >> ${V_DEBUGLOG}
		continue 2;
		fi
	done
	V_FINDNUM=`cat ${V_TMPFILE} |grep ${i} |grep -c ${V_CODE} `
	if [ "$V_FINDNUM" -ge "${V_REQUESTNUM}" ]; then
		echo "That's ok ${i}" >> ${V_DEBUGLOG}
		
	else
		echo "Bad guy ${i}" >> ${V_DEBUGLOG}
		if [ $V_IPTABLES -eq 1 ] ; then
			/sbin/iptables -I KICKLEECH 1 -s ${i} -j DROP
			echo "iptables ${i}" >> ${V_DEBUGLOG}
		fi
	fi

done