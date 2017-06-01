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

docker-compose kill $service
docker-compose rm -f $service

cat << EOF > docker-compose.debug.yml
version: '3'
services:
  $service:
    command: sh -c "node --inspect-brk=0.0.0.0:9229 $workdir$nodeindex"
    ports:
      - "$port:9229"
EOF

docker-compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.debug.yml up -d --build $service

echo "open chrome with url chrome://inspect, then select inspect for $service"

echo "press any key to stop debugging"
read -n 1
rm -rf docker-compose.debug.yml
echo ""
echo "restarting $service without debug"
docker-compose kill $service
docker-compose rm -f $service
docker-compose up -d --build $service
