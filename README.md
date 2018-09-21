### Illustrate
- This project aims to deploy **OpenGrok** on Unix-like by one-click command
- Imcremental install and subsequent handling all in one
- May install for Linux

Package | From | Version | Method | Comment
:---:|---|:---: | --- | ---
Universal ctags | Github | latest | Source Compile
Java | Official | 8u172 | Binary Dwonload | [split and cat](https://github.com/xiangp126/split-and-cat) pack into [jdk-splits](./packages/jdk-splits)
Tomcat | Official | 8.5.31 | Binary Dwonload | pack into [packages](./packages)
OpenGrok | Github | 1.1-rc33 | Binary Dwonload
- Support *Mac OS* since `tag 2.9`

> Latest released version: 3.0

### Quick Start
```bash
git clone https://github.com/xiangp126/Latch
```
```bash
sh oneKey.sh

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
sh oneKey.sh install
```
> Take you server address as 127.0.0.1 for example<br>
> Put your source code into `OPENGROK_SRC_ROOT` as per directory

```bash
./OpenGrok index
```
Then browser <http://127.0.0.1:8080/source>

### Handle Service
- on Mac OS

```bash
catalina stop
catalina start
```
- on Linux

```bash
sudo ./daemon stop
sudo ./daemon start
```

### Create Index
```
# make index of source (multiple index)
./OpenGrok index [/opt/o-source]
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

### Handy tools - Auto Pull
Only support git repository, auto re-indexing

```bash
# Go into your OPENGROK_SRC_ROOT
pwd
/opt/o-source

ls
coreutils-8.21      dpdk-stable-17.11.2 glibc-2.7           libconhash
dpdk-stable-17.05.2 dpvs                keepalived          nginx
```
Add or remove item in *`updateDir`* of [autopull.sh](./autopull.sh)

```bash
updateDir=(
    "dpvs"
    "keepalived"
    "Add Repo Name according to upper dir name"
)
```

Execute it

```bash
sh autopull.sh
```

### Handy tools - Auto Rsync
```bash
cat template/rsync.config
# config server info | rsync from
SSHPORT=
SSHUSER=
SERVER=
SRCDIR_ON_SERVER=

cp ./template/rsync.config .
vim rsync.config
# fix the information as instructed
```

```bash
sh rsync.sh
```

### Handy tools - Cron Tool
Chage the time as you wish in [addcron.sh](./addcron.sh)

```bash
# Generate crontab file
cat << _EOF > $crontabFile
04 20 * * * $updateShellPath &> $logFile
_EOF
```

And change *`updateShellPath`* as the shell needs auto executed by cron as you wish, default is autopull.sh

```bash
updateShellPath=$mainWd/autopull.sh
```

Execute it

```bash
sh addcron.sh
```

### Notice
    If you use EZ-Zoom on Chrome with OpenGrok, make sure it's 100% or OpenGrok will jump to the wrong line

### License
The [MIT](./LICENSE.txt) License (MIT)
