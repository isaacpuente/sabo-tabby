# Sabo Tabby

[JSON:API](http://jsonapi.org/) serializer for Ruby Objects.

# Table of Contents

* [Installation](#installation)
* [Features](#features)
* [Usage](#usage)
  * [Object Definition](#object-definition)
  * [Mapper Definition](#mapper-definition)
  * [Object Serialization](#object-serialization)
  * [Compound Document](#compound-document)
  * [Collection Serialization](#collection-serialization)
  * [Errors](#errors)
  * [Pagination](#pagination)
  * [Auto compound](#auto-compound)
  * [Params](#params)
  * [Sparse Fieldsets](#sparse-fieldsets)
* [Contributing](#contributing)


## Features

* Mapper type determined based on class name
* Support for `many` and `one` relationships
* Support for compound documents (included)
* Support for error documents (errors)
* Support for pagination
* Auto compound feature, define in mapper which relationship to include in compound documents

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sabo-tabby'
```

Execute:

```bash
$ bundle install
```

## Usage

### Object Definition

```ruby
class Cat
  attr_accessor :id, :name, :, :actor_ids, :owner_id, :movie_type_id
end
```

### Serializer Definition

```ruby
class MovieMapper
  include SaboTabby::Mapper
  set_type :movie  # optional
  set_id :owner_id # optional
  attributes :name, :year
  has_many :actors
  belongs_to :owner, record_type: :user
  belongs_to :movie_type
end
```
