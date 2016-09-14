#!/bin/bash
gsettings set org.gnome.desktop.background picture-uri file:///`pwd`/_bg.jpg

# sudo cp _bg.jpg /usr/share/backgrounds/desktop.jpg
# echo '修改壁纸需要重启，确定要现在重启吗(y/N)?'
# read yesorno
# if [ "$yesorno" == 'y' ]; then
#         sudo reboot;
# fi;