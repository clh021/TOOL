#!/bin/bash
# apt update
# apt upgrade

# Simple setup for configuring Ubuntu quickly.
sudo chmod +x *.sh 
sudo ./installApps.sh
sudo ./installDevelopment.sh
sudo ./setHost.sh
sudo ./setBackground.sh
sudo ./removeApps.sh
#sudo apt-get autoremove

#提示一些别的操作
echo "强制谷歌访问使用https
谷歌浏览器，打开chrome://net-internals/#hsts
在'Add domain'中依次输入以下网址并勾下面俩勾,Add
google.com
google.com.hk
googleusercontent.com
googleapis.com

搜狗输入法候选字符9个字符"