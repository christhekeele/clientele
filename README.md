Clientele
=========

> *An simple, structured, HTTP client adapter library.*



Design
------

Clientele is a simple ruby HTTP library that's easy to configure, extend, and build other libraries off of.

It's inspired by Faraday and Hurley, with a few extra design goals.

It represents all components of HTTP calls with plain-old ruby value objects. This makes it easy to add behavior the Ruby way, and translate between low and high level HTTP adapters.

It does most mutation on object initialization, to minimize potentially invalid states and be somewhat thread-safe without being clever.

It uses dependency injection heavily, so that objects can be reused often and tested simply.

The main Clientele classes you'll work with are Clients, Requests, and Responses. They're supported by Configurations, Adapters, and Pipelines.

- `Client`: An object that manages configuration and makes requests off of it.
- `Request`: An object with the minimal data needed to make a request.
- `Response`: An object with the minimal data needed to represent a response.

- `Configuration`: An object with the required fields needed to configure a client, sane defaults, and high user-extensiblity.
- `Adapter`: An HTTP Adapter that actually does the work of getting a response from a request.
- `Pipeline`: A functional set of transformations that can manipulate request and response objects before and after passing through an adapter.


Usage
-----

### Quick Start

Clientele will create clients on the fly for quick usage:

```ruby
Clientele.get('https://example.com')
#=> #<struct Clientele::Response
#>    status=#<Clientele::HTTP::Status:0x7fbfed08b3a8 - 200: OK>,
#>    headers=#<Clientele::HTTP::Headers:0x7fbfed08b330
#>      Connection: close
#>      Content-Length: 606
#>      Content-Type: text/html
#>      Date: Wed, 03 Feb 2016 21:11:24 GMT
#>      ...
#>    >,
#>    body=#<Clientele::HTTP::Response::Body:0x007fbfee9a0d70 @body="<!doctype html><html..."
#>  >

# Non-standard verb:

Clientele::Client.call(:foobar, 'https://example.com')
#=> #<struct Clientele::Response
#>    status=#<Clientele::HTTP::Status:0x7fbae62693c0 - 501: Not Implemented>,
#>    headers=#<Clientele::HTTP::Headers:0x7fbae6269398
#>      Connection: close
#>      Content-Length: 357
#>      Content-Type: text/html
#>      Date: Wed, 03 Feb 2016 21:32:02 GMT
#>      ...
#>    >,
#>    body=#<Clientele::HTTP::Response::Body:0x007fbae450d8f8 @body="<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n<!DOCTYPE html..."
#>  >

# Available standard verbs:
Clientele::HTTP::Verb.methods
#=> [:DELETE, :GET, :HEAD, :OPTIONS, :PATCH, :POST, :PUT, :TRACE]
```

### Client Usage

Generally though, you'll want to create a dedicated client to make requests from:

```ruby
# Shortcut to get instance: Clientele.client(root: 'https://example.com')

client = Clientele::Client.new(root: 'https://example.com')
#=> #<Clientele::Client:0x007fe41b90f180
#>    @configuration=#<Clientele::Client::Configuration:0x007fe41b90f158
#>       @adapter=Clientele::Adapters::NetHTTP...
#>     >
#>   >

# Shortcut to perform request: client.get(path: 'foo/bar/baz', headers: {'Accept' => 'text/plain;'})

request = client.request(verb: :get, path: 'foo/bar/baz', headers: {'Accept' => 'text/plain;'})
#=> #<struct Clientele::Request
#>    verb=#<Clientele::HTTP::Verb:0x7fab93fe7270 - GET>,
#>    uri=#<Clientele::HTTP::URI:0x7fab93ecb440 - https://example.com/foo/bar/baz>,
#>    headers=#<Clientele::HTTP::Headers:0x7fab93ecb0d0
#>      Accept: text/plain;
#>    >,
#>    body=#<Clientele::HTTP::Request::Body:0x007fab93ecafe0 @content=nil>
#>   >

client.call request
#=> #<struct Clientele::Response
#>    status=#<Clientele::HTTP::Status:0x7fab9446c200 - 404: Not Found>,
#>    headers=#<Clientele::HTTP::Headers:0x7fab93cebd78
#>     Cache-Control: max-age=604800
#>     Content-Type: text/html
#>     Date: Wed, 03 Feb 2016 22:42:52 GMT
#>     ETag: "359670651+gzip"
#>     Expires: Wed, 10 Feb 2016 22:42:52 GMT
#>     Last-Modified: Fri, 09 Aug 2013 23:54:35 GMT
#>     Server: ECS (oxr/83C7)
#>     Vary: Accept-Encoding
#>     X-Cache: HIT
#>     X-Ec-Custom-Error: 1
#>     Content-Length: 606
#>     Connection: close
#>    >,
#>    body=#<Clientele::HTTP::Response::Body:0x007fab93c8b108
#>      @body="<!doctype html>\n<html>...""
#>    >
#>   >
```

### Client Configuration

A root URI is the only required configuration. You can set several extra options though, or define your own:

```ruby
client = Clientele::Client.new do |config|
  config.root    = 'https://example.com'
  config.timeout = 10 # seconds. Default: false
  config.logger  = Rails.logger # Default: Logger.new($stdout)

  config.adapter  = Proc.new # Described below. Default: Clientele::Adapters::NetHTTP
  config.pipeline = Proc.new # Described below. Default: config.adapter

  config.custom = "value"
end

client.config.custom
#=> "value"
```

If you make extensive use of custom configuration or need advanced default values, it's recommended you subclass the Configuration class:

```ruby
# Or use Clientele::Configuration for a totally blank slate
class CustomConfiguration < Clientele::Client::Configuration

  # Custom setup
  def initialize
    super
    @custom = :value
  end

  # Custom assignment
  def custom= value
    @custom = value.to_sym
  end

  # Custom reader
  attr_reader :custom

  def configure(**options, &block)
    # This method takes an options hash, and calls
    # self.key= value for each item, then yields itself
    # into the block where block configuration can take place.
    # It's recommended to leave this method alone, but now
    # you know how this object works.
    super
  end

end
```

Custom Configuration classes can be used as a single positional argument when instantiating a client:

```ruby
client = Clientele.client(root: 'https://example.com', custom: 'value')
client.config.class
#=> Clientele::Client::Configuration
client.config.root
#=> #<Clientele::HTTP::URI:0x7f8b15cbadc0 - https://example.com>
client.config.custom
#=> 'value'

client = Clientele.client(CustomConfiguration, root: 'https://example.com', custom: 'value')
client.config.class
#=> CustomConfiguration
client.config.root
#=> #<Clientele::HTTP::URI:0x7f8b15cbadc0 - https://example.com>
client.config.custom
#=> :value
```

### Client Adapters

Adapters are any Ruby object that responds to `call`. They take a single `Clientele::Request` object and return a `Clientele::Response`.

Currently Clientele comes with batteries out-of-the-box: a default `Clientele::Adapters::NetHTTP` that uses Ruby's builtin 'net/http' library. We intend to support more down the line.

If you decide to compose your own, take a look at the `Clientele::Adapters::NetHTTP` implementation and the 'clientele/http' library to see the value objects and their predicate methods that Clientele uses under the hood. We'd love pull requests in this arena.

You can use them in your configuration as follows:

```ruby
Clientele.client(root: 'https://example.com') do |config|

  # Use simple symbol from `Clientele::Adapter.keys`
  config.adapter = :net_http
# OR
  # Use existing class namespaced under `Clientele::Adapters`
  config.adapter = Clientele::Adapters::NetHTTP
# OR
  # Use custom lambda implementation
  config.adapter = -> request do
    generate_clientele_response_from_clientele_request(request)
  end
# OR
  # Custom implementation inline
  config.adapter do |request|
    generate_clientele_response_from_clientele_request(request)
  end

end
```

### Client Pipelines

Pipelines are the way Clientele transforms requests and responses, similar to Faraday's middleware or Hurley's callbacks.

They're a simple collection of 'transforms'–objects that respond to `call` and accept a single argument. They have three stacks of transforms: before, around, and after transforms.

You can use them in your configuration as follows:

```ruby
Clientele.client(root: 'https://example.com') do |config|

  # Inline definition
  config.pipeline do
    before(list, of, transforms)
    around(list, of, transforms)
    after(list, of, transforms)
  end

  # Same as:

  custom_pipeline = Pipeline.new do
    before(list, of, transforms)
    around(list, of, transforms)
    after(list, of, transforms)
  end

  # assign an existing pipeline
  config.pipeline = custom_pipeline

end
```

Pipelines allow you create a series of functional transforms to an object.

Before transforms should take a single object and return it. They run in the order supplied:

```ruby
pipeline = Clientele::Pipeline.new

before1 = -> string do
  puts "in first before transform"
  string.upcase
end
before2 = -> string do
  puts "in second before transform"
  string + 'bar'
end
pipeline.before(before1, before2)

# To launch a pipeline, give it a starting object and it will be transformed:
pipeline.call("foo")
#:> in first before transform
#:> in second before transform
#=> "FOObar"
```

After transforms work similarly, but in the reverse order supplied.

```ruby
pipeline = Clientele::Pipeline.new

after1 = -> string do
  puts "in first after transform"
  '!' + string + '!'
end
after2 = -> string do
  puts "in second after transform"
  string + 'buzz'
end
pipeline.after(after1, after2)

pipeline.call("fizz")
#:> in second after transform
#:> in first after transform
#=> "!fizzbuzz!"
```

When you run a pipeline, you can pass it an optional transform to invoke in the middle of it. In clientele, this is your `config.adapter`, that takes a request and returns a response.

In this example, we expect a string and return a symbol.

```ruby
middle = -> string { string.to_sym }
middle.call("foo") #=> :foo

pipeline = Clientele::Pipeline.new do

  before(-> string do
    string + string.reverse.upcase
  end)

  after( -> symbol do
    symbol.swapcase
  end)

end

pipeline.call("foo", &middle)
#=> :FOOoof
```

Around transforms run in the order supplied, like before transforms, but must yield so that other around transforms and the middle transformation can be applied:

```ruby
require 'tempfile'

module TempfileManager
  class << self
    def call(path)
      file = Tempfile.new path
      yield file
      file.unlink
    end
  end
end

module FileManager
  class << self
    def call(file)
      file.open
      yield file
      file.close
    end
  end
end

pipeline = Clientele::Pipeline.new

pipeline.around(TempfileManager, FileManager)

pipeline.call("myfile") do |file|
  file.write "stuff"
end
#=> #<File:/var/folders/9w/mmrrtvd54nd5z0vl782ngwrh0000gn/T/myfile20160204-4307-1h57xvt (closed)>
```

Finally, if any step of the pipeline returns `nil`, the pipeline is aborted:

```ruby
cancel = -> o do
  puts "cancelling..."
  nil
end
before_transform = -> o do
  puts "in before"
  o
end
around_transform = -> o, &continue do
  puts "in around"
  continue.call o
end
after_transform = -> o do
  puts "in after"
  o
end

Clientele::Pipeline.new do
  before(cancel)
  around(around_transform)
  after(after_transform)
end.call(:object)
#:> cancelling...
#=> nil

Clientele::Pipeline.new do
  before(before_transform)
  around(cancel)
  after(after_transform)
end.call(:object)
#:> in before
#:> cancelling...
#=> nil

Clientele::Pipeline.new do
  before(before_transform)
  around(around_transform)
  after(cancel)
end.call(:object)
#:> in before
#:> in around
#:> cancelling...
#=> nil
```
