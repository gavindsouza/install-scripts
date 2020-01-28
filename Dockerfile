FROM ubuntu:18.04
MAINTAINER gavindsouza <gavin@erpnext.com>

ENV FRAPPE_USER=frappe \
    MYSQL_PASSWORD=12345678 \
    ADMIN_PASSWORD=12345678 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get -qq update \
    && apt-get -qq install -y sudo curl gnupg

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - 
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash -

RUN adduser --disabled-password --gecos '' $FRAPPE_USER && adduser $FRAPPE_USER sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $FRAPPE_USER
WORKDIR /home/$FRAPPE_USER

RUN sudo apt-get -qq install -y curl git gnupg sudo nodejs python3 python3-pip redis-server mariadb-server mariadb-client libmariadbclient18 nginx supervisor mariadb-common python3-mysqldb cron

RUN sudo apt-get -qq update && sudo apt-get -qq install -y yarn 
RUN git clone -q https://github.com/frappe/bench ~/.bench && pip3 install --user -q -e ~/.bench

ENV PATH=$PATH:/home/$FRAPPE_USER/.local/bin
ENV DEBIAN_FRONTEND noninteractive
#RUN sudo service mysql start \
#    && sudo mysqladmin -u root password $MYSQL_PASSWORD
RUN sudo mysqladmin -u root -p $MYSQL_PASSWORD

RUN bench init frappe-bench --skip-assets

#RUN cd frappe-bench \
#    && bench get-app erpnext

# RUN bench new-site site1.local --mariadb-root-password $MYSQL_PASSWORD \
#    && bench --site site1.local install-app erpnext \
#    && bench start

EXPOSE 80

CMD ["bash"]
