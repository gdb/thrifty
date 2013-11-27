require 'tmpdir'

require 'thrift'
require 'chalk-log'

require 'thrifty/thrift_file'
require 'thrifty/version'

module Thrifty
  @thrift_files = {}

  def self.basedir
    @basedir ||= Dir.tmpdir
  end

  def self.basedir=(basedir)
    @basedir = basedir
  end

  def self.register(thrift_file)
    raise "File already registered: #{thrift_file.inspect}" if @thrift_files.include?(thrift_file)
    @thrift_files[thrift_file] = Thrifty::ThriftFile.new(thrift_file)
  end

  def self.require(generated_file)
    definers = @thrift_files.values.select do |thrift_file|
      thrift_file.defines?(generated_file)
    end

    if definers.length == 0
      raise LoadError, "No registered thrift file defines #{generated_file.inspect}. Perhaps you forgot to run `Thrifty.register(thrift_file)`?"
    elsif definers.length == 1
      definer = definers.first
      definer.require(generated_file)
    else
      raise LoadError, "Ambiguous generated file #{generated_file.inspect} defined in #{definers.map {|definer| definer.thrift_file.inspect}.join(', ')}"
    end
  end
end
