#!/usr/bin/env sh

set -x

echo "Performing destructive operation. Removing all volumes associated with the compose file"
sleep 6

docker volume rm nifi-docker-compose_conf
docker volume rm nifi-docker-compose_content
docker volume rm nifi-docker-compose_data
docker volume rm nifi-docker-compose_db
docker volume rm nifi-docker-compose_flowfile
docker volume rm nifi-docker-compose_logs
docker volume rm nifi-docker-compose_provenance