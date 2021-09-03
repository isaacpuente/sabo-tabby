# Sabo Tabby

[JSON:API](http://jsonapi.org/) serializer for Ruby Objects.

# Table of Contents

* [Quickstart](#quickstart)
* [Usage](#usage)
  * [Mapper](#mapper)
  * [Compound Document](#compound-document)
  * [Collection Serialization](#collection-serialization)
  * [Sparse Fieldsets](#sparse-fieldsets)
  * [Links](#links)
  * [Options](#options)
  * [Pagination](#pagination)
  * [Auto compound](#auto-compound)
  * [Errors](#errors)
* [Contributing](#contributing)


## Quickstart

Add following to your application's Gemfile:

```ruby
gem 'sabo-tabby'
```

Execute:

```bash
$ bundle install
```

Resource can be any Ruby object

```ruby
class Role
  attr_accessor :id, :name, :permissions

  def initialize(id, name, permissions)
    @id = id
    @name = name,
    @permissions = permissions
  end
end
```

Mapper

```ruby
class RoleMapper
  include SaboTabby::Mapper

  resource :role do
    attributes :name, :permissions
  end
end
```

Serialization

```ruby
admin = Role.new(1, :admin, %i(:read, :write, :delete))

SaboTabby::Serialize.new(admin).as_json
```



## Features

* Mapper type determined based on class name
* Support for `many` and `one` relationships
* Support for compound documents (included)
* Support for error documents (errors)
* Support for pagination
* Auto compound feature, define in mapper which relationship to include in compound documents


