#!/bin/bash

echo $minio_access_key | bin/elasticsearch-keystore add s3.client.default.access_key --stdin;
echo $minio_secret_key | bin/elasticsearch-keystore add s3.client.default.secret_key --stdin;