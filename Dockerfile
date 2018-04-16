#Based on https://github.com/helpyio/helpy/wiki/Installing-Helpy-on-Ubuntu-16.04-using-Passenger-and-Nginx
FROM ubuntu:16.04

ENV HELPY_USER=helpy \
  HELPY_HOME=/helpy \
  RAILS_ENV=production

# set up deps
RUN apt-get update \
  && apt-get install -y git-core imagemagick postgresql-client libpq-dev curl build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libcurl4-openssl-dev libxml2-dev libxslt1-dev python-software-properties nodejs

# install PGP Key and add https support
RUN apt-get install -y dirmngr gnupg \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7 \
  && apt-get install -y apt-transport-https ca-certificates

# Install Passenger + Nginx
RUN echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list \ 
  && apt-get update \
  && apt-get install -y nginx-extras passenger

# Set up passenger and start nginx
ADD https://www.linode.com/docs/assets/660-init-deb.sh /etc/init.d/nginx
RUN chmod 755 /etc/init.d/nginx
RUN /usr/sbin/update-rc.d -f nginx defaults
COPY docker/nginx.default-vhost /etc/nginx/sites-available/default
COPY docker/nginx.conf /etc/nginx/nginx.conf
RUN service nginx start

# add user
RUN useradd ${HELPY_USER} \
  && mkdir -p ${HELPY_HOME} \ 
  && chown -R ${HELPY_USER}:${HELPY_USER} ${HELPY_HOME}

# Install Ruby/rvm
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
  && curl -sSL https://get.rvm.io | bash -s stable 
RUN /bin/bash -l -c "source /etc/profile.d/rvm.sh"
RUN /bin/bash -l -c "rvm install 2.3.3"
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm gemset create helpy"
RUN /bin/bash -l -c "rvm 2.3.3@helpy"
RUN /bin/bash -l -c "gem install rails --no-ri --no-rdoc -v 4.2.10"
RUN /bin/bash -l -c "gem install bundler"
RUN chown -R ${HELPY_USER}:${HELPY_USER} /usr/local/rvm/gems/ruby-2.3.3
  
# Pull down helpy
WORKDIR ${HELPY_HOME}
USER ${HELPY_USER}

RUN git clone https://github.com/daffinito/helpy.git .

RUN /bin/bash -l -c "bundle install"

RUN touch /helpy/log/production.log \
  && chmod 0664 /helpy/log/production.log

VOLUME ${HELPY_HOME}/public

COPY docker/runhelpy.sh $HELPY_HOME/runhelpy.sh

CMD [ "./runhelpy.sh" ]