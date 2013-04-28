require 'thrifty'
Thrifty.register('service.thrift')
Thrifty.require('user_storage')

port = ARGV[0] || 9090

transport = Thrift::BufferedTransport.new(Thrift::Socket.new('127.0.0.1', 9090))
protocol = Thrift::BinaryProtocol.new(transport)
client = UserStorage::Client.new(protocol)

transport.open

profile = UserProfile.new
profile.uid = 1234
profile.name = 'my name!'
profile.blurb = 'your name!'

puts "Storing #{profile.inspect}"
client.store(profile)

retrieved = client.retrieve(1234)
puts "Retrieved #{retrieved.inspect}"
