require "rubygems"
require "redis"

origin = Redis.new(host: '127.0.0.1', port: 6379)
destination = Redis.new(host: '127.0.0.1', port: 6380)

def migrate(from, to)
  # migrate keys from a redis connection to another one
  keys = from.keys '*'
  from.pipelined do
    keys.each do |key|
      from.migrate(to.client.host, to.client.port, key, 0, 1000)
    end
  end
end

def message(o, d)
  # this is a lazily imagined method
  puts "key counts %3d:%3d" % [o.dbsize, d.dbsize]
end


# flush any old stuff
origin.flushall
destination.flushall

# generate some new stuff
origin.pipelined do
  500.times do |i|
    origin.set(i, "value#{i}")
  end
end


loop do
  # bounce data between a couple redis connections
  message(origin, destination)
  migrate(origin, destination)
  message(origin, destination)
  migrate(destination, origin)
  puts
  sleep 1.0
end
