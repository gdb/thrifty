require_relative '_lib'
require 'fileutils'
require 'thrifty'
require 'chalk-tools'

# TODO: can we get by without quite so much rm -rf'ing?

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

    it_isolated 'build_root defaults to the thrift/thrifty directory' do
      expected_root = File.expand_path('../_lib/thrift/thrifty', __FILE__)
      FileUtils.rm_rf(expected_root)

      Thrifty.register('_lib/thrift/service.thrift', relative_to: __FILE__)
      Thrifty.require('user_storage')
      ThriftyTest::UserStorage

      assert(File.exists?(expected_root))
    end

    describe 'without relative_to' do
      it_isolated 'build_root defaults to Dir.tmpdir/thrifty' do
        expected_root = File.join(Dir.tmpdir, 'thrifty')
        FileUtils.rm_rf(expected_root)

        Thrifty.register(File.expand_path('../_lib/thrift/service.thrift', __FILE__))
        Thrifty.require('user_storage')
        ThriftyTest::UserStorage

        assert(File.exists?(expected_root))
      end
    end
  end

  describe 'with a build_root' do
    before do
      @build_root = File.expand_path('../_lib/thrift/thrifty', __FILE__)
      FileUtils.rm_rf(@build_root)
    end

    it_isolated 'raises an error if the thrift file does not exist' do
      assert_raises(RuntimeError) do
        Thrifty.register('_lib/thrift/nonexistent.thrift',
          relative_to: __FILE__,
          build_root: '_lib/thrift/thrifty')
      end
    end

    it_isolated 'sets paths appropriately' do
      thrift_file = Thrifty.register('_lib/thrift/service.thrift',
        relative_to: __FILE__,
        build_root: '_lib/thrift/thrifty')
      assert_equal(File.expand_path('../_lib/thrift/service.thrift', __FILE__),
        thrift_file.path)
      assert_equal(File.expand_path('../_lib/thrift/thrifty', __FILE__), thrift_file.build_root)
    end

    it_isolated 'can load the service' do
      Thrifty.register('_lib/thrift/service.thrift',
        relative_to: __FILE__,
        build_root: '_lib/thrift/thrifty')
      Thrifty.require('user_storage')
      ThriftyTest::UserStorage

      assert(File.exists?(@build_root), "Build root #{@build_root} does not exist")
    end

    it_isolated 'builds a given thrift file once' do
      Thrifty.register('_lib/thrift/service.thrift',
        relative_to: __FILE__,
        build_root: '_lib/thrift/thrifty')
      results = Thrifty.compile_all
      assert_equal(1, results.length)
      assert(results.all? {|_, built| built})

      results = Thrifty.compile_all
      assert_equal(1, results.length)
      assert(results.none? {|_, built| built})
    end
  end
end
