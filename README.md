# Thrifty

Tired of manually regenerating your Thrift interface code every time
the definition changes? Thrifty manages your Thrift interface
definitions behind the scenes.

## Usage

```ruby
require 'thrifty'
Thrifty.register('my_interface.thrift')

Thrifty.require('generated_service')
GeneratedService.do_things
```

See the examples directory for a complete working example.

## Precompiling

When using Thrifty in production, you'll likely want to precompile
your Thrift IDLs. The way I'd recommend doing this is as follows:

In `lib/myapp/thrift.rb`:

```ruby
require 'thrifty'
Thrifty.register('my_interface.thrift', relative_to: __FILE__, build_root: 'build')
```

Your build step will then just be:

```ruby
require 'myapp/thrift'
Thrifty.compile_all
```

## Caveats

You must have a working thrift compiler on your PATH. (That is, you
should be able to just type 'thrift'.) Thrifty does not currently
statically check that this is the case.

## TODO

- Statically ensure there's a thrift compiler on the PATH.
- Autorequire of all generated Thrift files?
