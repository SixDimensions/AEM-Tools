#!/bin/bash
function usage {
  echo -e \\n"Usage: run-compact.sh [OPTION]"\\n
  echo "Mandatory arguments to long options are mandatory for short options too."
  echo "-d       Path to repository to compact"
  echo "-v       The version of oak-compact.jar to use."
  echo "-m       The mode of cleanup, this can currently be rm-unreferenced or rm-all"
  echo "-b       Set to true to backup the repository before compacting, backup will occur in same directory as repo."
  echo "-s       Specify Xms memory requirement for JVM."
  echo "-x       Specify Xmx memory requirement for JVM."
  echo -e "-H       displays this help and then exits"\\n
  echo -e "Example: run-compact.sh -d /opt/aem/crx-quickstart/repository/segmentstore -v 1.0.8 -m rm-all"
  exit
}

function compact {
  if [ aem_not_running ]; then
    if [ ! -f oak_run_jars/oak-run-${1}.jar ];
      then
       echo "Could not find valid oak run jar in the oak_run_jars directory."
       exit 1
    fi
    if [ ! -d "$2" ];
      then
        echo "Could not find directory for the repository."
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
            java -jar oak_run_jars/oak-run-$VERSION.jar backup "${repoDir}" ${repoDir}_bak
        fi
      fi
      ## check if they supplied memory args
      if [ -n "$5" ];
        then
          XMX="-Xmx$5"
      fi
      if [ -n "$6" ];
        then
         XMS="-Xms$6"
      fi 
      VERSION=$1
      repoDir=$2
      # check for non-needed checkpoints
      echo -e "Using oak-run-${VERSION}.jar...\n"
      echo -e "Checking for checkpoints at $repoDir...\n"
      echo "java $XMX $XMS -jar oak_run_jars/oak-run-${VERSION}.jar checkpoints ${repoDir}"
      java $XMX $XMS -jar oak_run_jars/oak-run-${VERSION}.jar checkpoints "${repoDir}"
      # rm the checkpoints
      echo -e "Removing unreferenced checkpoints at $repoDir...\n"
      java $XMX $XMS -jar oak_run_jars/oak-run-${VERSION}.jar checkpoints "${repoDir}" ${MODE}
      #compact
      echo -e "Compacting segmentstore at $repoDir...\n"
      java $XMX $XMS -jar oak_run_jars/oak-run-${VERSION}.jar compact "${repoDir}"
      echo -e "Done!\n"
      exit 0
    fi
}
# function that gets called to getopts and check them.
function init {
  logDate=`date +"%h %d %Y %r"`
  echo -e "${logDate} [INFO] Starting offline oak compaction..."
  while getopts ":d:H:v:m:b:p:x:s:" arg; do
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
      s)
          xms=$OPTARG
          ;;
      x)
          xmx=$OPTARG
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
  echo -e "${logDate} [INFO] Compacting ${repoDir} with jar version ${version}..."

 compact $version $repoDir $mode $backup $xmx $xms

 exit 0
}
init $@ #call to init function
