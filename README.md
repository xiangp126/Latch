- This project aims to deploy OpenGrok on Linux server by just single command
    - automatically generating PATH/config files, need not set extra var
    - [use split/cat to store large packages originally transient on Oracle official website](https://github.com/xiangp126/split-and-cat)
    - server user is jsvc, more safe than jsut use root
- Imcremental install supported, safe to run consecutive times
- Has checked on on Ubuntu 14.04 LTS | CentOS 6.9
- May install
    - universal ctags latest
    - java 		v(8u161)
    - tomcat 	v(8.5.27)
    - OpenGrok  v(1.1-rc21)

Current released version: 2.7

## Quick Start
```bash
$ sh oneKey.sh
[NAME]
    sh oneKey.sh -- setup OpenGrok through one key stroke

[SYNOPSIS]
    sh oneKey.sh [install | summary | help] [PORT]

[EXAMPLE]
    sh oneKey.sh [help]
    sh oneKey.sh install
    sh oneKey.sh install 8081
    sh oneKey.sh summary

[DESCRIPTION]
    install -> install opengrok, need root privilege but no sudo prefix
    help    -> print help page
    summary -> print tomcat/opengrok guide and installation info

[TIPS]
    Default listen-port is 8080 if [PORT] was omitted

  ___  _ __   ___ _ __   __ _ _ __ ___ | | __
 / _ \| '_ \ / _ \ '_ \ / _` | '__/ _ \| |/ /
| (_) | |_) |  __/ | | | (_| | | | (_) |   <
 \___/| .__/ \___|_| |_|\__, |_|  \___/|_|\_\
      |_|               |___/
```
```bash
$ sh oneKey.sh install
```

## Brief Usage
```bash
$ sh oneKey.sh summary
-------------------------------------------------
FOR TOMCAT 8 GUIDE
-------------------------------------------------
-- Under /home/corsair/myGit/cc-opengrok
# start tomcat
sudo ./daemon.sh start
or
sudo ./daemon.sh run
sudo ./daemon.sh run &> /dev/null &
# stop tomcat
sudo ./daemon.sh stop
-------------------------------------------------
FOR OPENGROK GUIDE
-------------------------------------------------
-- Under ./downloads/opengrok-1.1-rc17/bin
# deploy OpenGrok
sudo ./OpenGrok deploy

# if make soft link of source to SRC_ROOT
# care for Permission of SRC_ROOT for user: tomcat8
cd /opt/o-source
sudo ln -s /usr/local/src/* .

# make index of source (multiple index)
sudo ./OpenGrok index [/opt/o-source]
                       /opt/source   -- proj1
                                     -- proj2
                                     -- proj3
--------------------------------------------------------
-- GUIDE TO CHANGE LISTEN PORT
# replace s/original/8080/ to the port you want to change
sudo sed -i 's/8080/8080/' /opt/tomcat8/conf/server.xml
sudo ./daemon.sh stop
sudo ./daemon.sh start
------------------------------------------------------
TOMCAT STARTED SUCCESSFULLY
---------------------------------------- SUMMARY ----
universal ctags path = /usr/local/bin/ctags
git-lfs path = /usr/local/bin/git-lfs
java path = /opt/java8/bin/java
jsvc path = /opt/tomcat8/bin/jsvc
java home = /opt/java8
tomcat home = /opt/tomcat8
opengrok instance base = /opt/opengrok
opengrok source root = /opt/o-source
http://127.0.0.1:8080/source
------------------------------------------------------
```

## Reference
- [UBUNTU INSTALL TOMCAT-8 - DIGITAL OCEAN](https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-8-on-ubuntu-14-04)
- [CENTOS 6 UPGRADE TO KERNEL 4.4, FIXING JAVA FATAL ERROR](https://www.jianshu.com/p/25d8ecc75846)
