#!/bin/bash
# From which path it was executed

# Open Debug
set -x

startDir=`pwd`
# Absolute path of this shell, no impact by start dir
mainWd=$(cd $(dirname $0); pwd)
execPrefix=sudo

PATH=$HOME/.usr/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin
dynamicEnvPath=$mainWd/dynamic.env
source $dynamicEnvPath

updateDir=(
    "dpvs"
)

cd $OPENGROK_SRC_ROOT
for repo in ${updateDir[@]}; do
    cd $repo
    $execPrefix git pull
    cd - &> /dev/null
done

# Update OpenGrok index
$execPrefix $OPENGROK_BIN_PATH index
