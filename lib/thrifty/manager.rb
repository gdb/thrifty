class Thrifty::Manager
  def initialize
    @thrift_files = {}
  end

  def register(thrift_file, options={})
    thrift = Thrifty::ThriftFile.new(thrift_file, options)

    if @thrift_files.include?(thrift.path)
      raise "File already registered: #{thrift.path}"
    end

    @thrift_files[thrift.path] = thrift
  end

  def require(generated_file)
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
