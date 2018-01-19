## CC-OpenGrok
Goal to deploy OpenGrok through onekey stroke under Unix like platform

Automatically generating needed env files, no need extra PATH set

Verified on Ubuntu 14.04 LTS | CentOS 6.9

* universal ctags
* java   >= 1.8
* tomcat >= 8
* OpenGrok latest version

```bash
$ sh oneKey.sh 
[NAME]
    sh oneKey.sh -- setup opengrok through one script
                | shell need root privilege, but
                | no need run with sudo prefix

[USAGE]
    sh oneKey.sh [install | help] [Listen-Port]
    #default Listen-Port 8080 if para was omitted

  ___  _ __   ___ _ __   __ _ _ __ ___ | | __
 / _ \| '_ \ / _ \ '_ \ / _` | '__/ _ \| |/ /
| (_) | |_) |  __/ | | | (_| | | | (_) |   <
 \___/| .__/ \___|_| |_|\__, |_|  \___/|_|\_\
      |_|               |___/

```
```bash
$ sh oneKey.sh help
-------------------------------------------------
FOR TOMCAT 8 HELP
-------------------------------------------------
-- Under ~/myGit/cc-opengrok
# start tomcat
sudo ./daemon.sh start
or
sudo ./daemon.sh run
sudo ./daemon.sh run &> /dev/null &
# stop tomcat
sudo ./daemon.sh stop
-------------------------------------------------
FOR OPENGROK HELP
-------------------------------------------------
-- Under ./opengrok-1.1-rc17/bin
# deploy OpenGrok
sudo ./OpenGrok deploy

# make soft link of source to SRC_ROOT
# care for Permission of SRC_ROOT for user: tomcat8
cd /opt/o-source
sudo ln -s /usr/local/src/* .

# make index of source (multiple index)
sudo ./OpenGrok index [/opt/o-source]
                       /opt/source   -- proj1
                                     -- proj2
                                     -- proj3
--------------------------------------------------------
-- GUIDE TO CHANGE LISTEN PORT ...
# replace s/original/8080/ to the port you want to change
sudo sed -i 's/8080/8080/'
sudo ./daemon.sh stop
sudo ./daemon.sh start
------------------------------------------------------
```
```bash
$ sh oneKey.sh install
```

## Reference
[ubuntu install tomcat-8 - digital ocean](https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-8-on-ubuntu-14-04)

[CentOS 6 upgrade to kernel 4.4, fixing java fatal error](https://www.jianshu.com/p/25d8ecc75846)
