#
# Return (echo) the base path to developers source repositorys
function get_code_path {
  EDUID_SRC_PATH=${EDUID_SRC_PATH-'~/work/NORDUnet'}
  echo "`eval echo ${EDUID_SRC_PATH//>}`"  # handle '>' in EDUID_SRC_PATH
}

#
# Figure out suitable 'docker run' parameters to volume-mount in any present
# source code for this container, and an according PYTHONPATH to the volumes
function get_developer_params {
    host_src_path="$(echo $(get_code_path))"
    guest_src_path="/opt/eduid/src"

    src_volumes=""
    pp=""

    for name in $*; do
	srcdir="${host_src_path}/${name}"
	if [ -d "${srcdir}" ]; then
	    if [ -d "${srcdir}/src" ]; then
		# Some packages, like eduid-IdP, has the Python package in a src/ dir
		srcdir+="/src"
	    fi
            # map developers local source copy into /opt/eduid/src and set PYTHONPATH accordingly
	    src_volumes+=" -v ${srcdir}:${guest_src_path}/${name}"
	    if [ "x${pp}" = "x" ]; then
		pp="--env=PYTHONPATH=${guest_src_path}/${name}"
	    else
		pp+=":${guest_src_path}/${name}"
	    fi
	fi
    done

    echo "${src_volumes} ${pp}"
}

function docker0_ipaddress {
    ifconfig docker0 | grep "inet addr:" | awk '{print $2}' | awk -F : '{print $2}'
}
