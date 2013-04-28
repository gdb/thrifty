require 'digest/sha1'
require 'fileutils'
require 'rubysh'

module Thrifty
  class ThriftFile
    attr_reader :thrift_file

    def initialize(thrift_file)
      @thrift_file = thrift_file
    end

    def defines?(generated_file)
      compile_once
      File.exists?(File.join(build_directory, generated_file + '.rb'))
    end

    def require(generated_file)
      compile_once
      $:.unshift(build_directory)

      begin
        Thrifty.logger.info("Requiring #{generated_file.inspect}, generated from #{thrift_file.inspect}")
        # Global require
        super(generated_file)
      ensure
        # Not sure what to do if someone changed $: in the
        # meanwhile. Could happen due a signal handler or something
        # crazy like that.
        if $:.first == build_directory
          $:.shift
        else
          Thrifty.logger.error("Unexpected first element in load path; not removing #{build_directory.inspect}: #{$:.inspect}")
        end
      end
    end

    def compile_once
      with_cache do
        FileUtils.mkdir_p(build_directory)
        Rubysh('thrift', '--gen', 'rb', '-out', build_directory, thrift_file).check_call
      end
    end

    private

    def with_cache(&blk)
      # There's obviously a race if someone changes the file before
      # the compiler runs, so we capture the sha1 up front so it'll at
      # least be more likely to falsely invalidate the cache.
      new_version = Digest::SHA1.file(thrift_file).to_s
      cached_version = File.read(version_file) if File.exists?(version_file)

      # cached_version will be nil if the cache doesn't exist, so always miss.
      if new_version == cached_version
        Thrifty.logger.debug("Using cached version")
        return
      end

      Thrifty.logger.info("Compiling thrift file #{thrift_file} with SHA1 #{new_version} to #{build_directory}")
      blk.call

      File.open(version_file, 'w') {|f| f.write(new_version)}
    end

    def version_file
      File.join(build_directory, 'VERSION')
    end

    def build_directory
      # Use the basename for informational purposes, and the SHA1 for
      # avoid collisions.
      base = File.basename(thrift_file)
      sha1 = Digest::SHA1.hexdigest(thrift_file)
      File.join(basedir, "#{base}-#{sha1}")
    end

    def basedir
      Thrifty.basedir
    end
  end
end
