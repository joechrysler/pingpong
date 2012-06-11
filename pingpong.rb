require "rubygems"
require "redis"

origin = Redis.new(host: '127.0.0.1', port: 6379)
destination = Redis.new(host: '127.0.0.1', port: 6380)


def migrate(from, to)
  keys = from.keys '*'
  from.pipelined do
    keys.each do |key|
      from.migrate(to.client.host, to.client.port, key, 0, 1000)
    end
  end
end

def message(o, d)
  puts "key counts %3d:%3d" % [o.dbsize, d.dbsize]
end


origin.flushall
destination.flushall

origin.pipelined do
  500.times do |i|
    origin.set(i, "value#{i}")
  end
end

loop do
  message(origin, destination)
  migrate(origin, destination)
  message(origin, destination)
  migrate(destination, origin)
  puts
  sleep 0.5
end
