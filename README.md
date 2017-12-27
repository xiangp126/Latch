# Prerequisite
verified on 
* Ubuntu 14.04 LTS
* CentOS 6.9 with kernel 6.9

# Installation Guide
script oneKey.sh does not use apt-get or yum install

* universal ctags
* java   >= 1.8
* tomcat >= 8
* OpenGrok latest version

```bash
$ sh oneKey.sh 
[NAME]
        oneKey.sh -- setup opengrok through one script

[USAGE]
        oneKey.sh [install | help]

  ___  _ __   ___ _ __   __ _ _ __ ___ | | __
 / _ \| '_ \ / _ \ '_ \ / _` | '__/ _ \| |/ /
| (_) | |_) |  __/ | | | (_| | | | (_) |   <
 \___/| .__/ \___|_| |_|\__, |_|  \___/|_|\_\
      |_|               |___/

$ sh oneKey.sh install

```
# Steps Summary
## Install universal ctags
```bash
git clone https://github.com/universal-ctags/ctags
cd ctags
./autogen.sh
#make sure /home/virl/.usr under PATH
./configure --prefix=/home/virl/.usr
make -j
make install

$ which ctags
/home/virl/.usr/bin/ctags
$ ctags --version
Universal Ctags 0.0.0(d161653), Copyright (C) 2015 Universal Ctags Team
Universal Ctags is derived from Exuberant Ctags.
Exuberant Ctags 5.8, Copyright (C) 1996-2009 Darren Hiebert
  Compiled: Dec 21 2017, 04:27:40
  URL: https://ctags.io/
  Optional compiled features: +wildcards, +regex, +multibyte, +option-directory, +xpath

```

## Install java-8
see script for detail

## Install tomcat-8
```bash
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

mkdir -p ~/.usr/src
cd ~/.usr/src
wget http://mirror.sdunix.com/apache/tomcat/tomcat-8/v8.0.23/bin/apache-tomcat-8.0.23.tar.gz
sudo mkdir -p /opt/tomcat
# untar into /opt/tomcat and strip one level directory
sudo tar xvf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1

cd /opt/tomcat
sudo chgrp -R tomcat conf
sudo chmod g+rwx conf
sudo chmod g+r conf/*

sudo chown -R tomcat work/ temp/ logs/
sudo update-alternatives --config java

sudo cp tomcat.conf /etc/init/tomcat.conf

# change default listen port 8080 to 8081
sudo cp server.xml /opt/tomcat/conf/server.xml

initctl reload-configuration
initctl start tomcat

```

## Install opengrok
```bash
# Get released binary, not source tar ball.
wget https://github.com/oracle/opengrok/releases/download/1.1-rc18/opengrok-1.1-rc18.tar.gz
tar -zxv -f opengrok-1.1-rc18.tar.gz
cd opengrok-1.1-rc18.tar.gz

export JAVA_HOME=/usr/lib/jvm/java-8-oracle
export CATALINA_HOME=/opt/tomcat
export OPENGROK_TOMCAT_BASE=$CATALINA_HOME

cd bin
sudo sh -x OpenGrok deploy
sudo sh -x OpenGrok index

```

# Reference
[ubuntu install tomcat-8 - digital ocean](https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-8-on-ubuntu-14-04)

[CentOS 6 upgrade to kernel 4.4, fixing java fatal error](https://www.jianshu.com/p/25d8ecc75846)
