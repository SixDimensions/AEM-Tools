#!/bin/bash
# creates packages, and adds filters based on a text file.

#config
HOST=""
PORT="4502"
# only configure if you plan to migrate content between two instances.
TARGET_HOST=""
TARGET_PORT=""
GROUP_NAME=""
PACKAGE_NAME=""
USER="admin"
FILTERS='filters.txt'
function usage {
  echo -e \\n"Usage: packbuldr.sh [OPTION]"\\n
  echo "Mandatory arguments to long options are mandatory for short options too."
  echo "-p       Password for configured user."
  echo "-n       The package name to use."
  echo "-f       Filter file to use."
  echo "-m       If set to 'true', script will upload built package to another AEM instance and install."
  echo -e "-H       displays this help and then exits"\\n
  echo -e "Example: packbuldr.sh -p myuserpassword -n my_new_package"
  exit
}

function createPackage {
  # create package
  #echo "creating package ${PACKAGE_NAME}..."
  curl -u ${USER}:${PASS} -X POST ${HOST}:${PORT}/crx/packmgr/service/.json/etc/packages/${GROUP_NAME}/${PACKAGE_NAME}?cmd=create -d packageName=${PACKAGE_NAME} -d groupName=${GROUP_NAME}
}

function addPackageFilters {
  # add filters
  #echo "adding filters..."
  echo -e "\n"
  ROOTPATH=
  while IFS= read -r LINE
  do
          path='{"root":"'${LINE}'","rules":[]}'
          if [ -z "${ROOTPATH}" ]; then
            ROOTPATH=${path}
          else
            ROOTPATH=${ROOTPATH},${path}
          fi
  done < "${FILTERS}"
  curl -u ${USER}:${PASS} -X POST ${HOST}:${PORT}/crx/packmgr/update.jsp -F path=/etc/packages/${GROUP_NAME}/${PACKAGE_NAME}.zip -F packageName=${PACKAGE_NAME} -F groupName=${GROUP_NAME} -F 'filter=['$ROOTPATH']' -F '_charset_=UTF-8'
}
# build package
function buildPackage {
  #echo "building package ${PACKAGE_NAME}... "
  echo -e "\n"
  curl -u ${USER}:${PASS} -X POST ${HOST}:${PORT}/crx/packmgr/service/exec.json/etc/packages/${GROUP_NAME}/${PACKAGE_NAME}.zip?cmd=build
}
function downloadPackage {
  echo -e "\n"
  curl -u ${USER}:${PASS} ${HOST}:${PORT}/etc/packages/${GROUP_NAME}/${PACKAGE_NAME}.zip > ${PACKAGE_NAME}.zip
}
function uploadPackage {
  echo -e "\n"
  curl -u ${USER}:${PASS} -F file=@"${PACKAGE_NAME}.zip" -F name="${PACKAGE_NAME}" -F force=true -F install=true ${TARGET_HOST}:${TARGET_PORT}/crx/packmgr/service.jsp
}
# function that gets called to getopts and check them.
function init {
  while getopts ":p:n:f:m:H:" arg; do
    case "${arg}" in
      p)
          PASS=$OPTARG
          ;;
      H)
          usage
          ;;
      n)
          PACKAGE_NAME=$OPTARG
          ;;
      f)
          FILTERS=$OPTARG
          ;;
      m)
          MIGRATE=$OPTARG
          ;;
      *)
         usage
        ;;
    esac
  done
  shift $((OPTIND-1))
  if [ -z "${PASS}" ] || [ -z "${PACKAGE_NAME}" ]; then
    echo "It appears you did not specify all required arguments!"
    usage
  fi
  createPackage
  addPackageFilters
  buildPackage
  downloadPackage
  if [ "${MIGRATE}" == "true" ]; then
    uploadPackage
  fi
  exit 0
}
init $@ #call to init function
