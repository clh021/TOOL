#!/bin/bash
sudo apt-get install phantomjs
sudo git clone git://github.com/n1k0/casperjs.git
sudo ln -sf $PWD/casperjs/bin/casperjs /usr/local/bin/casperjs