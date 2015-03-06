#!/bin/bash
# 定义数组，全部都是全路径
# 循环进入这些全路径
# 在该路径下执行git更新
echo "$(date +%Y-%m-%d_%H:%M:%S) $0" >> ~/WORK/cron.result.txt;
function updateGit()
{
    cd $1
    echo "$1" >> ~/WORK/cron.result.txt;
    git pull --rebase &>> ~/WORK/cron.result.txt
}

function getChildfolders()
{
    find $1 -maxdepth 1 -mindepth 1
}

function updateChildfolders()
{
    for shname in `getChildfolders $1`
    do
        updateGit $shname
    done
}

updateChildfolders ~/WORK