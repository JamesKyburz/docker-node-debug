#!/usr/bin/env bash

service=$1

docker-compose kill $service
docker-compose rm -f $service

cat << EOF > docker-compose.debug.yml
version: '3'
services:
  $service:
    command: sh -c "yarn prestart ; node --inspect-brk=0.0.0.0:9229 /usr/src/app/src/index"
    ports:
      - "9229:9229"
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
