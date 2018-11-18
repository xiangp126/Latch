### Illustrate
- This project aims to deploy _**OpenGrok**_ easy and eased
- Imcremental installation and subsequential handling all in one
- Using **python** tools(~~legacy bash~~) to deploy and generate index along with `OpenGrok`'s update
- Provide serveral handy scripts and packages

Package | Version | Repo | Comment
:---: |:---: | :---: | ---
Universal ctags | latest | [Universal-Ctags](https://github.com/universal-ctags/ctags) | source compile
Java | 8u172 | [Jdk-Splits](./packages/jdk-splits) | private [split and cat](https://github.com/xiangp126/split-and-cat)
Tomcat | 8.5.31 | [Packages](./packages) | local binary
OpenGrok | 1.1-rc74 | [OpenGrok](https://github.com/oracle/opengrok) | official binary
- Take my [Giggle](http://giggle.ddns.net:8080/source) as example and refer [Guide](./gif/guide.gif) 
- Support `Mac` since tag `v2.9`

> Latest released version: 3.0

### Lazy Deploy
#### clone `latch`
```bash
git clone https://github.com/xiangp126/Latch
```

#### help message
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

#### set up source code

_put your source code into `OPENGROK_SRC_ROOT`, **per code per directory**_

#### start to install
```bash
sh oneKey.sh install
```

#### browser site
> `indexer` was called in `oneKey`, you can also run `callIndexer` manually<br>
> take you server address as `127.0.0.1` for example<br>

_then browser your `http://127.0.0.1:8080/source`_

### Handle Web Service
#### mac
```bash
catalina stop
catalina start
```

#### linux
```bash
# repo main directory
sudo ./daemon stop
sudo ./daemon start
```

### Create Index Manually

_refer [Python-scripts-transition-guide](https://github.com/oracle/opengrok/wiki/Python-scripts-transition-guide)_

#### python tools - new method
```bash
# repo main directory
./callIndexer
```

#### bash script - lagacy method
```bash
# make index of source (multiple index)
./OpenGrok index [/opt/o-source]
                  /opt/source   -- proj1
                                -- proj2
                                -- proj3
```

### Introduction to Handy tools
#### auto pull
_only support `Git` repository, auto re-indexing_

```bash
# Go into your OPENGROK_SRC_ROOT
pwd
/opt/o-source

ls
coreutils-8.21      dpdk-stable-17.11.2 glibc-2.7           libconhash
dpdk-stable-17.05.2 dpvs                keepalived          nginx
```

_add or remove item in *`updateDir`* of [autopull.sh](./autopull.sh)_

```bash
updateDir=(
    "dpvs"
    "keepalived"
    "Add Repo Name according to upper dir name"
)
```

_execute it_

```bash
sh autopull.sh
```

#### auto rsync
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

#### cron tool
_chage the time as you wish in [addcron.sh](./addcron.sh)_

```bash
# Generate crontab file
cat << _EOF > $crontabFile
04 20 * * * $updateShellPath &> $logFile
_EOF
```

_and change *`updateShellPath`* as the shell needs auto executed by cron as you wish, default is `autopull.sh`_

```bash
updateShellPath=$mainWd/autopull.sh
```

_execute it_

```bash
sh addcron.sh
```

### Notice
    If you use EZ-Zoom on Chrome with OpenGrok, make sure it's 100% or OpenGrok will jump to the wrong line

### License
The [MIT](./LICENSE.txt) License (MIT)
