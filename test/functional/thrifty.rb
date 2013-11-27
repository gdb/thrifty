require_relative '_lib'
require 'fileutils'
require 'thrifty'
require 'chalk-tools'

class Thrifty::DynamicTest < Critic::Functional::Test
  def self.it_isolated(description, &blk)
    method = Chalk::Tools::ClassUtils.generate_method('test block', self, blk)

    it(description) do
      pid = fork do
        method.bind(self).call
        # This is very lurky, but a natural exit always seems to return 1
        exec('true')
      end
      _, status = Process.waitpid2(pid)
      assert_equal(0, status.exitstatus)
    end
  end

  describe 'without a build_root' do
    it_isolated 'can load the service' do
      Thrifty.register('_lib/thrift/service.thrift', relative_to: __FILE__)
      Thrifty.require('user_storage')
      ThriftyTest::UserStorage
    end
  end

  describe 'with a build_root' do
    before do
      @build_root = File.expand_path('../_lib/thrift/build', __FILE__)
      FileUtils.rm_rf(@build_root)
      assert(!File.exists?(@build_root))
    end

    it_isolated 'raises an error if the thrift file does not exist' do
      assert_raises(RuntimeError) do
        Thrifty.register('_lib/thrift/nonexistent.thrift',
          relative_to: __FILE__,
          build_root: '_lib/thrift/build')
      end
    end

    it_isolated 'sets paths appropriately' do
      thrift_file = Thrifty.register('_lib/thrift/service.thrift',
        relative_to: __FILE__,
        build_root: '_lib/thrift/build')
      assert_equal(File.expand_path('../_lib/thrift/service.thrift', __FILE__),
        thrift_file.path)
      assert_equal(File.expand_path('../_lib/thrift/build', __FILE__), thrift_file.build_root)
    end

    it_isolated 'can load the service' do
      Thrifty.register('_lib/thrift/service.thrift',
        relative_to: __FILE__,
        build_root: '_lib/thrift/build')
      Thrifty.require('user_storage')
      ThriftyTest::UserStorage

      assert(File.exists?(@build_root), "Build root #{@build_root} does not exist")
    end

    it_isolated 'builds a given thrift file once' do
      Thrifty.register('_lib/thrift/service.thrift',
        relative_to: __FILE__,
        build_root: '_lib/thrift/build')
      results = Thrifty.compile_all
      assert_equal(1, results.length)
      assert(results.all? {|_, built| built})

      results = Thrifty.compile_all
      assert_equal(1, results.length)
      assert(results.none? {|_, built| built})
    end
  end
end
