require 'tmpdir'

require 'thrift'
require 'chalk-log'

require 'thrifty/version'

require 'thrifty/manager'
require 'thrifty/thrift_file'

module Thrifty
  def self.manager
    @manager ||= Thrifty::Manager.new
  end

  [
    :register, :require, :build_root, :build_root=, :compile_all
  ].each do |method|
    define_singleton_method(method) do |*args, &blk|
      manager.send(method, *args, &blk)
    end
  end
end
