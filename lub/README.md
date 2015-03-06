# **linux系统备份还原脚本**
***



# 项目说明
This program can backup your running ubuntu system to a compressed, bootable squashfs file. When you want to restore, boot the squashfs backup and run this program again. You can also restore the backup to another machine. And with this script you can migrate ubuntu system on a virtual machine or a wubi installation to physical partitions.

可以备份您的运行Ubuntu系统到一个压缩的程序，可引导的squashfs文件。当你想恢复，启动的squashfs备份并再次运行此程序。你还可以备份还原到另一台机器。与此脚本可以迁移到一个虚拟机或Wubi安装Ubuntu系统物理分区。

***


# 目录说明：

lee 个人根据实际需要不断修改的版本,您可以根据自己的需要抽取自己喜欢的版本使用

lub.sh 官方初始版本(收藏)

lub.zh.en.sh 官方多语言版本(收藏)


***

http://forum.ubuntu.org.cn/viewtopic.php?f=21&%20t=206287 由billbear在08年发布的脚本

在保存收藏原版的同时，自己进行改编，方便平时需要


***
## 个人修改版本(命令调用方式一样)
------------------------------
###  会在home/remastersys/文件夹中生成目录

会在home/remastersys/文件夹中生成目录，这是为了适应remastersys软件使用者（remastersys备份成更易启动的iso再使用本脚本恢复系统），你也可以用来存放不用备份的内容的（比如体积较大的绿色软件，不用安装的，解压即可运行的，还有别的电影，还有就是往期的备份，我会存放多个备份方便恢复，我会把的我的备份隔一段时间同步到我的其它电脑中。）

### 备份文件包含多元系统信息

生成的备份包含多个文件，其中还包含一个文本文档，内有备份系统的内核信息，方便同时玩多个系统，备份多个系统的时候识别

### 备份时间精确到秒

备份一律按照当前时间（精确到秒）来命名，方便识别，有的时候启动内核是一样的，不过目前来讲已经不需要担心这个问题了。

### 方便快捷的备份系统，启动备份和恢复系统

关于启动和恢复，启动的时候只需要把备份的文件夹重命名为casper即可启动，内部仍然会包含有文件信息，所以不用担心改名后无法识别的混淆问题。

### 操作简便敏捷

操作简便，已经默认定义好了备份目录和排除文件夹，除了几个必要的选项操作以外所有交互式选项都可以直接回车默认进行。操作非常简便快速。

************************************************************************


 使用帮助 (lub -h)：  
--------------------
```bash
ubuntu@ubuntu-laptop:~$ lub -h
live ubuntu backup, 作者 billbear
本程序将帮助你备份运行中的 ubuntu 系统为一个可启动的 squashfs 压缩备份文件。
要恢复的时候, 从备份文件启动并再次运行本程序。
可以把备份文件恢复到另一台机器。
可以把虚拟机里的 ubuntu 迁移到真机。
可以把 wubi 安装的系统迁移到真分区。

安装:
只要拷贝此脚本到任何地方并赋予执行权限即可。
我喜欢把它放在 /usr/local/bin 里面, 这样每次运行的时候就不用写绝对路径了。

使用:
sudo 到此脚本的路径 -b
是备份，而
sudo 到此脚本的路径 -r
是恢复。
也可以用
sudo bash 到此脚本的路径 -b
和
sudo bash 到此脚本的路径 -r

注意不能用
sudo sh 到此脚本的路径 -b
和
sudo sh 到此脚本的路径 -r

备份:
程序依赖 squashfs-tools 来工作。
另外必须安装 lupin-casper 才能做出可启动的备份来。
在终端用如下命令来安装它们:
sudo apt-get install squashfs-tools lupin-casper
而后就可以用这样的命令来备份运行中的 ubuntu 系统了:
sudo 到此脚本的路径 -b
如果这个脚本在 /usr/local/bin, 只要这样
sudo lub -b
然后根据提示进行就可以了。
你可以指定存放备份的路径, 以及需要排除的文件和目录。
不必卸载移动硬盘, windows 分区, 或任何你手动挂载了的分区。它们将会自动被忽略。
因此你可以直接存放备份到移动硬盘, windows 分区等等。
小心: 你必须确定有足够的空间来存放备份。
脚本将会生成启动所需的另外几个文件。
阅读在备份存放目录生成的 menu.lst，里面会详细告诉你如何从备份文件直接启动。

恢复:
阅读在备份存放目录生成的 menu.lst，里面会详细告诉你如何从备份文件直接启动。
启动了 live ubuntu backup 之后, 打开一个终端输入
sudo 到此脚本的路径 -r
如果在备份时已经把此脚本放到了 /usr/local/bin, 现在只需敲入
sudo lub -r
并根据提示进行恢复就可以了。
注意:此脚本并不提供分区功能(只能格式化分区但不能创建,删除分区或调整分区大小)。
只能恢复备份到已有的分区。
因此建议在备份前安装 gparted，这样恢复时你就有分区工具可用了。
另外如果分区表有错误, 将不允许恢复备份，直到错误被修复。
你可以指定若干分区和它们的挂载点。
如果没有 swap 分区, 可以为你创建一个 swap 文件 (如果你这样要求的话)。
会自动生成新的 fstab 并安装 grub。
如果有必要, 还可以改变主机名, 用户名和密码。
```


 备份(sudo lub -b)：  
----------------------
```bash
ubuntu@ubuntu-laptop:~$ sudo lub -b
将要备份系统。建议退出其他程序。继续?(y/n)
y
指定一个空目录 (绝对路径) 来存放备份。可以从 Nautilus 文件管理器拖放目录至此。可以使用移动硬盘。
如果不指定, 将会存放到 /home/ubuntu/backup-20090524

指定需要排除的文件/目录, 一行写一个。可以从 Nautilus 文件管理器拖放至此。以空行结束。

开始备份?(y/n)
y
Parallel mksquashfs: Using 1 processor
Creating little endian 3.1 filesystem on /home/ubuntu/backup-20090524/backup20090524.squashfs, block size 131072.
[=========================================================== ] 92925/93032  99%File /tmp/bind/var/log/ConsoleKit/history changed size while reading filesystem, attempting to re-read
[=========================================================== ] 92930/93032  99%File /tmp/bind/var/log/auth.log changed size while reading filesystem, attempting to re-read
[=========================================================== ] 93001/93032  99%File /tmp/bind/var/log/messages changed size while reading filesystem, attempting to re-read
[=========================================================== ] 93006/93032  99%File /tmp/bind/var/log/syslog changed size while reading filesystem, attempting to re-read
[=========================================================== ] 93013/93032  99%File /tmp/bind/var/log/user.log changed size while reading filesystem, attempting to re-read
[============================================================] 93032/93032 100%
Exportable Little endian filesystem, data block size 131072, compressed data, compressed metadata, compressed fragments, duplicates are removed
Filesystem size 789719.00 Kbytes (771.21 Mbytes)
   40.17% of uncompressed filesystem size (1966107.66 Kbytes)
Inode table size 1155385 bytes (1128.31 Kbytes)
   29.20% of uncompressed inode table size (3957443 bytes)
Directory table size 1113938 bytes (1087.83 Kbytes)
   46.99% of uncompressed directory table size (2370406 bytes)
Number of duplicate files found 8348
Number of inodes 115900
Number of files 87876
Number of fragments 6597
Number of symbolic links  14964
Number of device nodes 95
Number of fifo nodes 3
Number of socket nodes 35
Number of directories 12927
Number of uids 14
   root (0)
   syslog (101)
   ubuntu (1000)
   daemon (1)
   polkituser (109)
   libuuid (100)
   lp (7)
   man (6)
   avahi-autoipd (104)
   gdm (105)
   news (9)
   messagebus (108)
   hplip (103)
   klog (102)
Number of gids 29
   video (44)
   audio (29)
   tty (5)
   kmem (15)
   disk (6)
   adm (4)
   daemon (1)
   dip (30)
   lp (7)
   fuse (104)
   shadow (42)
   ssl-cert (105)
   messagebus (117)
   crontab (107)
   mail (8)
   lpadmin (106)
   mlocate (108)
   utmp (43)
   ssh (109)
   games (60)
   polkituser (118)
   root (0)
   staff (50)
   libuuid (101)
   src (40)
   admin (121)
   avahi-autoipd (110)
   gdm (111)
   klog (103)
已备份至 /home/ubuntu/backup-20090524。请阅读里面的 menu.lst :)
```  

恢复(sudo lub -r) :
---------------------
``` bash
ubuntu@ubuntu:~$ sudo lub -r
将恢复你的备份。继续? (y/n)
y
指定 squashfs 备份文件 (绝对路径)。可以从 Nautilus 文件管理器拖放。如果你是从备份的 squashfs 启动的, 直接回车即可, 将会使用本次启动的 squashfs 文件。

将哪个分区作为 / ?
1) /dev/sda1 ntfs  5198MB      5) /dev/sda7 swap  625MB
2) /dev/sda10 swap  280MB      6) /dev/sda8 jfs  1464MB
3) /dev/sda5 reiserfs  206MB   7) /dev/sda9 ext2  1291MB
4) /dev/sda6 reiserfs  6087MB  8) /dev/sdb1 vfat  8015MB
#? 4
你选择的是 /dev/sda6, 里面现有这些文件/目录:
bin   cdrom  etc   initrd.img  media  opt   root  selinux  sys   usr  vmlinuz
boot  dev    home  lib          mnt    proc  sbin  srv      tmp   var
确定?(y/n)
y
是否格式化此分区?(y/n)
y
格式化 /dev/sda6 为:
1) ext2
2) ext3
3) ext4
4) reiserfs
5) jfs
6) xfs
#? 3
将哪个分区作为 swap ?
1) /dev/sda1 ntfs  5198MB        6) /dev/sda8 jfs  1464MB
2) /dev/sda10 swap  280MB        7) /dev/sda9 ext2  1291MB
3) /dev/sda5 reiserfs  206MB     8) /dev/sdb1 vfat  8015MB
4)             　　　　　　　　　　　9) 无
5) /dev/sda7 swap  625MB      　 10) 无，并结束分区设定。
#? 7
你选择的是 /dev/sda9, 里面现有这些文件/目录:
lost+found
确定?(y/n)
y
/dev/sda9 将被格式化为 swap.
将哪个分区作为 /home ?
1) /dev/sda1 ntfs  5198MB        6) /dev/sda8 jfs  1464MB
2) /dev/sda10 swap  280MB        7) 
3) /dev/sda5 reiserfs  206MB     8) /dev/sdb1 vfat  8015MB
4)             　　　　　　　　　　　9) 无
5) /dev/sda7 swap  625MB       　10) 无，并结束分区设定。
#? 6
你选择的是 /dev/sda8, 里面现有这些文件/目录:
billbear
确定?(y/n)
y
是否格式化此分区?(y/n)
y
格式化 /dev/sda8 为:
1) ext2
2) ext3
3) ext4
4) reiserfs
5) jfs
6) xfs
#? 6
将哪个分区作为 /boot ?
1) /dev/sda1 ntfs  5198MB        6) 
2) /dev/sda10 swap  280MB        7) 
3) /dev/sda5 reiserfs  206MB     8) /dev/sdb1 vfat  8015MB
4)             　　　　　　　　　　　9) 无
5) /dev/sda7 swap  625MB      　 10) 无，并结束分区设定。
#? 3
你选择的是 /dev/sda5, 里面现有这些文件/目录:
abi-2.6.28-11-generic         memtest86+.bin
config-2.6.28-11-generic      System.map-2.6.28-11-generic
grub               vmcoreinfo-2.6.28-11-generic
initrd.img-2.6.28-11-generic  vmlinuz-2.6.28-11-generic
确定?(y/n)
y
是否格式化此分区?(y/n)
y
格式化 /dev/sda5 为:
1) ext2
2) ext3
3) ext4
4) reiserfs
5) jfs
6) xfs
#? 1
将哪个分区作为 /tmp ?
1) /dev/sda1 ntfs  5198MB        6) 
2) /dev/sda10 swap  280MB        7) 
3)                       　　　　　8) /dev/sdb1 vfat  8015MB
4)             　　　　　　　　　　　9) 无
5) /dev/sda7 swap  625MB       　10) 无，并结束分区设定。
#? 10
开始格式化分区 (如果有需要格式化的分区的话)。继续? (y/n)
y
正在格式化 /dev/sda6
Done

正在格式化 /dev/sda8
Done

正在格式化 /dev/sda5
Done

正在格式化 /dev/sda9
Setting up swapspace version 1, size = 1261064 KiB
no label, UUID=a3491a9c-8226-4a29-bcf7-608b5a4e553f
Done

如果你为目标系统安排了其他分区, 现在打开另一个终端并挂载它们在 /tmp/target 下合适的地方。完成后回车。

把 GRUB stage1 安装到哪里?
建议安装到 /dev/sda 或 /dev/sda5
1) /dev/sda,MBR             6) /dev/sda7,swap
2) /dev/sdb,MBR             7) /dev/sda8,xfs
3) /dev/sda10,swap          8) /dev/sda9,swap
4) /dev/sda5,ext2           9) /dev/sdb1,vfat
5) /dev/sda6,ext4           10) 不安装（不推荐）
#? 1
将马上开始恢复。继续?(y/n)
y
......
输入新的主机名。留空将使用旧的主机名。
旧的主机名: ubuntu-laptop
新的主机名:
billbear-pc
是否改变用户名 ubuntu? (y/n)
y
新的用户名:
billbear
是否改变用户 billbear 的密码? (y/n)
y
输入新的 UNIX 口令： 
重新输入新的 UNIX 口令： 
passwd：已成功更新密码
如果刚才的密码改变不成功, 你还有机会。是否再次改变用户 billbear 的密码? (y/n)
n
搞定了 :)
ubuntu@ubuntu:~$ 
```  
