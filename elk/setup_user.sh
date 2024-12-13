#!/bin/bash

filename="/usr/share/elasticsearch/config/certs/passwords.txt"
if [[ ! -f $filename ]]; then
    echo "generatte passwords"
    
    bin/elasticsearch-setup-passwords auto -b > $filename
    elastic_password=$(grep "PASSWORD elastic =" $filename | awk '{print $4}')
fi
