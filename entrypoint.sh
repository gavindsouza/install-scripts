#!/bin/bash

set -euxo pipefail

sudo service nginx start
sudo service mysql start
sudo /usr/bin/supervisord -n