#!/bin/bash

curl -k -s -X POST "https://localhost:9200/_nodes/reload_secure_settings" -u "elastic:$ELASTIC_PASSWORD"