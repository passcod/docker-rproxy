haproxy: haproxy -f /app/haproxy.conf -p /var/run/haproxy.pid
dockergen: /app/docker-gen -notify="ruby /app/rproxy.rb" -watch /app/yaml.tmpl /app/docker.yml
