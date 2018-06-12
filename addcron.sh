#!/bin/bash
# From which path it was executed
startDir=`pwd`
# Absolute path of this shell, no impact by start dir
mainWd=$(cd $(dirname $0); pwd)
logDir=$mainWd/log
logFile=$logDir/crontab.log
crontabFile=$mainWd/crontab.txt
updateShellPath=$mainWd/autopull.sh
# updateShellPath=$mainWd/rsync.sh
execPrefix=sudo

if [[ ! -f $updateShellPath ]]; then
    echo "[Error]: Not found auto pull shell, pls check"
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
# 04 11 * * * $updateShellPath &> $logFile
# 04 20 * * * $updateShellPath &> $logFile

# Create log directory if not exist
if [[ ! -d $logDir ]]; then
    mkdir -p $logDir
fi
# Generate crontab file
cat << _EOF > $crontabFile
04 20 * * * $updateShellPath &> $logFile
_EOF

# Add into cron
crontab $crontabFile
crontab -l
