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

sudo apt install -y python3-pip fontconfig libxrender1 libxext6 xfonts-75dpi xfonts-base wget

sudo pip install frappe-bench

sudo bench setup sudoers

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

# Install wkhtmltopdf
echo "Installing wkhtmltopdf"

wget -O /tmp/wkhtmltopdf.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.focal_amd64.deb

sudo dpkg -i /tmp/wkhtmltopdf.deb

sudo rm -rf /tmp/wkhtmltopdf.deb


# echo 'frappe ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers

sudo -i -u $FRAPPEUSER sh << EOF
source ~/.profile

# Install Nix if it doesn't exist
if ! command -v nix-env &> /dev/null
then
    wget https://nixos.org/nix/install -O install-nix.sh
    sh install-nix.sh --daemon
fi

# Restart Shell

# exec $SHELL

source ~/.bashrc


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


# Install bench
echo "Installing Bench"

git clone https://github.com/frappe/bench ~/.bench 
#Editable local install
pip install -e ~/.bench 

# Init bench
echo "Installing Bench and Setting Up ERPNext for production"
bench init /home/$FRAPPEUSER/frappe-bench --version $FRAPPEBRANCH

echo "Creating a new site with $SITENAME"
cd /home/$FRAPPEUSER/frappe-bench
bench new site $SITENAME --admin-password $ADMINPW --mariadb-root-password $MDBPW
bench get-app https://github.com/frappe/erpnext --branch $BRANCH
bench --site $SITENAME install-app erpnext
sudo bench setup production $FRAPPEUSER --yes
EOF
