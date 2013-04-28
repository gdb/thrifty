require 'thrifty'
Thrifty.register('service.thrift')
Thrifty.require('user_storage')

class UserStorageServer
  def initialize
    @store = {}
  end

  def store(user_profile)
    @store[user_profile.uid] = user_profile
  end

  def retrieve(uid)
    @store[uid]
  end
end

handler = UserStorageServer.new
processor = UserStorage::Processor.new(handler)
transport = Thrift::ServerSocket.new(9090)
transportFactory = Thrift::BufferedTransportFactory.new()
server = Thrift::SimpleServer.new(processor, transport, transportFactory)

puts "Booting user storage server..."
server.serve
