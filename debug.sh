#!/usr/bin/env bash

# https://raw.githubusercontent.com/JamesKyburz/docker-node-debug/master/debug.sh

service=$1

declare -r cs_color_green="\033[1;92m"
declare -r cs_color_red="\033[0;91m"
declare -r cs_color_reset="\033[0m"

alias log_success="log green "
alias log_error="log red "

shopt -s expand_aliases

log () {
  local log_color="cs_color_${1}"
  echo -e "${cs_color_reset}${!log_color}${*:2}${cs_color_reset}"
}

if [ -z $service ]; then
  log_error "parameter 1 must be service name"
  log_error "optional parameter 2 is node working directory"
  log_error "optional parameter 3 is entry point for node"
  exit 1
fi

workdir=${2:-/usr/src/app}
nodeindex=${3:-/src/index}
port=${INSPECT_PORT:-9229}
ymlfiles=${DOCKER_COMPOSE_YAML_FILES:--f docker-compose.yml -f docker-compose.override.yml}

compose="docker-compose $ymlfiles"

function debugservice {
  $compose -f docker-compose.debug.yml up -d --build $service
}

function removeservice {
  $compose kill $service
  $compose rm -f $service
}

removeservice

cat << EOF > docker-compose.debug.yml
version: '3'
services:
  $service:
    entrypoint: sh -c "node --inspect-brk=0.0.0.0:9229 $workdir$nodeindex"
    command: []
    environment:
      - RABBITMQ_PREFETCH=1
    ports:
      - "$port:9229"
EOF

debugservice

log_success "open chrome with url chrome://inspect, then select inspect for $service"

while true; do
  log_success "press any key to stop debugging press (r to restart debug)"
  read -n 1 key
  if [ "$key" == "r" ]; then
    removeservice
    debugservice
  else
    break
  fi
done
rm -rf docker-compose.debug.yml
echo ""
log_success "restarting $service without debug"
removeservice
$compose up -d --build $service
