# Docker RProxy

_Flexible, automagical reverse proxy for Docker._

RProxy goes beyond [nginx-proxy] to provide a more versatile
solution that covers both multiple HTTP services on multiple
ports, as well as TCP services. It can also distribute incoming
HTTP traffic based on a path prefix or hostnames.

_This probably shouldn't be used for medium- or large- scale
deployments, or for anything where high availability, and other
entreprise/production concerns, are needed. For these, better
solutions such as [Consul], [etcd], [Serf], [SkyDNS],
[SmartStack], [ZooKeeper]… should be used._

[nginx-proxy]: https://github.com/jwilder/nginx-proxy/

[Consul]: http://www.consul.io/
[doozerd]: https://github.com/ha/doozerd
[etcd]: https://github.com/coreos/etcd
[Serf]: http://www.serfdom.io/
[SkyDNS]: https://github.com/skynetservices/skydns
[SmartStack]: http://nerds.airbnb.com/smartstack-service-discovery-cloud/
[ZooKeeper]: https://zookeeper.apache.org/

## Install

Just run the [docker image]:

```bash
$ docker pull passcod/rproxy
$ docker run -d --net=host -v /var/run/docker.sock:/var/run/docker.sock passcod/rproxy
```

`--net=host` will fail under the default backend until
[docker/docker#6887] is released, so you'll probably want to
install LXC and run the Docker daemon with the `-e lxc` option
(or build Docker from master).

Additionally, it exposes `1/tcp` by default and makes the HAProxy
statistics HTTP service available from there at all times, so
you'll want to firewall this.

[docker image]: https://registry.hub.docker.com/u/passcod/rproxy
[docker/docker#6887]: https://github.com/docker/docker/issues/6887

## Usage

RProxy recognises containers that advertise a `RPROXY` environment
variable. This is formatted as a URL. There can be multiple such
URLs, separated by commas.

```
scheme://host:port/path
```

- `scheme` must be `http` or `tcp`. Behind the scenes, this
  sets HAProxy's mode. More information on the low-level is
  available further below.

- `host` is used to differentiate HTTP services. This should be
  set to the _actual_ hostname the service will be used at, as
  traffic will be filtered according to this, so setting it to
  placeholder names will not match and give confusing results.
  The matching is done as a suffix, so `example.com` will also
  match `foo.example.com`. For TCP services, host has no effect,
  but should still be provided to use as an identifier.

- `port` is both the service's port inside the container _and_
  outside RProxy. I consider there to be little reason to use a
  different port, so that's not an option. For TCP, this is the
  only way to differentiate between services — TCP services on
  the same port will be load-balanced, regardless of the `host`.
  If the port is omitted, it defaults to 80 for HTTP and 4 for
  TCP (the first unassigned common port).

- `path` is used as a further filter for HTTP services. It
  matches a prefix path. It has no effect on TCP services.

Some examples:

```bash
# Directs HTTP traffic for host example.com and port 80 to
# this drunk/mayer instance.
$ docker run -Pde RPROXY=http://example.com drunk/mayer

# Directs HTTP traffic for host example.com and port 8080 to
# this sharp/galileo instance.
$ docker run -Pde RPROXY=http://example.com:8080 sharp/galileo

# Directs TCP traffic for port 666 to this cranky/doom instance.
$ docker run -Pde RPROXY=tcp://main.doom:666 cranky/doom

# Load-balances HTTP traffic for host api.example.com port 80
# to these angry/morse instances.
$ docker run -Pde RPROXY=http://api.example.com angry/morse
$ docker run -Pde RPROXY=http://api.example.com angry/morse
$ docker run -Pde RPROXY=http://api.example.com angry/morse

# Directs HTTP traffic for example.com:80/new/... to
# this loving/fermat instance.
$ docker run -Pde RPROXY=http://example.com/new loving/fermat

# An IRC bouncer
$ docker run -Pde RPROXY=tcp://znc:6667,tcp://znc:6697 mad/znc

# A SSHd on multiple ports for e.g. firewall punching
$ docker run -Pde RPROXY=tcp://ssh:22,tcp://ssh:443 jovial/sshd
```

## Under the covers

RProxy uses [HAProxy] with a configuration generated using
[docker-gen] and a custom Ruby script via a docker-gen-to-YAML
template, so that whenever a container is started or stopped,
the configuration changes and HAProxy is reloaded.

Each **scheme** (TCP and HTTP) is given a single `frontend`
section, bound to every port necessary for that scheme, and from
then on, `acl`s are used to route things around. Each `acl` rule
has a small memory cost, but uses negligible additional CPU. The
difference between the frontends come from the diversity of the
routing criterion (TCP uses *port* filters only, while HTTP may
use both *port*, *host*, and *path* filters), and from the speed
of the matching. __TCP is faster.__ When using HTTP mode, the
entire buffer has to be waited on and parsed before the filters
can be checked, as these are Layer 7 concerns. *Ports* are a
Layer 4 concern, and can be checked earlier, without waiting for
nor parsing a full buffer.

Each **config** (a config is a distinct `scheme://host:port/path`
item and its associated containers) is given a single `backend`
and the associated containers are listed within that as `server`s,
to be load-balanced (by default, using the `roundrobin` method).

That's all there is to the proxy side. The Docker side has a few
more elements:

- The RProxy image is run with `--net=host`, which means it *uses
  the host's network stack*. That makes it dead simple to set up
  for simple infrastructure, as you don't need to mess with
  anything else to get it to listen to the outside world. In more
  complex scenarios you may want not to use `--net=host` and
  instead use your own networking solution. Be aware however in
  that case that the image *only* `EXPOSE`s port `1/tcp`, and that
  ports used *will* change depending on which containers run.

- For docker-gen to pick up the IP address of a container, it
  *must* have an exposed or published port. It doesn't matter
  which, and it doesn't even matter if that isn't the correct
  port (which is why the fake examples above use `-P`): RProxy
  operates only using *explicit* instructions, i.e. if a **config**
  isn't specified in the `RPROXY` env variable for the port you
  want RProxy to handle, it won't magically pick it up. It won't
  even bother guessing. You *have* to tell it to.

- The *host* and *path* filters, and really the entire HTTP stack,
  are there mostly for convenience. If you need truly flexible
  reverse proxying or filtering for some ports, it is completely
  ok to have a secondary reverse proxy (e.g. nginx) sitting behind
  RProxy. However, you'll be in charge of routing things to the
  containers they belong to yourself, unless you want to be crazy
  and *route the secondary proxy's traffic back into RProxy*.
  That's probably totally possible but really really untested.

[HAProxy]: http://www.haproxy.org/
[docker-gen]: https://github.com/jwilder/docker-gen/
[file a bug]: https://github.com/passcod/docker-rproxy/issues/new

## Community

- RProxy is released in the Public Domain!
- Pull requests are welcome!
- Comments and bug reports are awesome!
- This is my first docker-related project and may be full of bugs!
