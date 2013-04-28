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

## TODO

- Add a precompile mode, similar to how the Rails asset pipeline
  works.
