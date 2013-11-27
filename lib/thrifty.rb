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

  def self.register(*args, &blk)
    @manager.register(*args, &blk)
  end

  def self.require(*args, &blk)
    @manager.require(*args, &blk)
  end

  def self.prebuild(*args, &blk)
    @manager.prebuild(*args, &blk)
  end
end
