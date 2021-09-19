#!/usr/bin/env bash

# check if user doesn't exist
function user_doesnt_exist {
  if id -u "$1" >/dev/null 2>&1; then
    return 1
  else
    return 0
  fi
}

# check if program doesn't exist
function program_doesnt_exist {
  # set to 1 initially
  local return_=1
  # set to 0 if not found
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  return $return_
}

is_subdomain() {
  [[ $1 =~ \..*\. ]]
}

is_subdomain_psl() {
  local output=$(psl --print-unreg-domain $1)
  local arr=(${output//:/ })
  local name=${1/${arr[1]}/}
  [[ $name =~ \..*\. ]]
}

COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_END='\033[0m'

now() {
  date "+%H:%M:%S"
}

info() {
  local msg=$1
  echo -e "${COLOR_BLUE}[NGINX_SCRIPT] $(now): ${msg}${COLOR_END}"
}

warn() {
  local msg=$1
  echo -e "${COLOR_YELLOW}[NGINX_SCRIPT] $(now): ${msg}${COLOR_END}"
}

success() {
  local msg=$1
  echo -e "${COLOR_GREEN}[NGINX_SCRIPT] $(now): ${msg}${COLOR_END}"
}

fail() {
  local msg=$1
  echo -e "${COLOR_RED}[NGINX_SCRIPT] $(now): ${msg}${COLOR_END}"
  exit 1
}
