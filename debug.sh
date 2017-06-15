#!/usr/bin/env bash

service=$1

if [ -z $service ]; then
  echo "parameter 1 must be service name"
  echo "optional parameter 2 is node working directory"
  echo "optional parameter 3 is entry point for node"
  exit 1
fi

workdir=${2:-/usr/src/app}
nodeindex=${3:-/src/index}
port=${INSPECT_PORT:-9229}

function debugservice {
  docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.debug.yml up -d --build $service
}

function removeservice {
  docker-compose kill $service
  docker-compose rm -f $service
}

removeservice

cat << EOF > docker-compose.debug.yml
version: '3'
services:
  $service:
    command: sh -c "node --inspect-brk=0.0.0.0:9229 $workdir$nodeindex"
    ports:
      - "$port:9229"
EOF

debugservice

echo "open chrome with url chrome://inspect, then select inspect for $service"

while true; do
  echo "press any key to stop debugging press (r to restart debug)"
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
echo "restarting $service without debug"
removeservice
docker-compose up -d --build $service
