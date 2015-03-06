#!/bin/bash

# Live Ubuntu Backup V1.2, May 31st,2009
# Copyright (C) 2009 billbear <billbear@gmail.com>

# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not, see <http://www.gnu.org/licenses>.

mypath=$0
today=`date +%d%m%Y`
version="V1.2, May 31st,2009"

new_dir(){
	local newdir="$*"
	i=0
	while [ -e $newdir ]; do
	i=`expr $i + 1`
	newdir="$*-$i"
	done
	echo $newdir
}

echored(){
	echo -ne "\033[31m$*\033[0m"
	echo
}

packagecheck_b(){
	dpkg -l | grep ^ii | sed 's/[ ][ ]*/ /g' | cut -d " " -f 2 | grep ^lupin-casper$ > /dev/null || { echored "Warning: lupin-casper is currently not installed. You can install it by typing:\nsudo apt-get install lupin-casper\nYou may need a working internet connection to do that.\nYou can also continue without installing it, but your backup may not be self-bootable. However, you can still restore your backup from something like a livecd environment.\nHit enter to continue and ctrl-c to quit"; read yn; }

	dpkg -l | grep ^ii | sed 's/[ ][ ]*/ /g' | cut -d " " -f 2 | grep ^squashfs-tools$ > /dev/null || { echored "squashfs-tools is required to run this program. You can install it by typing:\nsudo apt-get install squashfs-tools\nYou may need a working internet connection to do that."; exit 1; }
}

packagecheck_r(){
	dpkg -l | grep ^ii | sed 's/[ ][ ]*/ /g' | cut -d " " -f 2 | grep ^parted$ > /dev/null || { echored "parted is required to run this program. You can install it by typing:\nsudo apt-get install parted\nYou may need a working internet connection to do that."; exit 1; }
}

rebuildtree(){ # Remounting the linux directories effectively excludes removable media, manually mounted devices, windows partitions, virtual files under /proc, /sys, /dev, the /host contents of a wubi install, etc. If your partition scheme is more complicated than listed below, you must add lines to rebuildtree() and destroytree(), otherwise the backup will be partial.
	mkdir /$1
	mount --bind / /$1
	mount --bind /boot /$1/boot
	mount --bind /home /$1/home
	mount --bind /tmp /$1/tmp
	mount --bind /usr /$1/usr
	mount --bind /var /$1/var
	mount --bind /srv /$1/srv
	mount --bind /opt /$1/opt
	mount --bind /usr/local /$1/usr/local
}

destroytree(){
	umount /$1/usr/local
	umount /$1/opt
	umount /$1/srv
	umount /$1/var
	umount /$1/usr
	umount /$1/tmp
	umount /$1/home
	umount /$1/boot
	umount /$1
	rmdir /$1
}

target_cmd(){
	mount --bind /proc $1/proc
	mount --bind /dev $1/dev
	mount --bind /sys $1/sys
	chroot $*
	umount $1/sys
	umount $1/dev
	umount $1/proc
}

dequotepath(){ # If drag n drop from nautilus into terminal, the additional single quotes should be removed first.
	local tmpath="$*"
	[ "${tmpath#\'}" != "$tmpath" ] && [ "${tmpath%\'}" != "$tmpath" ] && { tmpath="${tmpath#\'}"; tmpath="${tmpath%\'}"; }
	echo "$tmpath"
}

checkbackupdir(){
	[ "${1#/}" = "$1" ] && { echored "You must specify the absolute path"; exit 1; }
	[ -d "$*" ] || { echored "$* does not exist, or is not a directory"; exit 1; }
	[ `ls -A "$*" | wc -l` = 0 ] || { echored "$* is not empty"; exit 1; }
}

probe_partitions(){
	for i in /dev/[hs]d[a-z][0-9]*; do
	vol_id $i > /dev/null 2>&1 || continue
	parted -s $i print > /dev/null 2>&1 || continue
	part[${#part[*]}]=$i
	oldfstype[${#oldfstype[*]}]=`vol_id --type $i`
	size=`parted -s $i print | grep $i`
	size=${size#*:}
	size=${size#*：}	#全角冒号，台湾 parted 输出用这个 :(
	partinfo[${#partinfo[*]}]="$i `vol_id --type $i` $size"
	done
}

choose_partition(){
	select opt in "${partinfo[@]}"; do
	[ "$opt" = "" ] && continue
	arrno=`expr $REPLY - 1`
	[ $REPLY -gt ${#part[*]} ] && break
	echored "You selected ${part[$arrno]}, it currently contains these files/directories:"
	tmpdir=`new_dir /tmp/mnt`
	[ "${oldfstype[$arrno]}" = "swap" ] || { mkdir $tmpdir; mount ${part[$arrno]} $tmpdir; ls -A $tmpdir; umount $tmpdir; rmdir $tmpdir; }
	echored "confirm?(y/n)"
	read yn
	[ "$yn" != "y" ] && echored "Select again" && continue
	partinfo[$arrno]=""
	break
	done

	eval $1=$arrno
	[ $REPLY -gt ${#part[*]} ] && return
	[ $1 = swappart ] && echored "${part[$arrno]} will be formatted as swap." && return

	if [ "${oldfstype[$arrno]}" = "ext2" -o "${oldfstype[$arrno]}" = "ext3" -o "${oldfstype[$arrno]}" = "ext4" -o "${oldfstype[$arrno]}" = "reiserfs" -o "${oldfstype[$arrno]}" = "jfs" -o "${oldfstype[$arrno]}" = "xfs" ]; then
	echored "Do you want to format this partition?(y/n)"
	read yn
	[ "$yn" != "y" ] && newfstype[$arrno]="keep" && return
	fi
	echored "Format ${part[$arrno]} as:"

	select opt in ext2 ext3 ext4 reiserfs jfs xfs; do
	[ "$opt" = "" ] && continue
	ls /sbin/mkfs.$opt > /dev/null 2>&1 && break
	echored "mkfs.$opt is not installed."
	[ "$opt" = "reiserfs" ] && echored "You can install it by typing\nsudo apt-get install reiserfsprogs"
	[ "$opt" = "jfs" ] && echored "You can install it by typing\nsudo apt-get install jfsutils"
	[ "$opt" = "xfs" ] && echored "You can install it by typing\nsudo apt-get install xfsprogs"
	echored "Please re-select file system type."
	done

	newfstype[$arrno]=$opt
}

setup_target_partitions(){
	rootpart=1000
	swappart=1000
	homepart=1000
	bootpart=1000
	tmppart=1000
	usrpart=1000
	varpart=1000
	srvpart=1000
	optpart=1000
	usrlocalpart=1000

	echored "Which partition do you want to use as / ?"
	choose_partition rootpart

	partinfo[${#partinfo[*]}]="None"
	partinfo[${#partinfo[*]}]="None and finish setting up partitions"

	echored "Which partition do you want to use as swap ?"
	choose_partition swappart
	[ $arrno -gt ${#part[*]} ] && return

	for i in home boot tmp usr var srv opt; do
	echored "Which partition do you want to use as /$i ?"
	eval choose_partition ${i}part
	[ $arrno -gt ${#part[*]} ] && return
	done

	echored "Which partition do you want to use as /usr/local ?"
	choose_partition usrlocalpart
}

umount_target_partitions(){
	for i in usrlocalpart swappart homepart bootpart tmppart usrpart varpart srvpart optpart rootpart; do
	eval thispart=\$$i
	[ "${part[$thispart]}" = "" ] && continue
	[ "${newfstype[$thispart]}" = "keep" ] && continue
		while mount | grep "^${part[$thispart]} " > /dev/null; do
		umount ${part[$thispart]} || { echored "Failed to umount ${part[$thispart]}"; exit 1; }
		done
	[ $i = swappart ] && continue
	swapon -s | grep "^${part[$thispart]} " > /dev/null && echored "swapoff ${part[$thispart]} and try again." && exit 1
	done
}

format_target_partitions(){
	for i in rootpart homepart bootpart tmppart usrpart varpart srvpart optpart usrlocalpart; do
	eval thispart=\$$i
	[ "${part[$thispart]}" = "" ] && continue
	[ "${newfstype[$thispart]}" = "keep" ] && continue
	echored "Formatting ${part[$thispart]}"
	[ "${newfstype[$thispart]}" = "xfs" ] && formatoptions=fq || formatoptions=q
	mkfs.${newfstype[$thispart]} -$formatoptions ${part[$thispart]} > /dev/null || { echored "Failed to format ${part[$thispart]}"; exit 1; }
	disk=`expr substr ${part[$thispart]} 1 8`
	num=${part[$thispart]#$disk}
	sfdisk -c -f $disk $num 83
	done

	[ "${part[$swappart]}" = "" ] && return
	[ "${oldfstype[$swappart]}" = "swap" ] && return
	echored "Formatting ${part[$swappart]}"
	mkfs.ext2 -q ${part[$swappart]} || { echored "Failed to format ${part[$swappart]}"; exit 1; }
	mkswap ${part[$swappart]} || { echored "Failed to format ${part[$swappart]}"; exit 1; }
	disk=`expr substr ${part[$swappart]} 1 8`
	num=${part[$swappart]#$disk}
	sfdisk -c -f $disk $num 82
}

chkuuids(){
	uuids=""
	for i in /dev/[hs]d[a-z][0-9]*; do
	uuids="$uuids\n`vol_id --uuid $i 2> /dev/null`"
	done
	[ "`echo -e $uuids | sort | uniq -d`" = "" ] && return
	echored "duplicate UUIDs detected! The program will now terminate."
	exit 1
}

mount_target_partitions(){
	tgt=`new_dir /tmp/target`
	mkdir $tgt
	mount ${part[$rootpart]} $tgt
	[ "${part[$homepart]}" != "" ] && mkdir -p $tgt/home && mount ${part[$homepart]} $tgt/home
	[ "${part[$bootpart]}" != "" ] && mkdir -p $tgt/boot && mount ${part[$bootpart]} $tgt/boot
	[ "${part[$tmppart]}" != "" ] && mkdir -p $tgt/tmp && mount ${part[$tmppart]} $tgt/tmp
	[ "${part[$usrpart]}" != "" ] && mkdir -p $tgt/usr && mount ${part[$usrpart]} $tgt/usr
	[ "${part[$varpart]}" != "" ] && mkdir -p $tgt/var && mount ${part[$varpart]} $tgt/var
	[ "${part[$srvpart]}" != "" ] && mkdir -p $tgt/srv && mount ${part[$srvpart]} $tgt/srv
	[ "${part[$optpart]}" != "" ] && mkdir -p $tgt/opt && mount ${part[$optpart]} $tgt/opt
	[ "${part[$usrlocalpart]}" != "" ] && mkdir -p $tgt/usr/local && mount ${part[$usrlocalpart]} $tgt/usr/local
}

gettargetmount(){ # Generate a list of mounted partitions and mount points of the restore target.
	for i in `mount | grep " $* "`; do
	[ "${i#/dev/}" != "$i" ] && echo $i
	[ "$i" = "$*"  ] && echo "$i/"
	done

	for i in `mount | grep " $*/"`; do
	[ "${i#/}" != "$i" ] && echo $i
	done
}

getdefaultgrubdev(){ # Find the root or boot partition.
	local bootdev=""
	local rootdev=""
	for i in $*; do
	[ "$i" = "$tgt/" ] && rootdev="$j" || j=$i
	[ "$i" = "$tgt/boot" ] && bootdev="$k" || k=$i
	done
	[ "$bootdev" = "" ] && echo $rootdev && return
	echo $bootdev && return 67
}

listgrubdev(){
	for i in /dev/[hs]d[a-z]; do
	echo $i,MBR
	done

	for i in /dev/[hs]d[a-z][0-9]*; do
	vol_id $i > /dev/null 2>&1 || continue
	[ "`vol_id --type $i`" = "ntfs" ] && continue
	parted -s $i print > /dev/null 2>&1 || continue
	echo $i,`vol_id --type $i`
	done

	echo none,not_recommended
}

getmountoptions(){ # According to the default behavior of ubuntu installer. You can alter these or add options for other fs types.
	case "$*" in
	"/ ext4" ) echo relatime,errors=remount-ro;;
	"/ ext3" ) echo relatime,errors=remount-ro;;
	"/ ext2" ) echo relatime,errors=remount-ro;;
	"/ reiserfs" ) [ "$hasboot" = "yes" ] && echo relatime || echo notail,relatime;;
	"/ jfs" ) echo relatime,errors=remount-ro;;

	"/boot reiserfs" ) echo notail,relatime;;

	*"ntfs" ) echo defaults,umask=007,gid=46;;
	*"vfat" ) echo utf8,umask=007,gid=46;;
	*) echo relatime;;
	esac
}

generate_fstab(){
	local targetfstab="$*/etc/fstab"

	echo "# /etc/fstab: static file system information." > "$targetfstab"
	echo "#" >> "$targetfstab"
	echo "# <file system> <mount point>   <type>  <options>       <dump>  <pass>" >> "$targetfstab"
	echo "proc            /proc           proc    defaults        0       0" >> "$targetfstab"

	for i in $tgtmnt; do
	[ "${i#/dev/}" != "$i" ] && { echo "# $i" >> "$targetfstab"; j=$i; continue; }
	uuid="`vol_id --uuid $j`"
	[ "$uuid" = "" ] && partition=$j || partition="UUID=$uuid"
	mntpnt=${i#$tgt}
	fs=`vol_id --type $j`
	fsckorder=`echo "${i#$tgt/} s" | wc -w`
	echo "$partition $mntpnt $fs `getmountoptions "$mntpnt $fs"` 0 $fsckorder" >> "$targetfstab"
	done

	for i in /dev/[hs]d[a-z][0-9]*; do
	[ "`vol_id --type $i 2> /dev/null`" = swap ] || continue
	echo "# $i" >> "$targetfstab"
	swapuuid="`vol_id --uuid $i`"
	[ "$swapuuid" = "" ] && partition=$i || partition="UUID=$swapuuid"
	echo "$partition none swap sw 0 0" >> "$targetfstab"
	haswap="yes"
	[ -f $tgt/etc/initramfs-tools/conf.d/resume ] || { echo "RESUME=$partition" > $tgt/etc/initramfs-tools/conf.d/resume; continue; }
	lastresume="`cat $tgt/etc/initramfs-tools/conf.d/resume`"
	lastresume="${lastresume#RESUME=}"
	[ "${lastresume#UUID=}" != "$lastresume" ] && lastresume="`parted /dev/disk/by-uuid/${lastresume#UUID=} unit B print | grep /dev/`"
	[ "${lastresume#/dev/}" != "$lastresume" ] && lastresume="`parted $lastresume unit B print | grep /dev/`"
	lastresume=${lastresume#*:}
	lastresume=${lastresume#*：}	#有可能是全角冒号
	lastresume=${lastresume%B}
	thisresume="`parted $i unit B print | grep $i`"
	thisresume=${thisresume#*:}
	thisresume=${thisresume#*：}	#有可能是全角冒号
	thisresume=${thisresume%B}
	[ "$thisresume" -gt "$lastresume" ] && echo "RESUME=$partition" > $tgt/etc/initramfs-tools/conf.d/resume
	done

	echo "/dev/scd0 /media/cdrom0 udf,iso9660 user,noauto,exec,utf8 0 0" >> "$targetfstab"
}

makelostandfound(){ # If lost+found is removed from an ext? FS, create it with the command mklost+found. Don't just mkdir lost+found
	for i in $tgtmnt; do
	[ "${i#/dev/}" != "$i" ] && j=$i
	[ "${i#$tgt}" != "$i" ] &&  vol_id --type $j | grep ext > /dev/null && cd $i && mklost+found 2> /dev/null
	done
}

makeswapfile(){
	echored "You do not have a swap partition. Would you like a swap file? Default is yes.(y/n)"
	read yn
	[ "$yn" = "n" ] && return
	echored "The size of the swap file in megabytes, defaults to 512"
	read swapsize
	swapsize=`expr $swapsize + 0 2> /dev/null`
	[ "$swapsize" = "" ] && swapsize=512
	[ "$swapsize" = "0" ] && swapsize=512
	local sf=`new_dir $*/swapfile`
	echored "Generating swap file..."
	dd if=/dev/zero of=$sf bs=1M count=$swapsize
	mkswap $sf
	echo "${sf#$*}  none  swap  sw  0 0" >> "$*/etc/fstab"
}

sqshboot_menulst(){ # Generate a windows-notepad-compatible menu.lst in the backup directory with instructions to boot backup.squashfs directly.
	echo -e "# This menu.lst is for grub4dos only. You must edit it to use with gnu grub\r
\r
\r
# Instructions to boot your backup$today.squashfs directly on a windows PC:\r
# Download the latest grub4dos from http://download.gna.org/grub4dos\r
# Unzip grub4dos, then copy grldr and grldr.mbr to the root of your c: drive\r
# Also copy this menu.lst to the root of your c: drive\r
# Then make a directory \"casper\" under the root of any fat, ntfs, or ext partition and copy backup$today.squashfs, initrd.img-`uname -r`, vmlinuz-`uname -r` to the directory\r
# Then add this line to boot.ini (without #)\r
# c:\grldr.mbr=\"grub4dos\"\r
##### On Windows Vista, you can still create a boot.ini yourself with these lines:\r
##### [boot loader]\r
##### [operating systems]\r
##### c:\grldr.mbr=\"grub4dos\"\r
# Reboot and select grub4dos\r
\r
\r
# Instructions to boot your backup$today.squashfs directly on a linux PC:\r
# Make a directory \"casper\" under the root of any fat, ntfs, or ext partition and copy backup$today.squashfs, initrd.img-`uname -r`, vmlinuz-`uname -r` to the directory. (Note that NTFS is not readable by gnu grub so don't put initrd.img-`uname -r` & vmlinuz-`uname -r`  there)\r
# Then copy the Live Ubuntu Backup entries below to the end of your /boot/grub/menu.lst file and change the \"find --set-root\" line to \"root (hd?,?)\" (where you created the directory \"casper\")\r
\r
\r
default	0\r
timeout 10\r
\r
title Live Ubuntu Backup $today\r
find --set-root /casper/vmlinuz-`uname -r`\r
kernel /casper/vmlinuz-`uname -r` boot=casper ro ignore_uuid\r
initrd /casper/initrd.img-`uname -r`\r
\r
title Live Ubuntu Backup $today, Recovery Mode\r
find --set-root /casper/vmlinuz-`uname -r`\r
kernel /casper/vmlinuz-`uname -r` boot=casper ro single ignore_uuid\r
initrd /casper/initrd.img-`uname -r`\r"
}

windowsentry(){
	for i in /dev/[hs]d[a-z][0-9]*; do
	volid="`vol_id --type $i 2> /dev/null`"
	[ "$volid" != ntfs -a "$volid" != vfat ] && continue
	tmpdir=`new_dir /tmp/mnt`
	mkdir $tmpdir
	mount $i $tmpdir || { rmdir $tmpdir; continue; }
	disk=`expr substr $i 1 8`
	num=${i#$disk}
	num=`expr $num - 1`
	[ -f $tmpdir/bootmgr -o -f $tmpdir/ntldr ] && { echo >> $tgt/boot/grub/menu.lst; echo "# This entry may not be correct when you have multiple hard disks" >> $tgt/boot/grub/menu.lst; echo "title windows" >> $tgt/boot/grub/menu.lst; echo "rootnoverify (hd0,$num)" >> $tgt/boot/grub/menu.lst; echo "chainloader +1" >> $tgt/boot/grub/menu.lst; }
	umount $i
	rmdir $tmpdir
	done
}

cleartgtmnt(){
	[ "${part[$usrlocalpart]}" != "" ] && umount ${part[$usrlocalpart]}
	[ "${part[$homepart]}" != "" ] && umount ${part[$homepart]}
	[ "${part[$bootpart]}" != "" ] && umount ${part[$bootpart]}
	[ "${part[$tmppart]}" != "" ] && umount ${part[$tmppart]}
	[ "${part[$usrpart]}" != "" ] && umount ${part[$usrpart]}
	[ "${part[$varpart]}" != "" ] && umount ${part[$varpart]}
	[ "${part[$srvpart]}" != "" ] && umount ${part[$srvpart]}
	[ "${part[$optpart]}" != "" ] && umount ${part[$optpart]}
	umount ${part[$rootpart]} || echored "You may umount $tgt yourself"
}

dobackup(){
	bindingdir=`new_dir /tmp/bind`
	backupdir=`new_dir ~/backup-$today`
	bindingdir="${bindingdir#/}"
	backupdir="${backupdir#/}"
	packagecheck_b
	packagecheck_r
	echored "You are about to backup your system. It is recommended that you quit all open applications now. Continue?(y/n)"
	read yn
	[ "$yn" != "y" ] && exit 1
	echored "Specify an empty directory(absolute path) to save the backup. You can drag directory from Nautilus File Manager and drop it here. Feel free to use external media.
If you don't specify, the backup will be saved to /$backupdir"
	read userdefined_backupdir
	[ "$userdefined_backupdir" != "" ] && { userdefined_backupdir="`dequotepath "$userdefined_backupdir"`"; checkbackupdir "$userdefined_backupdir"; backupdir="${userdefined_backupdir#/}"; }

	exclude=`new_dir /tmp/exclude`
	echo $backupdir > $exclude
	echo $bindingdir >> $exclude
	echo boot/grub >> $exclude
	echo etc/fstab >> $exclude
	echo etc/mtab >> $exclude
	echo etc/blkid.tab >> $exclude
	echo etc/udev/rules.d/70-persistent-net.rules >> $exclude
	echo lost+found >> $exclude
	echo boot/lost+found >> $exclude
	echo home/lost+found >> $exclude
	echo tmp/lost+found >> $exclude
	echo usr/lost+found >> $exclude
	echo var/lost+found >> $exclude
	echo srv/lost+found >> $exclude
	echo opt/lost+found >> $exclude
	echo usr/local/lost+found >> $exclude

	for i in `swapon -s | grep file | cut -d " " -f 1`; do
	echo "${i#/}" >> $exclude
	done

	for i in `ls /tmp -A`; do
	echo "tmp/$i" >> $exclude
	done

	echored "Do you want to exclude all user files in /home? (y/n)"
	read yn
	if [ "$yn" = y ]; then
	for i in /home/*; do
	[ -f "$i" ] && echo "${i#/}" >> $exclude
	[ -d "$i" ] || continue
		for j in "$i"/*; do
		[ -e "$j" ] && echo "${j#/}" >> $exclude
		done
	done
	fi

	echored "Do you want to exclude all user configurations (hidden files) in /home as well? (y/n)"
	read yn
	if [ "$yn" = y ]; then
	for i in /home/*; do
	[ -d "$i" ] || continue
		for j in "$i"/.*; do
		[ "$j" = "$i/." ] && continue
		[ "$j" = "$i/.." ] && continue
		echo "${j#/}" >> $exclude
		done
	done
	fi

	echored "Do you want to exclude the local repository of retrieved package files in /var/cache/apt/archives/ ? (y/n)"
	read yn
	if [ "$yn" = y ]; then
	for i in /var/cache/apt/archives/*.deb; do
	[ -e "$i" ] && echo "${i#/}" >> $exclude
	done
	for i in /var/cache/apt/archives/partial/*; do
	[ -e "$i" ] && echo "${i#/}" >> $exclude
	done
	fi

	echored "(For advanced users only) Specify other files/folders you want to exclude from the backup, one file/folder per line. You can drag and drop from Nautilus. End with an empty line.\nNote that the program has automatically excluded all removable media, windows partitions, manually mounted devices, files under /proc, /sys, /tmp, the /host contents of a wubi install, etc. So in most cases you can just hit enter now.\nIf you exclude important system files/folders, the backup will fail to restore."
	read ex
	while [ "$ex" != "" ]; do
	ex=`dequotepath "$ex"`
	[ "${ex#/}" = "$ex" ] && { echo "You must specify the absolute path"; read ex; continue; }
	[ -e "$ex" ] || { echo "$ex does not exist"; read ex; continue; }
	ex="${ex#/}"
	echo $ex >> $exclude
	read ex
	done

	rebuildtree $bindingdir

	for i in /$bindingdir/media/*; do
	ls -ld "$i" | grep "^drwx------ " > /dev/null || continue
	[ `ls -A "$i" | wc -l` = 0 ] || continue
	echo "${i#/$bindingdir/}" >> $exclude
	done

	echored "Start to backup?(y/n)"
	read yn
	[ "$yn" != "y" ] && { destroytree $bindingdir; rm $exclude; exit 1; }
	stime=`date`
	mkdir -p "/$backupdir"
	mksquashfs /$bindingdir "/$backupdir/backup$today.squashfs" -ef $exclude
	destroytree $bindingdir
	rm $exclude
	cp /boot/initrd.img-`uname -r` "/$backupdir"
	cp /boot/vmlinuz-`uname -r` "/$backupdir"
	sqshboot_menulst > "/$backupdir/menu.lst"
	thisuser=`basename ~`
	chown -R $thisuser:$thisuser "/$backupdir" 2> /dev/null
	echored "Your backup is ready in /$backupdir. Please read the menu.lst inside :)"
	echored "start time: $stime\nend time: `date`"
	tput bel
}

dorestore(){
	sqshmnt="/rofs"
	tgtmnt=""
	haswap="no"
	hasboot="no"

	declare -a part oldfstype newfstype partinfo
	packagecheck_r
	echored "This will restore your backup. Continue? (y/n)"
	read yn
	[ "$yn" != "y" ] && exit 1

	echored "Specify the squashfs backup file (absolute path). You can drag the file from Nautilus File Manager and drop it here. If you are booting from the backup squashfs, you can just hit enter, and the squashfs you are booting from will be used."
	read backupfile
	[ "$backupfile" = "" ] && { ls /rofs > /dev/null 2>&1 || { echored "/rofs not found"; exit 1; } }
	[ "$backupfile" != "" ] && { backupfile="`dequotepath "$backupfile"`"; sqshmnt=`new_dir /tmp/sqsh`; mkdir $sqshmnt; mount -o loop "$backupfile" $sqshmnt 2> /dev/null || { echored "$backupfile mount error"; rmdir $sqshmnt; exit 1; } }

	probe_partitions
	setup_target_partitions
	echored "Start to format partitions (if any). Continue? (y/n)"
	read yn
	[ "$yn" != "y" ] && [ "$sqshmnt" != "/rofs" ] && { umount $sqshmnt; rmdir $sqshmnt; }
	[ "$yn" != "y" ] && exit 1
	umount_target_partitions
	format_target_partitions
	chkuuids
	mount_target_partitions

	echored "If you have other partitions for the target system, open another terminal and mount them to appropriate places under $tgt. Then press return."
	read yn

	tgtmnt=`gettargetmount $tgt`
	defaultgrubdev=`getdefaultgrubdev "$tgtmnt"`
	[ $? = 67 ] && hasboot=yes
	echored "Specify the place into which you want to install GRUB stage1."
	echored "`expr substr $defaultgrubdev 1 8` and $defaultgrubdev are recommended."
	select grubdev in `listgrubdev`; do
	[ "$grubdev" = "" ] && continue
	break
	done
	grubdev=${grubdev%,*}

	echored "The restore process will launch. Continue?(y/n)"
	read yn
	[ "$yn" != "y" ] && [ "$sqshmnt" != "/rofs" ] && { umount $sqshmnt; rmdir $sqshmnt; }
	[ "$yn" != "y" ] && { cleartgtmnt; exit 1; }
	stime=`date`
	cp -av $sqshmnt/* $tgt
	rm -f $tgt/etc/initramfs-tools/conf.d/resume
	touch $tgt/etc/mtab
	generate_fstab "$tgt"
	target_cmd "$tgt" update-initramfs -u

	if [ "${grubdev#/dev/}" != "$grubdev" ]; then
	mv $tgt/boot/grub `new_dir $tgt/boot/grub.old` 2> /dev/null
	grub-install --root-directory="$tgt" $grubdev
	grub-install --root-directory="$tgt" $grubdev
	# grub-install (onto reiserfs) sometimes fails for unknown reason. Installing it twice succeeds most of the time.
	target_cmd "$tgt" update-grub -y
	sed -i "s/^hiddenmenu/#hiddenmenu/" $tgt/boot/grub/menu.lst
	windowsentry
	fi

	makelostandfound
	tput bel
	[ "$haswap" = "no" ] && makeswapfile $tgt
	[ "$sqshmnt" != "/rofs" ] && { umount $sqshmnt; rmdir $sqshmnt; }

	echored "Enter new hostname or leave blank to use the old one"
	oldhostname=`cat $tgt/etc/hostname`
	echored "old hostname: $oldhostname"
	echored "new hostname:"
	read newhostname
	[ "$newhostname" != "" ] && { echo $newhostname > $tgt/etc/hostname; sed -i "s/\t$oldhostname/\t$newhostname/g" $tgt/etc/hosts; }

	for i in `ls $tgt/home`; do
	[ -d $tgt/home/$i ] || continue
	target_cmd "$tgt" id $i 2> /dev/null | grep "$i" > /dev/null || continue
	echored "Do you want to change the name of user $i? (y/n)"
	read yn
	[ "$yn" != "y" ] && continue
	echored "new username:"
	read newname
		while target_cmd "$tgt" id $newname 2> /dev/null | grep "$newname" > /dev/null; do
		echored "$newname already exists"
		echored "new username:"
		read newname
		done
	[ -e $tgt/home/$newname ] && mv $tgt/home/$newname `new_dir $tgt/home/$newname`
	target_cmd "$tgt" chfn -f $newname $i
	target_cmd "$tgt" usermod -l $newname -d /home/$newname -m $i
	target_cmd "$tgt" groupmod -n $newname $i
	done

	for i in `ls $tgt/home`; do
	[ -d $tgt/home/$i ] || continue
	target_cmd "$tgt" id $i 2> /dev/null | grep "$i" > /dev/null || continue
	echored "Do you want to change the password of user $i? (y/n)"
	read yn
		while [ "$yn" = "y" ]; do
		target_cmd "$tgt" passwd $i
		echored "If the password was not successfully changed, now you have another chance to change it. Do you want to change the password of user $i again? (y/n)"
		read yn
		done
	done

	rm -f $tgt/etc/blkid.tab
	[ "${part[$usrlocalpart]}" != "" ] && umount ${part[$usrlocalpart]}
	[ "${part[$homepart]}" != "" ] && umount ${part[$homepart]}
	[ "${part[$bootpart]}" != "" ] && umount ${part[$bootpart]}
	[ "${part[$tmppart]}" != "" ] && umount ${part[$tmppart]}
	[ "${part[$usrpart]}" != "" ] && umount ${part[$usrpart]}
	[ "${part[$varpart]}" != "" ] && umount ${part[$varpart]}
	[ "${part[$srvpart]}" != "" ] && umount ${part[$srvpart]}
	[ "${part[$optpart]}" != "" ] && umount ${part[$optpart]}
	umount ${part[$rootpart]} || echored "You may umount $tgt yourself"
	echored "Done! Enjoy:)"
	echored "start time: $stime\nend time: `date`"
}

echohelp(){
	echo "live ubuntu backup $version, copyleft billbear <billbear@gmail.com>

This program can backup your running ubuntu system to a compressed, bootable squashfs file. When you want to restore, boot the squashfs backup and run this program again. You can also restore the backup to another machine. And with this script you can migrate ubuntu system on a virtual machine or a wubi installation to physical partitions.

Install:
Just copy this script anywhere and allow execution of the script. I put this script under /usr/local/bin, so that I don't have to type the path to this script everytime.

Use:
sudo /path/to/this/script -b
to backup or
sudo /path/to/this/script -r
to restore
You can also type
sudo bash /path/to/this/script -b
or
sudo bash /path/to/this/script -r

Note that
sudo sh /path/to/this/script -b
and
sudo sh /path/to/this/script -r
will not work.

Backup:
squashfs-tools is required for this program to backup your system. lupin-casper is required to make a bootable backup.
You can install them by typing
sudo apt-get install squashfs-tools lupin-casper
in a terminal.
Then you can backup your running ubuntu system by typing
sudo /path/to/this/script -b
If you put this script under /usr/local/bin, just type
sudo `basename $mypath` -b
and follow the instructions.
You can specify where to save the backup, files/folders you want to exclude from the backup.
You don't need to umount external media, windows partitions, or any manually mounted partitions. They will be automatically ignored. Therefore you can save the backup to external media, windows partitions, etc.
Waring: You must make sure you have enough space to save the backup.
The program will generate other files needed for booting the backup. Read the menu.lst file the program generated under the backup folder for details on how to boot the backup.

Restore:
Read the menu.lst file the program generated under the backup folder for details on how to boot the backup.
After booting into the live ubuntu backup, open a terminal and type
sudo /path/to/this/script -r
If you have put this script under /usr/local/bin when backup, now just type
sudo `basename $mypath` -r
and follow the instructions.
Note: This program does not provide a partitioner (it can only format partitions but cannot create, delete, or resize partitions). The backup can be restored to existing partitions. So it is recommended that you include gparted in the backup. And if the partition table has any error, you will not be able to restore the backup until the errors are fixed.
You can specify partitions and mount points, if you have no swap partition, the program will make a swap file for you if you tell it to do so. It will generate new fstab and install grub. It can also change the hostname, username and password if you tell it to do so." | more
}

echousage(){
	echo "Usage:
sudo bash $mypath -b
to backup;
or
sudo bash $mypath -r
to restore;
or
bash $mypath -h
to view help."
}


[ "$*" = -h ] && { echohelp; exit 0; }
[ "`id -u`" != 0 ] && { echo "Root privileges are required for running this program."; echousage; exit 1; }
[ "$*" = -b ] && { dobackup; exit 0; }
[ "$*" = -r ] && { dorestore; exit 0; }
echousage
exit 1

