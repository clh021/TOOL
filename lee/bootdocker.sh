#!/bin/bash
sudo service docker restart

sudo docker stop $(docker ps -aq) && sudo docker rm $(docker ps -aq)

sudo docker run --rm -i -t -p 80:80 -p 3306:3306 -v ~/WORK/home.chenlianghong:/home/chenlianghong -v ~/WORK:/app -v ~/WORK/mysqldb:/var/lib/mysql -e MYSQL_PASS="admin" leehom/lamp /bin/bash

scp deepin-wiki.tar.gz root@121.199.27.77:~/
scp -r root@121.199.27.77:~/website-code/database-bak ~/WORK/database-bak
scp root@121.199.27.77:~/website-code/database-bak/bbs.sql ~/WORK/database-bak/
scp root@121.199.27.77:~/website-code/database-bak/ucenter.sql ~/WORK/database-bak/
