#!/bin/bash

#
# To run: sudo bash server.bash
#

PROJECT_HOME_PATH="$(pwd)"

apt-get update
apt-get install -y tk8.5 tcl8.5 openjdk-6-jre-headless

if [ ! -d /opt/redis-2.6.12 ] ; then
	cd /opt/
	wget http://redis.googlecode.com/files/redis-2.6.12.tar.gz
	tar zxvf redis-2.6.12.tar.gz
	cd redis-2.6.12
	make
	make test
	rm ../redis-2.6.12.tar.gz
	cd $PROJECT_HOME_PATH
fi

if ! dpkg -s elasticsearch >/dev/null; then
	wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.20.6.deb
	dpkg -i elasticsearch-0.20.6.deb
	rm elasticsearch-0.20.6.deb
fi
