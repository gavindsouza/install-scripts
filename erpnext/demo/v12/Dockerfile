# UNMAINTAINED - last used/tested in 2020
FROM ubuntu:18.04

LABEL maintainer="gavindsouza <gavin18d@gmail.com>"

ENV FRAPPE_USER=frappe \
	MYSQL_PASSWORD=12345678 \
	ADMIN_PASSWORD=12345678 \
	VERSION=version-12 \
	DEBIAN_FRONTEND=noninteractive \
	LC_ALL=C.UTF-8 \
	LANG=C.UTF-8

RUN apt-get -qq update \
	&& apt-get -qq install -y sudo wget gnupg python3-minimal python3-pip npm nodejs git mariadb-server redis-server cron \
	&& npm install -g yarn \
	&& apt-get purge npm -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean -y \
	&& apt-get autoremove -y \
	&& mkdir -p /run/systemd && echo 'docker' > /run/systemd/container \
	&& echo "export PATH=$PATH::/home/frappe/.local/bin" > /etc/environment \
	&& useradd $FRAPPE_USER \
	&& mkdir /home/$FRAPPE_USER \
	&& chown -R $FRAPPE_USER.$FRAPPE_USER /home/$FRAPPE_USER \
	&& usermod -aG sudo $FRAPPE_USER \
	&& echo "${FRAPPE_USER}	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /home/$FRAPPE_USER

RUN git clone https://github.com/frappe/bench .bench \
	&& pip3 install -q -e .bench \
	&& rm -rf ~/.cache/* \
	&& find . -name ".git/*" -delete

USER $FRAPPE_USER

RUN sudo service mysql restart \
	&& sudo mysql -u root -p${MYSQL_PASSWORD} -e "DROP USER 'root'@'localhost';CREATE USER 'root'@'%' IDENTIFIED BY '';GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;FLUSH PRIVILEGES;" \
	&& sudo mysqladmin -u root password ${MYSQL_PASSWORD} \
	&& mysql -u root -p${MYSQL_PASSWORD} -e " \
	SET GLOBAL innodb_file_format='Barracuda'; \
	SET GLOBAL innodb_file_per_table='ON'; \
	SET GLOBAL innodb_large_prefix='ON'; \
	SET GLOBAL character_set_server='utf8mb4'; \
	SET GLOBAL collation_server='utf8mb4_unicode_ci';commit;" \
	&& bench init frappe-bench --frappe-branch ${VERSION} \
	&& cd frappe-bench \
	&& bench new-site site1.local --mariadb-root-password ${MYSQL_PASSWORD} --admin-password ${ADMIN_PASSWORD} \
	&& bench get-app erpnext --branch ${VERSION} \
	&& bench --site site1.local install-app erpnext \
	&& sudo bench setup production ${FRAPPE_USER} \
	&& sudo python3 -m pip uninstall ansible -y \
	&& sudo find ~ -name "*.pyc" -delete \
	&& sudo find . -name "**/.git/*" -delete \
	&& sudo rm -rf /var/lib/apt/lists/* \
	&& sudo rm -rf /root/.cache/* \
	&& sudo rm -rf /home/${FRAPPE_USER}/.cache/* \
	&& sudo apt-get clean -y \
	&& sudo apt-get autoremove -y

WORKDIR /home/${FRAPPE_USER}/frappe-bench

EXPOSE 80
COPY entrypoint.sh /usr/local/bin/
RUN sudo chmod +x /usr/local/bin/entrypoint.sh
CMD ["sudo","/usr/local/bin/entrypoint.sh"]