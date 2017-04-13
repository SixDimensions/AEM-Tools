#!/bin/bash
function usage {
  echo -e \\n"Usage: run-compact.sh [OPTION]"\\n
  echo "Mandatory arguments to long options are mandatory for short options too."
  echo "-d       Path to repository to compact"
  echo "-v       The version of oak-compact.jar to use."
  echo "-m       The mode of cleanup, this can currently be rm-unreferenced or rm-all"
  echo "-b       Set to true to backup the repository before compacting, backup will occur in same directory as repo."
  echo "-j       Specify additional JVM options for oak run jar (such as memory requirements)"
  echo "-p       Specify the crx-quickstart location for locating the pid file."
  echo "-i       Instance Type, can be publish to use configured start/stop scripts for a publish instance (must configure)"
  echo -e "-H       displays this help and then exits"\\n
  echo -e "Example: run-compact.sh -d /opt/aem/crx-quickstart/repository/segmentstore -v 1.0.8 -m rm-all"
  exit
}
# script configurations
##the start and stop need to be configured for the modes you plan to run this with (-i).
START='/etc/init.d/aem-author start'
STOP='/etc/init.d/aem-author stop'
ITYPE='' #blank for author, this is for internal error reporting.
OAK_JARS_LOCATION="/home/aem"
COMPACTION_USER="aem"
SLEEPTIME='120s'
TIMEOUT=5
# email notification configuration
HOST=""
TO="myemail@email.com"

#functions
function sendAlertEmail {
  echo "Subject: Offline Compaction failed on ${HOST}\nOffline compaction failed on ${HOST} for reason: ${1}\n" | /usr/sbin/sendmail ${TO}
}
function validateAEMStart {
    COUNT=1
    PID=`cat $1/conf/cq.pid`
    echo `date +"%h %d %Y %r"`" [INFO] Attempting to start AEM with PID of $PID"
    while [ -z "`ps aux | grep 'java' | head -n -1 | grep ${PID}`" ]; do
      if [ ${COUNT} -ge ${TIMEOUT} ]; then
        echo `date +"%h %d %Y %r"`" [WARN] Instance failed to start, could not find PID of ${PID}."
        REASON="${ITYPE}Instance failed to start, could not find PID of ${PID}."
        #sendAlertEmail ${REASON}
        exit 1
      fi
      echo `date +"%h %d %Y %r"`" [INFO] Instance not started completely, sleeping for $SLEEPTIME, check number ${COUNT}"
      sleep ${SLEEPTIME}
      ((COUNT++))
    done
    echo `date +"%h %d %Y %r"`" [INFO] Instance appears to have started, found PID of ${PID}."
}
function stopAEM {
  COUNT=1
  PID=`cat $1/conf/cq.pid`
  echo `date +"%h %d %Y %r"`" [INFO] Attempting to stop AEM with PID of $PID"
  $STOP
  while [ -n "`ps aux | grep 'java' | head -n -1 | grep ${PID}`" ]; do
    if [ ${COUNT} -ge ${TIMEOUT} ]; then
      echo `date +"%h %d %Y %r"`" [WARN] Instance failed to stop...aborting compaction."
      REASON="${ITYPE}Instance failed to stop after trying ${COUNT} times and waiting ${SLEEPTIME} each time."
      #sendAlertEmail ${REASON}
      exit 1
    fi
    echo `date +"%h %d %Y %r"`" [INFO] Instance not stopped completely, sleeping for $SLEEPTIME, check number ${COUNT}"
    sleep ${SLEEPTIME}
    ((COUNT++))
  done
}
function compact {

    if [ ! -f ${OAK_JARS_LOCATION}/oak_run_jars/oak-run-${1}.jar ];
      then
       echo `date +"%h %d %Y %r"`" [INFO] Could not find valid oak run jar in the oak_run_jars directory."
       exit 1
    fi
    if [ ! -d "$2" ];
      then
        echo `date +"%h %d %Y %r"`" [INFO] Could not find directory for the repository."
        exit 1
      fi
      if [ -z "$3" ];
          then
            #they didn't supply a mode, run rm-unreferenced
            MODE='rm-unreferenced'
          else
            MODE="$3"
      fi
      ## check if they want to backup
      if [ -n "$4" ];
        then
        if [ "$4" = 'true' ];
          then
            java ${javaOpts} -jar ${OAK_JARS_LOCATION}/oak_run_jars/oak-run-$VERSION.jar backup "${repoDir}" ${repoDir}_bak
        fi
      fi
      if [ -n "$pidFile" ];
        then
          stopAEM $pidFile
      fi

      VERSION=$1
      repoDir=$2
      echo "Switching user to ${COMPACTION_USER}"

      # check for non-needed checkpoints
      echo -e `date +"%h %d %Y %r"`" [INFO] Using oak-run-${VERSION}.jar...\n"
      echo -e `date +"%h %d %Y %r"`" [INFO] Checking for checkpoints at $repoDir...\n"
      su -c "java ${javaOpts} -jar ${OAK_JARS_LOCATION}/oak_run_jars/oak-run-${VERSION}.jar checkpoints "${repoDir}"" - ${COMPACTION_USER}
      # rm the checkpoints
      echo -e `date +"%h %d %Y %r"`" [INFO] ${MODE} checkpoints at $repoDir...\n"
      su -c "java ${javaOpts} -jar ${OAK_JARS_LOCATION}/oak_run_jars/oak-run-${VERSION}.jar checkpoints "${repoDir}" ${MODE}" - ${COMPACTION_USER}
      #compact
      echo -e `date +"%h %d %Y %r"`" [INFO] Compacting segmentstore at $repoDir...\n"
      su -c "java ${javaOpts} -jar ${OAK_JARS_LOCATION}/oak_run_jars/oak-run-${VERSION}.jar compact "${repoDir}"" - ${COMPACTION_USER}
      echo -e `date +"%h %d %Y %r"`" [INFO] Done!\n"
      if [ -n "$pidFile" ];
        then
         echo "Starting AEM..."
         $START
         validateAEMStart $pidFile
      fi
      exit 0
}
# function that gets called to getopts and check them.
function init {
  echo -e `date +"%h %d %Y %r"`" [INFO] Starting offline oak compaction..."
  while getopts ":d:H:v:m:b:p:j:i:" arg; do
    case "${arg}" in
      d)
          repoDir=$OPTARG
          ;;
      H)
          usage
          ;;
      v)
          version=$OPTARG
          ;;
      m)
          mode=$OPTARG
          ;;
      b)
          backup=$OPTARG
          ;;
      p)
          pidFile=$OPTARG
          ;;
      j)
          javaOpts=$OPTARG
          ;;
      i)
          instance=$OPTARG
          ;;
     *)
         usage
        ;;
    esac
  done
  shift $((OPTIND-1))
  if [ -z "${version}" ] || [ -z "${repoDir}" ]; then
    echo "It appears you did not specify all required arguments!"
    usage
  fi
  echo -e `date +"%h %d %Y %r"`" [INFO] Compacting ${repoDir} with jar version ${version}..."
  if [ "${instance}" == "publish" ]; then
    ITYPE='Publish '
    START='/etc/init.d/aem-publish start'
    STOP='/etc/init.d/aem-publish stop'
  fi
  compact $version $repoDir $mode $backup $javaOpts

 exit 0
}
init $@ #call to init function
