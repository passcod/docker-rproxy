# Docker RProxy

_Flexible, automagical reverse proxy for Docker._

RProxy goes beyond [nginx-proxy] to provide a more versatile
solution that covers both multiple HTTP services on multiple
ports, as well as TCP services. It can also distribute incoming
HTTP traffic based on a path prefix or hostnames.

[nginx-proxy]: https://github.com/jwilder/nginx-proxy/

## Install

Just run the [docker image]:

```bash
$ docker pull passcod/rproxy
$ docker run -dP passcod/rproxy
```

[docker image]: https://registry.hub.docker.com/u/passcod/rproxy

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

# On Unix systems, port 0 will use a random available port,
# although I'm not sure what the use of that would be.
$ docker run -Pde RPROXY=http://example.com:0 ecstatic/turing
```

## Behind the scenes

TODO
