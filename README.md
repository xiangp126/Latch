## CC-OpenGrok
- Goal to deploy OpenGrok under Linux like platform through 'onekey' stroke

- Automatically generating PATH/config files, no need extra var set

- Verified on Ubuntu 14.04 LTS | CentOS 6.9
    - universal ctags
    - java   >= 1.8
    - tomcat >= 8
    - OpenGrok latest version

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
------------------------------------------------------
universal ctags path = /usr/local/bin/ctags
java path = /opt/java8/bin/java
jsvc path = /opt/tomcat8/bin/jsvc
java home = /opt/java8
tomcat home = /opt/tomcat8
opengrok instance base = /opt/opengrok
opengrok source root = /opt/o-source
http://127.0.0.1:8080/source
------------------------------------------------------
```
```bash
$ sh oneKey.sh install
```

## Reference
[ubuntu install tomcat-8 - digital ocean](https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-8-on-ubuntu-14-04)

[CentOS 6 upgrade to kernel 4.4, fixing java fatal error](https://www.jianshu.com/p/25d8ecc75846)
