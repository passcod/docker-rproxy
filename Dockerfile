#> RProxy - Flexible, automagical reverse proxy for Docker.
#? https://github.com/passcod/docker-rproxy
FROM dockerfile/haproxy
MAINTAINER Félix Saparelli me@passcod.name

# Remove haproxy invocation from setup script
RUN head -n-2 /haproxy-start > /setup
RUN rm /haproxy-start
RUN chmod +x /setup

# Set up volume as in base image
VOLUME ["/data", "/haproxy-override"]

# Set up pwd
RUN mkdir /app
WORKDIR /app

# Install deps
RUN apt-get -y install ruby
RUN gem install memoist
RUN wget -P /usr/local/bin https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego
RUN chmod u+x /usr/local/bin/forego
RUN wget https://github.com/jwilder/docker-gen/releases/download/0.3.3/docker-gen-linux-amd64-0.3.3.tar.gz
RUN tar xvzf docker-gen-linux-amd64-0.3.3.tar.gz

# Set up scripts
ADD . /app
ADD haproxy.cfg /etc/haproxy/haproxy.cfg

# For docker-gen
ENV DOCKER_HOST unix:///tmp/docker.sock

# Go for it
CMD ["bash", "/app/start.sh"]
