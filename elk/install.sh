#!/bin/bash

source lib.sh

cd elk;

if [[ ! -f .env ]]; then
    cp .env.example .env
fi

log 'Creating certificates'

docker compose up create_certs;

log 'Starting Elasticsearch'

docker compose up -d;

log 'Waiting for availability of Elasticsearch. This can take several minutes.'

declare -i exit_code=0
wait_for_elasticsearch || exit_code=$?

if ((exit_code)); then
	case $exit_code in
		6)
			suberr 'Could not resolve host. Is Elasticsearch running?'
			;;
		7)
			suberr 'Failed to connect to host. Is Elasticsearch healthy?'
			;;
		28)
			suberr 'Timeout connecting to host. Is Elasticsearch healthy?'
			;;
		*)
			suberr "Connection to Elasticsearch failed. Exit code: ${exit_code}"
			;;
	esac

	exit $exit_code
fi

sublog 'Elasticsearch is running'

log 'Waiting for initialization of built-in users'

docker compose exec -T elasticsearch01 bash < setup_user.sh

log 'Initialization of built-in users completed'

log 'Store Elasticsearch password'

filename="../certs/passwords.txt"
apm_system_password=$(grep "PASSWORD apm_system =" $filename | awk '{print $4}')
kibana_system_password=$(grep "PASSWORD kibana_system =" $filename | awk '{print $4}')
kibana_password=$(grep "PASSWORD kibana =" $filename | awk '{print $4}')
logstash_system_password=$(grep "PASSWORD logstash_system =" $filename | awk '{print $4}')
beats_system_password=$(grep "PASSWORD beats_system =" $filename | awk '{print $4}')
remote_monitoring_user_password=$(grep "PASSWORD remote_monitoring_user =" $filename | awk '{print $4}')
elastic_password=$(grep "PASSWORD elastic =" $filename | awk '{print $4}')

sed -i "s/APM_SYSTEM_PASSWORD=.*/APM_SYSTEM_PASSWORD=$apm_system_password/" .env
sed -i "s/KIBANA_SYSTEM_PASSWORD=.*/KIBANA_SYSTEM_PASSWORD=$kibana_system_password/" .env
sed -i "s/KIBANA_PASSWORD=.*/KIBANA_PASSWORD=$kibana_password/" .env
sed -i "s/LOGSTASH_SYSTEM_PASSWORD=.*/LOGSTASH_SYSTEM_PASSWORD=$logstash_system_password/" .env
sed -i "s/BEATS_SYSTEM_PASSWORD=.*/BEATS_SYSTEM_PASSWORD=$beats_system_password/" .env
sed -i "s/REMOTE_MONITORING_USER_PASSWORD=.*/REMOTE_MONITORING_USER_PASSWORD=$remote_monitoring_user_password/" .env
sed -i "s/ELASTIC_PASSWORD=.*/ELASTIC_PASSWORD=$elastic_password/" .env

docker compose up -d;

wait_for_elasticsearch || exit_code=$?

docker compose exec -T elasticsearch01 bash < setup_keystore.sh
docker compose exec -T elasticsearch02 bash < setup_keystore.sh
docker compose exec -T elasticsearch03 bash < setup_keystore.sh