## CC-OpenGrok
Goal to deploy OpenGrok through onekey stroke under Unix like platform

Verified on Ubuntu 14.04 LTS | CentOS 6.9 (kernel 6.9)

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

$ sh oneKey.sh install
```

## Reference
[ubuntu install tomcat-8 - digital ocean](https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-8-on-ubuntu-14-04)

[CentOS 6 upgrade to kernel 4.4, fixing java fatal error](https://www.jianshu.com/p/25d8ecc75846)
