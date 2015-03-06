#!/bin/bash
#统计根分区使用率
rate=$(df -h | grep "/dev/sda3" | awk '{print $5}' | cut -d "%" f1)
#把根分区使用率作为变量值赋予变量rate
if [ $rate -ge 80 ];then
	echo "Warning! /dev/sda3 is full!!"
fi
