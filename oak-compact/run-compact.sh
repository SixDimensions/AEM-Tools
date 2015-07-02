#!/bin/bash
function usage {
  echo -e \\n"Usage: run-compact.sh [OPTION]"\\n
  echo "Mandatory arguments to long options are mandatory for short options too."
  echo "-d       Path to repository to compact"
 echo "-v       The version of oak-compact.jar to use."
  echo -e "-H       displays this help and then exits"\\n
  echo -e "Example: run-compact.sh -d /opt/aem/crx-quickstart/repository/segmentstore -v 1.0.8"
  exit 
}
function compact {
    if [ -f "oak_run_jars/oak-run-$1.jar" ];
    	then
        echo "You did not supply a version found in oak_run_jars directory.\n Please download the appropriate version and place inside the oak_run_jars directory."
    fi
    if [ -d "$2" ];
    then
    #java -jar oak_run_jars/oak-run-$VERSION.jar backup "$DIR" $DIR_bak
    # check for non-needed checkpoints
    echo -e "Using oak-run-$VERSION.jar...\n"
    echo -e "Checking for checkpoints at $repoDir...\n"
    java -jar oak_run_jars/oak-run-$version.jar checkpoints "$repoDir"
    # rm the checkpoints
    echo -e "Removing unreferenced checkpoints at $repoDir...\n"
    java -jar oak_run_jars/oak-run-$version.jar checkpoints "$repoDir" rm-unreferenced
    #compact
    echo -e "Compacting segmentstore at $repoDir...\n"
    java -jar oak_run_jars/oak-run-$version.jar compact "$repoDir"
    echo -e "Done!\n"
    exit 0
    else 
        echo "You did not supply a valid directory...exiting..."
        exit 1
    fi
}
# function that gets called to getopts and check them.
function init {
  #logDate=`date +"%h %d %Y %r"`
  echo -e "${logDate} [INFO] Starting offline oak compaction..." >> $logFile
  while getopts ":d:H:v:" arg; do
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
  echo -e "${logDate} [INFO] Compacting ${repoDir} with jar version ${version}..." >> $logFile
 # fetch what is on remote server, compress it to make it faster.
 compact $version $repoDir
 # sync it with the local resources directory
 exit 0
}
init $@ #call to init function