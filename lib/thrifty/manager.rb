class Thrifty::Manager
  attr_accessor :build_root

  def initialize
    @thrift_files = {}
    @build_root ||= File.join(Dir.tmpdir, 'thrifty')
  end

  def register(path, options={})
    thrift_file = Thrifty::ThriftFile.new(self, path, options)
    thrift_file.validate_existence

    if @thrift_files.include?(thrift_file.path)
      raise "File already registered: #{thrift_file.path}"
    end

    @thrift_files[thrift_file.path] = thrift_file
    thrift_file
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

  def compile_all
    @thrift_files.map do |_, thrift_file|
      built = thrift_file.compile_once
      [thrift_file, built]
    end
  end
end
