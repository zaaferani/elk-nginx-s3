#!/bin/bash

domain=${1:-localhost}

openssl req -x509 -out $domain.crt -keyout $domain.key \
  -newkey rsa:2048 -nodes -sha256 \
  -subj '/CN=$domain' -extensions EXT -config <( \
   printf "[dn]\nCN=$domain\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:$domain\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
