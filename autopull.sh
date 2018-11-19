#!/bin/bash
set -x
startDir=`pwd`
# absolute path of this shell, not influenced by start dir
mainWd=$(cd $(dirname $0); pwd)
loggingPath=$mainWd/log
# empty or root
execPrefix=""

PATH=$HOME/.usr/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
dynamicEnvPath=$mainWd/dynamic.env
source $dynamicEnvPath

updateDir=(
    "dpvs"
    "nginx"
    "keepalived"
)

cd $OPENGROK_SRC_ROOT
for repo in ${updateDir[@]}; do
    if [[ ! -d $repo ]]; then
        exit
    fi
    cd $repo
    $execPrefix git pull
    cd - &> /dev/null
done

# Update OpenGrok index
if [[ ! -d $loggingPath ]]; then
    mkdir -p $loggingPath
fi

# call indexer
cd $mainWd
./callIndexer
