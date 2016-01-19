Clientele
=========

> *Create Ruby API clients with ease.*



Usage
-----

Clientele makes it easy to create feature-rich ruby API clients with minimal boilerplate.

In this example, we'll be making an API client for our popular new service at example.com.


### Creating an API Client

Since we'll be distributing this client as a gem, we'll use bundler to get our boilerplate code set up:

```bash
bundle gem example-api
cd example-api
```

Next we'll add `clientele` as a dependency to our gemspec.

```ruby
# example-api.gemspec

Gem::Specification.new do |spec|

# ...

  spec.add_dependency 'clientele'

# ...

end
```

Then install `clientele`.

```bash
bundle install
```

Finally, we can create our simple API Client class.

```ruby
# lib/example/api.rb

require 'clientele'

module Example
  class API < Clientele::API

  end
end
```


### Using API Clients

Now that we have a client class, we can construct requests off of it to our API by providing the anatomy of an HTTP request.

#### Initializing a Client

Creating a client instance is as simple as passing in any configuration options into `new`. We'll make requests off of these client instances.

```ruby
client = Example::API.new(root_url: 'http://example.com')
```

Alternatively, you can use the `client` method to lazily initialize and access a global API client if you're not concerned about thread safety, or just experimenting with an API.

```ruby
# Return client with default configuration
Example::API.client
#=> #<Example::API:0x007f85faa16468>

# Configure/reconfigure and return global client
Example::API.client(root_url: 'http://example.com')
#=> #<Example::API:0x007f85faa16468>
```

Future calls to `client` will use this configured instance. Passing options into it will reconfigure this global client.

Finally, any unknown method calls on the client class attempt to see if the global client instance responds to them.

```ruby
Example::API.foo
# will return the result of
Example::API.client.foo
# provided the client responds to foo.
```

#### Configuring Clients

API client classes are highly configurable. The only required parameter to use your client is the `root_url` we saw above on initialization. We can configure our API with a default root_url and omit it on initialization in the future.

```ruby
# lib/example/api.rb

require 'clientele'

module Example
  class API < Clientele::API
    configure do |config|
      config.root_url = "http://example.com/"
    end
  end
end
```

This default configuration can be overridden by passing a hash of options as seen above. Other configuration options and their default values are discussed below.


#### Building Requests on Client Instances

The simplest way to make requests is to call the HTTP verb you want on your client, passing in a hash with everything you need to in the request. For the rest of these examples we'll be using the global client rather than initialize a new one each time.

```ruby
request = Example::API.get(path: 'foo')
#=> #<struct Clientele::Request>
```

Clients respond to any of the HTTP verbs found in `Clientele::Request::VERBS`. The resulting request can be triggered with `call`, as if a Proc.

```ruby
response = Example::API.get(path: 'foo').call
#=> #<Faraday::Response>
```

Unlike other options, you can provide path as a direct argument rather than a keyword one.

```ruby
Example::API.get(path: 'foo', query: {bar: :baz})
# is the same as
Example::API.get('foo', query: {bar: :baz})
# and corresponds to GET http://example.com/foo?bar=baz
```

The options used to construct a request are:

Option | Default | Description
------------------------------
path | `''` | The url path to build off of `root_url`.
query | `{}` | A hash of query string parameters.
body | `{}` | A hash representing the request payload.
headers | `client.configuration.default_headers` | A hash representing the request headers. Supplying your own will merge in with the default headers set on the client instance, overriding already defined ones.
callback | `nil` | An optional callback `Proc` to pass the response into. If the request constructor receives a block, it will use that as a callback.

Of course, all these features amount to at this point is an idiomatic Ruby HTTP Library. The power of `clientele` comes from defining resources your API contains.


### Creating Resources

Resources inherit from `Clientele::Resource` and map to namespaced endpoints of an API that deal with similar datatypes, as is found often in RESTful APIs.

```ruby
# lib/example/api/resources/foo.rb

module Example
  class API < Clientele::API
    module Resources
      class Foo < Clientele::Resource

      end
    end
  end
end
```

Resource classes can be placed anywhere under any namespace, because they're registered with your API Client by hand using the `resource` directive. Ours is just an example namespace.

```ruby
# lib/example/api.rb

require "clientele"
require "example/api/resources/foo"

module Example
  class API < Clientele::API

    configure do |config|
      config.root_url = "http://example.com/"
    end

    resource Resources::Foo
  end
end
```

Registering this resource on the client allows it to be invoked as a method.

```ruby
Example::API.foos
#=> #<Clientele::RequestBuilder>
```

Calling this request will send a `GET` request to `http://example.com/foos` with default headers and no query string parameters.

### Customizing Resources

Using the request builder API, we can define class methods on the resource that accomplish any HTTP request. If we provide a path it will be appended to the resource's path (ie. `'foos/path'`); otherwise it will send the request to the resource root. For instance, to get an ActiveRecord-inspired request DSL:

```ruby
# lib/example/api/resources/foo.rb

module Example
  class API < Clientele::API
    module Resources
      class Foo < Clientele::Resource

        class << self

          def all(&callback)
            get &callback
          end

          def where(query={}, &callback)
            get query: query, &callback
          end

          def create(body={}, &callback)
            post body: body, &callback
          end

          def fetch(id, query={}, &callback)
            get id, query: query, &callback
          end

          def update(id, body={}, &callback)
            patch id, body: body, &callback
          end

          def destroy(id, &callback)
            delete id, &callback
          end

        end

      end
    end
  end
end
```


### Using Resources

Introduction

#### Making Requests to Resources

#### Making Asyncronous Requests

#### Chaining Resource Requests

#### Iterating Across Paginated Resources


### Configuration

`Clientele::API` instances each have their own configuration that they receive from a class-level configuration object. Both the class level and instance level configurations can be customized on demand by you, the API client developer, or consumers of your client.

#### Configuration Options and Their Defaults

```ruby
# lib/example/api.rb

require 'clientele'

module Example
  class API < Clientele::API
    configure do |config|
      # Required at some point during initialization
      config.root_url = "http://example.com/"

      # Logger to use
      config.logger                = Logger.new($stdout)
      # Faraday adapter to use
      config.adapter               = Faraday.default_adapter
      # Default headers to inject into every request
      config.headers               = {}
      # Regex that Content-Type header must match to trigger
      # automatic conversion of responses into hashes
      # (behaviour can be disabled in `connection` option
      # as well as a never-matching regex like /$^/)
      config.hashify_content_type  = /\bjson$/
      # Whether or not to follow redirects
      config.follow_redirects      = true
      # Max redirects to follow in a row
      config.redirect_limit        = 5
      # Force trailing slashes when appropriate
      config.ensure_trailing_slash = true

      # Faraday connection Proc to use.
      config.connection            = default_connection

      # Default connection Proc
      def config.default_connection
        Proc.new do |conn, options|

          conn.use FaradayMiddleware::FollowRedirects, limit: options[:redirect_limit] if options[:follow_redirects]

          conn.request  :url_encoded

          conn.response :logger, options[:logger], bodies: true
          conn.response :json, content_type: options[:hashify_content_type], preserve_raw: true

          conn.options.params_encoder = options[:params_encoder] if options[:params_encoder]

          yield(conn, options) if block_given?

          conn.adapter options[:adapter] if options[:adapter]

        end
      end

    end
  end
end
```

#### Default Library Configuration

To override `clientele`'s default options within your library, use the `configure` class method on your API client. You'll probably want to do this for at least the `root_url` option since it has no default.

```ruby
#lib/example/api.rb
require 'clientele'

module Example
  class API < Clientele::API

    configure do |config|

      # Required options
      config.root_url = "http://example.com"

      # Optional overrides
      config.headers = {
        'Accept'       => 'application/json',
        'Content-Type' => 'application/json',
      }
      # must add 'net-http-persistent' to gemspec to use:
      config.adapter = :net_http_peristent

      # Custom configuration values
      config.custom = :foobar

    end

  end
end
```

#### Default User Configuration

Users of your API Client can also access the class level `configure` method to change default configuration options within their project. This should be done early on in the script, library loading stage, or boot process so it can take effect before any clients are instanciated.

Rails users would put this in an initializer.

```ruby
#my_app/config/initializers/example-api.rb
require 'example/api'

Example::API.configure do |config|
  config.root_url = 'http://dev.example.com'
  config.logger   = Rails.logger
end
```

#### Initialization Configuration

Finally, all these options can be overridden on client initialization using their logical symbol names in the hash to `new`:

```ruby
require 'example/api'

client = Example::API.new(root_url: 'http://dev.example.com', logger: Rails.logger)
```


Contributing
------------

1. Fork it ( https://github.com/[my-github-username]/clientele/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
