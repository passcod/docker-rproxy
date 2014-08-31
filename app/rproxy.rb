require 'erb'
require 'json'
require 'memoist'
require 'uri'
require 'yaml'

module URI
  class TCP < Generic
    DEFAULT_PORT = 4
  end
  @@schemes['TCP'] = TCP
end

class K_
  extend Memoist

  def parse(conf)
    URI conf
  end

  def slug(conf, with_scheme = true)
    s = [conf.hostname.gsub('.', '_'), conf.port]
    s.unshift(conf.scheme) if with_scheme
    s.join '_'
  end

  memoize :parse, :slug
end
_ = K_.new

containers = (YAML.load_file('/app/docker.yml') || []).select do |cont|
  cont[:env].include? :RPROXY
end

containers.select! do |c|
  c[:rconfig] = c[:env][:RPROXY].split(',').map {|r| _.parse r}
  c[:rconfig].reduce(true) {|memo, obj| memo && obj.scheme =~ /^(http|tcp)$/}
end

res = File.read '/etc/haproxy/haproxy.cfg'
res += "\n\n"

if containers.length == 0
  $stderr.puts 'No eligible containers, writing default config'
  res += "\nfrontend tcp"
  res += "\nfrontend http"
  res += "\n  mode http"
else
  configs = {tcp: {}, http: {}}
  ports = {tcp: [], http: []}
  containers.each do |c|
    next if c[:addresses].nil?
    c[:rconfig].each { |r|
      s = r.scheme.to_sym
      t = configs[s]
      t[r] ||= []
      t[r] << c
      ports[s] << r.port
    }
  end

  ports[:http].sort!.uniq!
  ports[:tcp].sort!.uniq!
  conflict = ports[:http] & ports[:tcp]
  if conflict.length > 0
    $stderr.puts 'Fatal! Port(s) conflict between tcp and http:'
    $stderr.puts "  #{conflict.join(', ')}"
    exit 2
  end

  file = File.read '/app/haproxy.erb'
  erb = ERB.new file
  res += erb.result binding
end

res = res
  .split("\n")
  .reject {|l| l =~ /^\s*$/}
  .map {|l| if l[0] == " " then l else "\n#{l}" end}
  .join("\n")

File.write '/app/haproxy.conf', res
exec '/reload' # Reload HAProxy
