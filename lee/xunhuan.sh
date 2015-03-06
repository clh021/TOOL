#!/bin/bash
for $i in 1 2 3 4 5 6 
	do
		echo $i
	done

#批量解压缩
cd /lamp
ls *.tar.gz > ls.log
for i in $(cat ls.log)
	do
		tar -zxf $i &> /dev/null
	done
rm -rf /lamp/ls.log


