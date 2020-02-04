#!/bin/bash

set -euxo pipefail

docker cp erpnext:/home/frappe/frappe-bench/sites /home/docker/frappe-bench
# docker cp erpnext:/var/lib/mysql/. /home/docker/mysql-data

docker container stop erpnext
docker container rm erpnext

# docker run -d --name erpnext -p 80:80 -v /home/docker/frappe-bench/sites:/home/frappe/frappe-bench/sites -v /home/docker/mysql-data:/var/lib/mysql frappe/erpnext:version-12
docker run -d --name erpnext -p 80:80 -v /home/docker/frappe-bench/sites:/home/frappe/frappe-bench/sites frappe/erpnext:version-12
