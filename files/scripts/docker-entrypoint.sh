#!/bin/bash
set -e

# set or append a config value in a file
function setConfigValue {
        configFile=${1}
        configName=${2}
        configValue=${3}
        configDelim=${4}

        if grep -q '^[ 	]*'${configName} ${configFile}; then
		# escape value for sed
		configValue=$(echo ${configValue} | sed -e 's/[\/&]/\\&/g')
		regex='s/^\([ \t]*'${configName}'[ \t]*'${configDelim/[ \t]*/}'[ \t]*\).*/\1'${configValue}'/'
                sed -i ${configFile} -e "${regex}" || (echo "  regex: ${regex}"; false)
        else
                if [ "${configDelim}" = "" ]; then
                        configDelim=" "
                fi
                echo "${configName}${configDelim}${configValue}" >>${configFile}
        fi

}

SCRIPT_DIR=$(dir=$(dirname ${0}); cd ${dir}; pwd)

# set this variable to skip the entrypoint for debugging and execute directly the command
if [ -z "${ENTRYPOINT_SKIP}" ]; then

	# determine if this is running first time to initialize some stuff only once
	if [ -f ${SCRIPT_DIR}/entrypoint.initialized ]; then
		ENTRYPOINT_INITIALIZED=true
	else
		ENTRYPOINT_INITIALIZED=false
	fi

	echo "Executing $BASH_SOURCE"

	# define ssl directory for services
	SSL_DIR="/etc/ssl/$(hostname --fqdn)"

	if [ ${ENTRYPOINT_IS_COMMAND}=true ]; then
		# set initialized for next execution
		touch ${SCRIPT_DIR}/entrypoint.initialized
	
		# create ssl directory if not exists
		if [ ! -d ${SSL_DIR} ]; then
			mkdir -p ${SSL_DIR}
		fi

	fi

	# executing service entrypoint scripts
	for script in $(find ${SCRIPT_DIR}/ -maxdepth 1 -regex '.*/docker-entrypoint[^/]+\.sh' | sort); do
        	. $script $@
	done

fi

# unset configuration environment variables
for varName in $(env | grep -E "^CONF_" | cut -d"=" -f1); do
	unset ${varName}
done

echo "Starting Command"
exec $@

