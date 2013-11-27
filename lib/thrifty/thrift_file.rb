require 'digest/sha1'
require 'fileutils'
require 'rubysh'

class Thrifty::ThriftFile
  include Chalk::Log

  attr_reader :relative_path, :options

  def initialize(manager, relative_path, options={})
    @manager = manager
    @relative_path = relative_path
    @options = options
  end

  def validate_existence
    raise "No such Thrift file #{path.inspect}" unless File.exists?(path)
  end

  def path
    expand_relative_path(@relative_path)
  end

  def defines?(generated_file)
    compile_once
    File.exists?(File.join(build_directory, generated_file + '.rb'))
  end

  def require(generated_file)
    compile_once
    $:.unshift(build_directory)

    begin
      log.info('Requiring', file: generated_file, idl: path)
      # Global require
      super(generated_file)
    ensure
      # Not sure what to do if someone changed $: in the
      # meanwhile. Could happen due a signal handler or something
      # crazy like that.
      if $:.first == build_directory
        $:.shift
      else
        log.error('Unexpected first element in load path; not removing', build_directory: build_directory, load_path: $:.inspect)
      end
    end
  end

  def compile_once
    with_cache do
      FileUtils.mkdir_p(build_directory)
      Rubysh('thrift', '--gen', 'rb', '-out', build_directory, path).check_call
    end
  end


  def version_file
    File.join(build_directory, 'VERSION')
  end

  def build_directory
    # Use the basename for informational purposes, and the SHA1 for
    # avoid collisions.
    base = File.basename(path)
    sha1 = Digest::SHA1.hexdigest(path)
    File.join(build_root, "#{base}-#{sha1}")
  end

  def build_root
    if build_root = @options[:build_root]
      expand_relative_path(build_root)
    else
      @manager.build_root # Don't expand the manager's build root
    end
  end

  private

  def with_cache(&blk)
    validate_existence

    # There's obviously a race if someone changes the file before
    # the compiler runs, so we capture the sha1 up front so it'll at
    # least be more likely to falsely invalidate the cache.
    new_version = Digest::SHA1.file(path).to_s
    cached_version = File.read(version_file) if File.exists?(version_file)

    # cached_version will be nil if the cache doesn't exist, so always miss.
    if new_version == cached_version
      log.debug('Using cached version')
      return false
    end

    log.info('Compiling thrift file', idl: path, sha1: new_version, build_directory: build_directory)
    blk.call

    File.open(version_file, 'w') {|f| f.write(new_version)}

    true
  end

  def expand_relative_path(path)
    if relative_to = @options[:relative_to]
      path = File.expand_path(path, File.join(relative_to, '..'))
    end
    path
  end
end
