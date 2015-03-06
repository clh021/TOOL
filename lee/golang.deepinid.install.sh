sudo apt-get install golang

echo 'export GOROOT=/usr/lib/go' >> ~/.profile
echo 'export GOPATH=$HOME/workspace/go' >> ~/.profile
echo 'export PATH=$GOPATH/bin:$PATH' >> ~/.profile
source /etc/profile
go get github.com/go-sql-driver/mysql
go get github.com/Iceyer/go-uuid/uuid
go get github.com/Iceyer/phpbbencrypt
go get github.com/Iceyer/osin
go get github.com/Iceyer/deepin-rest-core

ln -s .. ...

vi conf/deepin_oauth_server_config.json

# init database
#import server/database/create_tables.sql
cd tools/init
go build
./init

