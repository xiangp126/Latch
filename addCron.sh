#!/bin/bash
# From which path it was executed
startDir=`pwd`
# Absolute path of this shell, no impact by start dir
mainWd=$(cd $(dirname $0); pwd)
execPrefix=sudo

updateShellPath=$mainWd/update.sh
if [[ ! -f $updateShellPath ]]; then
    echo "[Error]: Not found update shell, pls check"
    exit 255
fi

# For details see man 4 crontabs

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed

# Example
# 50 9 * * * $updateShellPath &> $mainWd/crontab.log
# 04 20 * * * $updateShellPath &> $mainWd/crontab.log

# Generate crontab file
crontabFile=$mainWd/crontab.txt
cat << _EOF > $crontabFile
04 20 * * * $updateShellPath &> $mainWd/crontab.log
_EOF

# Add into cron
crontab $crontabFile
crontab -l
