#!/bin/bash

# if [[ ! -f config/elasticsearch.keystore ]]; then
    echo $minio_access_key | bin/elasticsearch-keystore add s3.client.default.access_key --stdin;
    echo $minio_secret_key | bin/elasticsearch-keystore add s3.client.default.secret_key --stdin;

    # must be reload elasticsearch
    curl -k -s -X POST "https://localhost:9200/_nodes/reload_secure_settings" -u "elastic:$ELASTIC_PASSWORD"
# fi;