require 'thrifty/version'
require 'rubysh'

require 'thrift'

module Thrifty
  def self.cache_directory=(cache_directory)
    @cache_directory = cache_directory
  end

  def self.register(thrift_file)
    raise "No cache defined" unless @cache_directory
    code_directory = @cache_directory
    Rubysh('thrift', '--gen', 'rb', '-out', code_directory, thrift_file).check_call
  end

  def self.require(generated)
    raise "No cache defined" unless @cache_directory
    code_directory = @cache_directory
    $:.unshift(code_directory)

    begin
      # Global require
      super(generated)
    ensure
      # Not sure what to do if someone changed $: in the
      # meanwhile.
      $:.shift if $:.first == code_directory
    end
  end
end
