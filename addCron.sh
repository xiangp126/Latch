#!/bin/bash
# From which path it was executed
startDir=`pwd`
# Absolute path of this shell, no impact by start dir
mainWd=$(cd $(dirname $0); pwd)
execPrefix=sudo

currentShellPath=$mainWd/update.sh
if [[ ! -f $currentShellPath ]]; then
    echo "[Error]: Not found update shell, pls check"
    exit 255
fi
# Generate crontab file
crontabFile=$mainWd/crontab.txt
# 50 9 * * * $currentShellPath &> $mainWd/crontab.log
# 04 20 * * * $currentShellPath &> $mainWd/crontab.log
cat << _EOF > $crontabFile
04 20 * * * $currentShellPath &> $mainWd/crontab.log
_EOF

# Add into cron
crontab $crontabFile
crontab -l
