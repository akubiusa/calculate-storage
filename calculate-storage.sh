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

# docker system prune は進捗を出さないため、dangling イメージの残数から進捗と ETA を推定して出力する
# dangling 以外の未使用イメージは件数に含まれない
function docker_prune_with_progress() {
  local interval=30
  local total start prune_pid tick remaining done_count elapsed

  total=$(docker images -f dangling=true -q | wc -l)
  echo "Docker prune started (dangling images: $total)"
  start=$(date +%s)

  docker system prune -a -f &
  prune_pid=$!
  # バックグラウンドジョブは SIGINT を無視するため、中断時は明示的に止める
  trap 'kill "$prune_pid" 2>/dev/null; exit 130' INT TERM

  tick=0
  while kill -0 "$prune_pid" 2>/dev/null; do
    sleep 1
    tick=$((tick + 1))
    if [ $((tick % interval)) -ne 0 ]; then
      continue
    fi

    remaining=$(docker images -f dangling=true -q | wc -l)
    done_count=$((total - remaining))
    elapsed=$(($(date +%s) - start))
    if [ "$done_count" -gt 0 ]; then
      echo "Docker prune progress: $remaining/$total dangling images remaining, elapsed ${elapsed}s, ETA about $((elapsed * remaining / done_count))s"
    else
      echo "Docker prune progress: $remaining/$total dangling images remaining, elapsed ${elapsed}s, ETA unknown"
    fi
  done

  wait "$prune_pid"
  trap - INT TERM
}

# docker command exists
if type docker >/dev/null 2>&1; then
  docker_prune_with_progress
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
