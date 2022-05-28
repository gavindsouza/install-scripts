#!/bin/bash

MDBPW="mypass"
ADMINPW="mypass"
SITENAME="site1.local"
BRANCH="develop"
FRAPPEBRANCH="develop"
while getopts ":m:a:s:b:f" OPTION; do

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
    *)
      echo "Usage: $(basename $0) [-a admin password] [-m mariadb password] [-s sitename] [-b ERPNext branch] [-f Frappe branch]"
      exit 1
      ;;
  esac
done

useradd -m -s /usr/bin/bash frappe
echo 'frappe ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers
sudo -i -u frappe bash << EOF
source ~/.profile

# Install docker if it doesn't exist
if ! command -v docker &> /dev/null
then
    wget https://get.docker.com/ -O install-docker.sh
    sh install-docker.sh
fi
# Install Nix if it doesn't exist
if ! command -v nix-env &> /dev/null
then
    wget https://nixos.org/nix/install -O install-nix.sh
    sh install-nix.sh --daemon
fi

# Restart Shell

exec $SHELL


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
sudo apt install -y python3-pip fontconfig
sudo pip install frappe-bench 


# Export Path if non-existent

export PATH="$HOME/.local/bin:$PATH"

# Install base fonts for wkhtmltopdf

git clone --progress --depth 1 https://github.com/frappe/fonts.git /tmp/fonts 

sudo rm -rf /etc/fonts && mv /tmp/fonts/etc_fonts /etc/fonts
sudo rm -rf /usr/share/fonts && mv /tmp/fonts/usr_share_fonts /usr/share/fonts
fc-cache -f 

# Install wkhtmltopdf
echo "Installing wkhtmltopdf"

curl -L  https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.focal_amd64.deb -o /tmp/wkhtmltopdf.deb

sudo dpkg -i /tmp/wkhtmltopdf.deb

sudo rm -rf /tmp/wkhtmltopdf.deb /tmp/fonts

# Start docker daemon
sudo systemctl start docker 
sudo gpasswd -a "${USER}" docker

# Start mariadb in Docker
wget https://gist.githubusercontent.com/athul/x/raw/56877ad792fe2656931403c74dadeb3a80b33689/my.cnf -o /tmp/my.cnf
sudo docker run --name frappe-mariadb -v /tmp/my.cnf:/etc/mysql/my.cnf -e MYSQL_ROOT_PASSWORD=$MDBPW -p 3306:3306 -d docker.io/library/mariadb:10.6


# Init bench
echo "Installing Bench and Setting Up ERPNext for production"
bench init /home/frappe/frappe-bench --version $FRAPPEBRANCH

echo "Creating a new site with $SITENAME"
cd /home/frappe/frappe-bench
bench new site $SITENAME  --admin-password $ADMINPW --mariadb-root-password $MDBPW
bench get-app erpnext https://github.com/frappe/erpnext --branch $BRANCH
bench --site $SITENAME install-app erpnext
sudo bench setup production $USER --yes
EOF
