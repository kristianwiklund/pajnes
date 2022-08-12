#!/bin/sh

docker network create --driver bridge influxdb-telegraf-net
docker-compose up -d
echo "Open http://localhost:8086/ in your favorite browser"
echo "Select user pajnes, if you use pajnespajnes as password, everything works out of the box"

