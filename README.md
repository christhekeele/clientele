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

Finally, we can create our API Client class. We must configure it with a url to use as the base of our API.

```ruby
# lib/example/api.rb

require 'clientele'

module Example
  class API < Clientele::API

  end
end
```


### Making Requests

Now that we have a client class, we can construct requests off of it to our API by providing the anatomy of an HTTP request.

#### Initializing a Client

Creating a client instance is as simple as passing in any configuration options into `new`. See the Configuration section for more options.

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

Finally, any unknown method calls on the client class attempt to see if the global client responds to them.

```ruby
Example::API.foo
# will return the result of
Example::API.client.foo
# provided the client responds to foo.
```

#### Building Requests on Client Instances

The simplest way to make requests is to call the HTTP verb you want on your client, passing in a hash with everything you need to in the request. For the rest of these examples we'll be using the global client.

```ruby
request = Example::API.get(path: 'foo')
#=> #<struct Clientele::Request>
```

Clients respond to any of the HTTP verbs found in `Clientele::Request::VERBS`. The resulting request can be triggered with `call` as if a Proc.

```ruby
response = Example::API.get(path: 'foo').call
#=> #<Faraday::Response>
```

Unlike other options, you can provide path as a direct argument rather than a keyword one.

```ruby
Example::API.get(path: 'foo', query: {bar: :baz})
# is the same as
Example::API.get('foo', query: {bar: :baz})
```

The options used to construct a request are:

Option | Default | Description
------------------------------
path | `''` | The url path to build off of `root_url`.
query | `{}` | A hash of query string parameters.
body | `{}` | A hash representing the request payload.
headers | `client.configuration.default_headers` | A hash representing the request headers.
callback | `nil` | An optional callback `Proc` to pass the response into. If the request constructor receives a block, it will use that as a callback.

In actuality, these methods will instead return `Clientele::RequestBuilder` instances with your defined request inside. Regardless, the `call` method will invoke them the same.

Of course, all these features amount to at this point is a verbose HTTP Library. The power of `clientele` comes from using these components to define resources.


### Creating Resources

Resources inherit from `Clientele::Resource` and map to namespaced endpoints of an API that deal with similar datatypes, as is found often in RESTful APIs.

```ruby
# lib/example/api/resources.rb

require 'example/api/resources/foo`
```

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

```ruby
# lib/example/api.rb

require 'lib/example/api/resources'

module Example
  class API < Clientele::API

  # ...

    resource Resources::Foo

  # ...

  end
end
```

Registering this resource on the client allows it to be invoked as a method.

```ruby
Example::API.foos
#=> #<Clientele::RequestBuilder>
```

Calling this request will send a `GET` request to `http://example.com/foos' with default headers and no query string parameters.

Using the request builder API, we can define class methods on the resource that accomplish any HTTP request. If we provide a path it will be appended to the resource's path (ie. `'foo/path'`); otherwise it will send the request to the resource root. For instance, to get an ActiveRecord-inspired request DSL:

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

#### Configuration Options

Option | Default | Description
------------------------------
root_url | Required | The root url against which all requests are made.
logger | `Logger.new($stdout)` | The logger for `clientele` to use.
adapter | `Faraday.default_adapter` | The `faraday` adapter to use.
headers | `{}` | Headers to use with every request.
hashify_content_type | /\bjson$/ | A regex `faraday` applies to response content types to determine whether or not to try to convert the payload into a hash.
follow_redirects | `true` | Whether or not to follow redirects.
redirect_limit | `5` | How deep to follow redirects.

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

You'll probably want to include the table above, alongside any modifications or additions, in your client's documentation.

#### Default User Configuration

Users of your API Client can also access the class level `configure` method to change default configuration options within their project. This should be done early on in the script, library loading stage, or boot process so it can take effect before any clients are instanciated.

Rails users would put this in an initializer.

```ruby
#my_app/config/initializers/example-api.rb
require 'example/api'

Example::API.configure do |config|
  config.root_url = 'http://dev.example.com'
end
```

You may also wish to document how to do this in your gem.



Contributing
------------

1. Fork it ( https://github.com/[my-github-username]/clientele/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
