#!/bin/bash

MDBPW="mypass"
ADMINPW="mypass"
SITENAME="site1.local"
BRANCH="develop"
FRAPPEBRANCH="develop"
FRAPPEUSER="frappe"

while getopts ":m:a:s:b:f:u" OPTION; do

  case "$OPTION" in
    m)
      MDBPW="$OPTARG"
      ;;
    a)
      ADMINPW="$OPTARG"
      ;;
    s)
      SITENAME="$OPTARG"
      ;;
    b)
      BRANCH="$OPTARG"
      ;;
    f)
      FRAPPEBRANCH="$OPTARG"
      ;;
    u)
      FRAPPEUSER="$OPTARG"
      ;;
    *)
      echo "Usage: $(basename $0) [-a admin password] [-m mariadb password] [-s sitename] [-b ERPNext branch] [-f Frappe branch] [-u frappe user]"
      exit 1
      ;;
  esac
done

useradd -m -s /usr/bin/bash $FRAPPEUSER

sudo apt update

sudo apt install -y python3-pip python3.8-venv python3.8-dev wget git certbot

sudo pip3 install setuptools wheel frappe-bench

# Install docker if it doesn't exist
if ! command -v docker &> /dev/null
then
    wget https://get.docker.com/ -O install-docker.sh
    sh install-docker.sh
fi

# Start docker daemon
sudo systemctl start docker 
sudo gpasswd -a $FRAPPEUSER docker

# Start mariadb in Docker
wget -O ~/.my.cnf https://gist.githubusercontent.com/athul/96c7e86c7e6e70c7f8d4e87e49c95f32/raw/fa68699858b68d1676134f3d4c5c5f045a4872c9/my.cnf
sudo docker run --name frappe-mariadb -v ~/.my.cnf:/etc/mysql/my.cnf -e MYSQL_ROOT_PASSWORD=$MDBPW -p 3306:3306 -d docker.io/library/mariadb:10.6


echo 'frappe ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers

sudo -i -u $FRAPPEUSER sh << EOF
source ~/.profile

# Install Nix if it doesn't exist
if ! command -v nix-env &> /dev/null
then
    wget https://nixos.org/nix/install -O install-nix.sh
    sh install-nix.sh --daemon
fi
EOF

sudo -i -u $FRAPPEUSER sh << EOF

# Install bench
echo "Installing Bench"

pip3 install setuptools wheel frappe-bench --user

# Install the required packages with Nix
nix-env -iA \
    nixpkgs.nodejs-14_x \
    nixpkgs.yarn \
    nixpkgs.redis \
    nixpkgs.python39Full \
    nixpkgs.python39Packages.pip \
    nixpkgs.python39Packages.setuptools \
    nixpkgs.python27 \
    nixpkgs.nginx \
    nixpkgs.gcc \
    nixpkgs.gnumake \
    nixpkgs.mariadb-client \
    nixpkgs.wkhtmltopdf

# Init bench
echo "Installing Bench and Setting Up ERPNext for production"
bench init /home/$FRAPPEUSER/frappe-bench --version $FRAPPEBRANCH

echo "Creating a new site with $SITENAME"
cd /home/$FRAPPEUSER/frappe-bench
bench new-site $SITENAME --admin-password $ADMINPW --mariadb-root-password $MDBPW
bench get-app https://github.com/frappe/erpnext --branch $BRANCH
bench --site $SITENAME install-app erpnext
sudo bench setup production $FRAPPEUSER --yes
EOF