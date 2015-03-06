#!/bin/bash
echo "$(date +%Y-%m-%d_%H:%M:%S) $0" >> ~/WORK/cron.result.txt;
# 打印拷贝的所有文件，不要覆盖已存在的文件
cp -vn /var/cache/apt/archives/* ~/SOFT/apt-get.cache/  | sed '/lock"$/d' >> ~/WORK/cron.result.txt