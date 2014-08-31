#> RProxy - Flexible, automagical reverse proxy for Docker.
#? https://github.com/passcod/docker-rproxy
FROM base/devel:minimal
MAINTAINER Félix Saparelli me@passcod.name

# Deps
RUN pacman -Sy --noconfirm --needed --noprogressbar ruby linux-headers

# HAProxy
ADD https://aur.archlinux.org/packages/ha/haproxy/haproxy.tar.gz /tmp/
RUN cd /tmp/ && tar xzvf haproxy.tar.gz && cd haproxy && makepkg --asroot -si --noconfirm && rm -rf /tmp/haproxy*
RUN mkdir /var/lib/haproxy
VOLUME ["/data", "/override"]

# Docker-gen
ADD https://github.com/jwilder/docker-gen/releases/download/0.3.3/docker-gen-linux-amd64-0.3.3.tar.gz /docker-gen.tar.gz
RUN tar xzvf docker-gen.tar.gz && mv docker-gen /usr/bin/docker-gen && rm docker-gen.tar.gz

# RProxy
RUN gem install --no-rdoc --no-ri foreman memoist

# Files
ADD ./app /app
ADD ./haproxy /etc/haproxy/
ADD ./root /

# Cleanup
RUN /cleanup && rm /cleanup

CMD ["/start"]
