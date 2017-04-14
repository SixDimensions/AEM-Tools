#!/bin/bash
# creates packages, and adds filters based on a text file.

#config
HOST=""
# only configure if you plan to migrate content between two instances.
TARGET_HOST=""
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
  echo "-t       If set to a host string such as http://localhost:4502, it will upload and install package on that host."
  echo "-h       Use to specify host name of machine to build package from."
  echo -e "-H       displays this help and then exits"\\n
  echo -e "Example: ./packbuldr.sh -p myuserpassword -n my_new_package -h http://localhost:4502 -t 'http://localhost:5502 http://localhost:5503' -f myNewFilters.txt"
  exit
}

function createPackage {
  # create package
  #echo "creating package ${PACKAGE_NAME}..."
  curl -u ${USER}:${PASS} -X POST ${HOST}/crx/packmgr/service/.json/etc/packages/${GROUP_NAME}/${PACKAGE_NAME}?cmd=create -d packageName=${PACKAGE_NAME} -d groupName=${GROUP_NAME}
}

function addPackageFilters {
  # add filters
  echo -e "\n"
  ROOTPATH=
  while IFS= read -r LINE
  do
    if [ ${LINE} != "#"* ]; then
          path='{"root":"'${LINE}'","rules":[]}'
          if [ -z "${ROOTPATH}" ]; then
            ROOTPATH=${path}
          else
            ROOTPATH=${ROOTPATH},${path}
          fi
    fi
  done < "${FILTERS}"
  curl -u ${USER}:${PASS} -X POST ${HOST}/crx/packmgr/update.jsp -F path=/etc/packages/${GROUP_NAME}/${PACKAGE_NAME}.zip -F packageName=${PACKAGE_NAME} -F groupName=${GROUP_NAME} -F 'filter=['$ROOTPATH']' -F '_charset_=UTF-8'
}
# build package
function buildPackage {
  #echo "building package ${PACKAGE_NAME}... "
  echo -e "\n"
  curl -u ${USER}:${PASS} -X POST ${HOST}/crx/packmgr/service/exec.json/etc/packages/${GROUP_NAME}/${PACKAGE_NAME}.zip?cmd=build
}
function downloadPackage {
  echo -e "\n"
  curl -u ${USER}:${PASS} -X POST -F path="/etc/packages/${GROUP_NAME}/${PACKAGE_NAME}.zip" -F _charset_="=utf-8" ${HOST}/crx/packmgr/download.jsp > ${PACKAGE_NAME}.zip
}
function uploadPackage {
  echo -e "\n"
  for HOST in $TARGET_HOST
  do
      curl -u ${USER}:${PASS} -F file=@"${PACKAGE_NAME}.zip" -F name="${PACKAGE_NAME}" -F force=true -F install=true ${HOST}/crx/packmgr/service.jsp
  done
}
while getopts ":p:n:f:m:h:t:H:" arg; do
    case "${arg}" in
      p)
          PASS=$OPTARG
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
      h)
          HOST=$OPTARG
          ;;
      t)
          TARGET_HOST=$OPTARG
          ;;
      H)
          usage
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
  if [ -n "${TARGET_HOST}" ]; then
    uploadPackage
  fi
  exit 0
