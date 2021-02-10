#!/bin/bash

# define global vars
pystub_basedir=~/pystub
pystub_repo=https://github.com/dwrightco1/pystub.git
pip_url=https://bootstrap.pypa.io/get-pip.py
pip_path=/tmp/get_pip.py
pystub_venv=~/.pystub/venv
venv_activate=${pystub_venv}/bin/activate
init_flag=0
logging=1
log_file=~/pystub.log
python3_flag=0
os_platform=""
os_version=""

# functions
assert() {
    if [ $# -gt 0 ]; then echo "ASSERT: $(basename $0) : ${1}"; fi
    exit 1
}

usage() {
    echo "Usage: $(basename $0)"
    echo "	  [-i|--init]"
    echo "	  [-v|--verbose]"
    echo ""
    exit 0
}

get_os_platform() {
  if [ -r /etc/centos-release ]; then
    os_platform="centos"
    os_version=$(cat /etc/centos-release | cut -d ' ' -f 4)
    if [[ ! "${os_version}" == 7.* ]]; then assert "unsupported CentOS release: ${os_version}"; fi
  elif [ -r /etc/lsb-release ]; then
    os_platform="ubuntu"
    os_version=$(cat /etc/lsb-release | grep ^DISTRIB_RELEASE | cut -d = -f2)
    if [[ ! "${os_version}" == 18.* ]]; then assert "unsupported Ubuntu release: ${os_version}"; fi
  elif [ "$(uname)" == "Darwin" ]; then
    os_platform="macos"
    os_version=$(sw_vers | grep ^ProductVersion | awk -F : '{print $2}' | awk -F ' ' '{print $1}')
    if [[ ! "${os_version}" == 10.* ]]; then assert "unsupported MacOS release: ${os_version}"; fi
  else
    echo "ERROR: unsupported platform (only Ubuntu and CentOS are supported)"
    exit 1
  fi
}

install_virtualenv() {
    echo "Initializing Virtual Environment using Python ${python_version}"

    if [[ ${python_version} == 2 ]]; then
        pyver="";
    else
        pyver="3";
    fi

    # Validate and initialize virtualenv
    if [ "$(virtualenv --version -p python${pyver} > /dev/null 2>&1; echo $?)" -ne 0 ]; then
        # Validating pip
        which pip > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "--> Installing Pip"
            case ${os_platform} in
            ubuntu)
                if [ ${logging} -eq 1 ]; then
                    apt install -y python${pyver}-pip >> ${log_file} 2>&1
                else
                    apt install -y python${pyver}-pip
                fi
                if [ $? -ne 0 ]; then
                    if [ ${logging} -eq 1 ]; then
                        sudo apt install -y python${pyver}-pip >> ${log_file} 2>&1
                    else
                        sudo apt install -y python${pyver}-pip
                    fi
                    if [ $? -ne 0 ]; then
                        assert "Failed to install Python package: pip"
                    fi
                fi
                ;;
            centos|macos)
                if [ ${logging} -eq 1 ]; then
                    curl -s -o ${pip_path} ${pip_url} >> ${log_file} 2>&1
                else
                    curl -s -o ${pip_path} ${pip_url}
                fi
                if [ ! -r ${pip_path} ]; then assert "failed to download get-pip.py (from ${pip_url})"; fi

                if [ ${logging} -eq 1 ]; then
                    python${pyver} ${pip_path} >> ${log_file} 2>&1
                else
                    python${pyver} ${pip_path}
                fi
                if [ $? -ne 0 ]; then
                    if [ ${logging} -eq 1 ]; then
                        sudo python${pyver} ${pip_path} >> ${log_file} 2>&1
                    else
                        sudo python${pyver} ${pip_path}
                    fi
                    if [ $? -ne 0 ]; then
                        assert "Failed to install Python package: pip"
                    fi
                fi
                ;;
            *)
                ;;
            esac
        fi

        # Attemping to Install virtualenv
        echo "--> Installing python package: virtualenv"

        case ${os_platform} in
        ubuntu)
            if [ ${logging} -eq 1 ]; then
                apt install -y python${pyver}-venv >> ${log_file} 2>&1
            else
                apt install -y python${pyver}-venv
            fi
            if [ $? -ne 0 ]; then
                if [ ${logging} -eq 1 ]; then
                    sudo apt install -y python${pyver}-venv >> ${log_file} 2>&1
                else
                    sudo apt install -y python${pyver}-venv
                fi
                if [ $? -ne 0 ]; then
                    assert "Failed to install Python package: virtualenv"
                fi
            fi
            ;;
        centos|macos)
            if [ ${logging} -eq 1 ]; then
                pip${pyver} install virtualenv >> ${log_file} 2>&1
            else
                pip${pyver} install virtualenv
            fi
            if [ $? -ne 0 ]; then
                if [ ${logging} -eq 1 ]; then
                    sudo pip${pyver} install virtualenv >> ${log_file} 2>&1
                else
                    sudo pip${pyver} install virtualenv
                fi
                if [ $? -ne 0 ]; then
                    assert "Failed to install Python package: virtualenv"
                fi
            fi
            ;;
        *)
            ;;
        esac
    fi

    echo "--> Starting virtual environment (located in ${pystub_venv})"
    case ${os_platform} in
    ubuntu)
        if [ ${logging} -eq 1 ]; then
            python${pyver} -m venv ${pystub_venv} >> ${log_file} 2>&1
        else
            python${pyver} -m venv ${pystub_venv}
        fi
        if [ ! -r ${venv_activate} ]; then assert "failed to initialize virtual environment"; fi
        ;;
    centos|macos)
        if [ ${logging} -eq 1 ]; then
            virtualenv -p python${pyver} ${pystub_venv} >> ${log_file} 2>&1
        else
            virtualenv -p python${pyver} ${pystub_venv}
        fi
        if [ ! -r ${venv_activate} ]; then assert "failed to initialize virtual environment"; fi
        ;;
    *)
        ;;
    esac

    echo "--> Upgrading Pip"
    # upgrade pip
    (. ${venv_activate} && pip install pip --upgrade > /dev/null 2>&1)
    echo
}

install_git() {
    which git > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "--> Installing git"
        yum install -y git > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            sudo yum install -y git > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                assert "Failed to install Yum package: git"
            fi
        fi
        echo
    fi
}

##################################################################
## main
##################################################################
# parse commandline
for i in "$@"; do
    case $i in
    -h|--help)
        usage
        ;;
    -i|--init)
        init_flag=1
        shift
        ;;
    -v|--verbose)
        logging=0
        shift
        ;;
    *)
        echo "$i is not a valid command line option."
        echo ""
        echo "For help, please use $0 -h"
        echo ""
        exit 1
        ;;
    esac
    shift
done

# get platform
get_os_platform
echo "Running on: ${os_platform} ${os_version}"

# logging message
if [ ${logging} -eq 1 ]; then
    if [ -r ${log_file} ]; then
        rm -f ${log_file}
        if [ $? -ne 0 ]; then assert "ERROR: failed to initialize log [0]: ${log_file}"; fi
    fi

    touch ${log_file}
    if [ $? -ne 0 ]; then assert "ERROR: failed to initialize log [1]: ${log_file}"; fi

    echo "Logging to: ${log_file}"
fi

# validate python stack (try python3 first)
which python3 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    python3_flag=1
else
    which python > /dev/null 2>&1
    if [ $? -ne 0 ]; then assert "Python stack missing"; fi
fi

# get python version
if [ ${python3_flag} -eq 1 ]; then
    python_version="$(python3 <<< 'import sys; print(sys.version_info[0])')"
else
    python_version="$(python <<< 'import sys; print(sys.version_info[0])')"
fi

# perform initialization (optional based on commandline '--init')
if [ ${init_flag} -eq 1 ]; then
    echo "Initiaizing"
    echo "--> removing ${pystub_basedir}"
    rm -rf ${pystub_basedir}
    echo "--> removing ${pystub_venv}"
    rm -rf ${pystub_venv}
    echo
fi

# initialize Python virtual environment
if [ ! -r ${pystub_venv} ]; then
    install_virtualenv
fi

# validate git
which git > /dev/null 2>&1
if [ $? -ne 0 ]; then
    install_git
fi

# install pystub
if [ ! -r ${pystub_basedir} ]; then
    echo "Downloading pystub"
    echo "--> Cloning into ${pystub_basedir} (sourcing from: ${pystub_repo})"
    if [ ${logging} -eq 1 ]; then
        git clone ${pystub_repo} ${pystub_basedir} > ${log_file} 2>&1
    else
        git clone ${pystub_repo} ${pystub_basedir}
    fi
    if [ ! -r ${pystub_basedir} ]; then assert "failed to clone repo to: ${pystub_basedir}"; fi

    # install pystub
    echo "--> Installing pystub"
    if [ ${logging} -eq 1 ]; then
        (cd ${pystub_basedir} && . ${venv_activate} && pip install -e . > ${log_file} 2>&1)
    else
        (cd ${pystub_basedir} && . ${venv_activate} && pip install -e .)
    fi
    if [ $? -ne 0 ]; then assert "failed to install pystub (ran 'pip install -e .')"; fi
fi

# display completion message
echo
echo "pystub installation complete, to start run:"
echo "source ${venv_activate} && pystub"

exit 0
