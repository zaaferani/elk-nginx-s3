# Elastic stack (ELK) with 3 nodes on Docker with Minio S3 storage and Nginx reverse proxy

## Prerequisites
- Docker > v20

## Set domain
```bash
echo "127.0.0.1 mydomain s3.mydomain elasticsearch.mydomain kibana.mydomain" >> /etc/hosts
```

## Run nginx reverse proxy
In the first disable elasticsearch and kibana server (comment lines 22:66) in nginx.conf and run nginx:

```bash
docker compose -f nginx/docker-compose.yaml up -d
```

## Run Minio S3 storage
```bash
docker compose -f minio/docker-compose.yaml up -d
```

If minio is not working, check logs using `docker compose -f minio/docker-compose.yaml logs -f --tail 300`.
If you see error like `my-minio  | /opt/bitnami/scripts/libminio.sh: line 374: /bitnami/minio/data/.root_user: Permission denied` you can use this command to fix it:
```bash
sudo chown -R 1001:1001 minio/minio_data
```

### Create bucket and set access policy

Open Minio web interface: http://s3.mydomain

Create bucket: such as `elk-s3-snapshots`

Generate access key and secret key and save it

## Run Elasticsearch cluster

Set environment variables:

```bash
cd elk
cp .env.example .env
sed -i "s/your_minio_access_key=<YOUR_ACCESS_KEY>/your_minio_secret_key=<YOUR_ACCESS_KEY>/g" .env
```

If you use diffrent domain name, change `s3.client.default.endpoint` to your s3 domain name

For run cluster, run:
```bash
./install.sh
```

## Configure nginx
In this step you must enable elasticsearch and kibana server in `nginx.conf` and restart nginx:
```bash
docker compose -f nginx/docker-compose.yaml down;
docker compose -f nginx/docker-compose.yaml up -d;
```

## Check cluster status
```bash
curl -k -XGET "https://elasticsearch.mydomain/_cluster/health?pretty" -u elastic:your-elastic-password
```

or open Kibana web interface: https://kibana.mydomain

## Create index
```bash
curl -k -XPUT "https://elasticsearch.mydomain/my-index" -u elastic:your-elastic-password
curl -k -XPOST "https://elasticsearch.mydomain/my-index/_doc"  -u elastic:your-elastic-password -H 'Content-Type: application/json' \
-d '{
    "id": "id1",
    "title": "name1",
    "description": "Description 1."
}'
```

## Create repository
```bash
curl -k -X PUT "https://elasticsearch.mydomain/_snapshot/my-snapshot?pretty" -H 'Content-Type: application/json'  -u 'elastic:your-elastic-password' \
-d '{
  "type": "s3",
  "settings": {
    "bucket": "elk-s3-snapshots",
    "endpoint": "s3.mydomain",
    "protocol": "http",
    "path_style_access": "true"
  }
}'
```

## Create snapshot
```bash
curl -k -X PUT "https://elasticsearch.mydomain/_snapshot/my-snapshot/snapshot-$(date -I)?wait_for_completion=true&pretty" \
-u 'elastic:your-elastic-password' -H 'Content-Type: application/json' \
-d '{
  "indices": "my-index",
  "ignore_unavailable": true
}'
```
