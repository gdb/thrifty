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

## Caveats

You must have a working thrift compiler on your PATH. (That is, you
should be able to just type 'thrift'.) Thrifty does not currently
statically check that this is the case.

## TODO

- Add a precompile mode, similar to how the Rails asset pipeline
  works.
- Statically ensure there's a thrift compiler on the PATH.
- Autorequire of all generated Thrift files?
