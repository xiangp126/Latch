- This project aims to deploy OpenGrok on server by just single command
    - automatically generating PATH/config files, no extra env set needed
    - use [split/cat](https://github.com/xiangp126/split-and-cat) to store large packages originally transient on Oracle official website
    - server user is jsvc, more safe than blind use root
    - specify listen port as parameter, 8080 default
    - cron update shell provided
- Imcremental install supported, safe to run consecutive times
- May install for Linux
    - universal ctags latest
    - java 		v(8u171)
    - tomcat 	v(8.5.31)
    - OpenGrok  v(1.1-rc27)
- Add support for Mac OS from tag 2.9

Current released version: 2.9

![](./gif/guide.gif)

## Quick Start
```bash
git clone https://github.com/xiangp126/Let-OpenGrok
```
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

Then browser http://server-ip:8080/source

Put your source into OPENGROK_SRC_ROOT
```

## Brief Usage After Install
### start service
on Mac OS
```bash
catalina stop
catalina start
```
on Linux
```bash
sudo ./daemon stop
sudo ./daemon start
```

### create index
```bash
# make index of source (multiple index)
sudo ./OpenGrok index [/opt/o-source]
                       /opt/source   -- proj1
                                     -- proj2
                                     -- proj3

---------------------------------------- SUMMARY ----
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

## Auto Update Repository - Tool
### Update Tool
Only support git repository

```bash
# Go into your OPENGROK_SRC_ROOT
pwd
/opt/o-source

ls
coreutils-8.21      dpdk-stable-17.11.2 glibc-2.7           libconhash
dpdk-stable-17.05.2 dpvs                keepalived          nginx
```
revise in [update.sh](./update.sh)
```bash
updateDir=(
    "dpvs"
    "keepalived"
    "Add Repo Name according to upper dir name"
)
```

### Cron Tool
revise in [addCron.sh](./addCron.sh), chage the time as you wish
```bash
cat << _EOF > $crontabFile
04 11 * * * $updateShellPath &> $logFile
_EOF
```
Execute the cron shell
```bash
sh addCron.sh
```

## Notice
If you use EZ-Zoom on Chrome with OpenGrok, make sure it's 100% or OpenGrok will jump to the wrong line

## License
The [MIT](./LICENSE.txt) License (MIT)
