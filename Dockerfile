#> RProxy - Flexible, automagical reverse proxy for Docker.
#? https://github.com/passcod/docker-rproxy
FROM base/devel:minimal
MAINTAINER Félix Saparelli me@passcod.name

# Deps
RUN pacman -Sy --noconfirm --needed linux-headers ruby supervisor

# Docker-gen
ADD https://github.com/jwilder/docker-gen/releases/download/0.3.3/docker-gen-linux-amd64-0.3.3.tar.gz /docker-gen.tar.gz
RUN tar xzvf docker-gen.tar.gz && mv docker-gen /usr/bin/docker-gen && rm docker-gen.tar.gz

# HAProxy
ADD https://aur.archlinux.org/packages/ha/haproxy/haproxy.tar.gz /tmp/
RUN cd /tmp/ && tar xzvf haproxy.tar.gz && cd haproxy && makepkg --asroot -si --noconfirm && rm -rf /tmp/haproxy*
RUN mkdir -p /var/lib/haproxy
VOLUME ["/data", "/override"]
EXPOSE 1

# RProxy
RUN gem install --no-rdoc --no-ri memoist

# Supervisor
RUN mkdir -p /var/log/supervisor

# Cleanup
ADD cleanup /cleanup
RUN /cleanup && rm /cleanup

# Files
ADD app /app
ADD haproxy /etc/haproxy/
ADD root /
ADD supervisord.conf /etc/supervisord.conf

CMD ["/usr/bin/supervisord"]
