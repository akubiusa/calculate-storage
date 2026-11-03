#!/bin/bash
set -eu

# root check
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Required: git, python3, python3-venv
function check_command() {
  if ! type "$1" >/dev/null 2>&1; then
    read -p "Do you want to install $1? [y/n]: " yn
    if [ "$yn" = "y" ]; then
      if type apt >/dev/null 2>&1; then
        apt update
        apt install -y "$1"
      elif type yum >/dev/null 2>&1; then
        yum install -y "$1"
      else
        echo "Not found package manager"
        exit 1
      fi
    else
      echo "Please install $1"
      exit 1
    fi
  fi
}

check_command git
check_command python3

# docker command exists
if type docker >/dev/null 2>&1; then
  docker system prune -a -f
fi

mkdir -p /opt/calculate-storage
chmod 777 /opt/calculate-storage
cd /opt/calculate-storage || exit 1

# clone repository
if [ ! -d /opt/calculate-storage/.git ]; then
  git clone https://github.com/book000/calculate-storage.git .
else
  git pull
fi

# Debian/Ubuntu では ensurepip が python3-venv にのみ含まれる
if ! python3 -c "import ensurepip" >/dev/null 2>&1; then
  if type apt >/dev/null 2>&1; then
    apt update
    apt install -y python3-venv
  else
    echo "ensurepip is unavailable for python3; install the package that provides venv"
    exit 1
  fi
fi

# create venv and install requirements
# venv/bin/pip が残っていても pip モジュールが無い venv があるため、pip が実際に動くかで判定する
if ! venv/bin/python3 -m pip --version >/dev/null 2>&1; then
  python3 -m venv --clear venv
fi

venv/bin/pip install -r requirements.txt

export CALCULATE_STORAGE_LOG_DIR=/opt/calculate-storage/logs
venv/bin/python3 calculate_storage.py $ISSUE_NUMBER
