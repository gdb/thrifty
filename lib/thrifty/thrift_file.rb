require 'digest/sha1'
require 'fileutils'
require 'rubysh'

class Thrifty::ThriftFile
  include Chalk::Log

  DUMMY_DIRECTORY = File.expand_path('../dummy', __FILE__)

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

    # This is a bit dicey, as a generated thrift <file> will also
    # include <file>_types and <file>_constants as well as
    # 'thrift'. We need to make sure we can handle file names that may
    # have already been required -- this path munging should
    # successfully do so.

    super('thrift')
    log.debug('Requiring', file: generated_file, idl: path, build_directory: build_directory)

    orig_load_path = $:.dup

    begin
      $:[0..-1] = @manager.require_path + [DUMMY_DIRECTORY]
      # Global require
      super(generated_file)
    ensure
      $:[0..-1] = orig_load_path
    end
  end

  def compile_once
    with_cache do
      begin
        FileUtils.mkdir_p(build_directory)
      rescue Errno::EACCES => e
        e.message << ' (HINT: this probably means you forgot to precompile your Thrift file, or the relative path has changed between your build and deploy machines)'
        raise e
      end
      includes = @manager.include_path.map {|x| ['-I', x]}.flatten
      Rubysh('thrift', *includes, '--gen', 'rb', '-out', build_directory, path).check_call
    end
  end

  def version_file
    File.join(build_directory, 'VERSION')
  end

  def build_directory
    # Use the basename for informational purposes, and the SHA1 to avoid
    # collisions.
    #
    # Use relative_path since that should be invariant across machines
    # (i.e. once you've deployed the service).
    base = File.basename(path)
    sha1 = Digest::SHA1.hexdigest(relative_path)
    File.join(build_root, "#{base}-#{sha1}")
  end

  def build_root
    if build_root = @options[:build_root]
      expand_relative_path(build_root)
    elsif @options[:relative_to]
      File.join(File.dirname(path), 'build-thrifty')
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
