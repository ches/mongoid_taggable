Mongoid Taggable
================

Mongoid Taggable provides some helpers to create taggable documents. Changes on
this fork are noted in the `CHANGELOG` file.

Installation
------------

You can simply install from rubygems:

    gem install mongoid_taggable

or in `Gemfile`:

    gem 'mongoid_taggable'

or as a Rails Plugin:

    rails plugin install git://github.com/wilkerlucio/mongoid_taggable.git

Basic Usage
-----------

To make a document taggable you need to include `Mongoid::Taggable` into your document and call the `taggable` macro with optional arguments:

```ruby
class Post
  include Mongoid::Document
  include Mongoid::Taggable
  
  field :title
  field :content
  
  taggable
end
```

Then in your form, for example:

```rhtml
<% form_for @post do |f| %>
  <p>
    <%= f.label :title %><br />
    <%= f.text_field :title %>
  </p>
  <p>
    <%= f.label :content %><br />
    <%= f.text_area :content %>
  </p>
  <p>
    <%= f.label :tags %><br />
    <%= text_field_tag 'post[tags]', (@post.tags.join(', ') if @post.tags) %>
  </p>
  <p>
    <button type="submit">Send</button>
  </p>
<% end %>
```

You can of course use helpers or a `FormBuilder` extension to express this in a prettier way. If you're using SimpleForm for example, a custom input can be found in [this Gist](https://gist.github.com/1172956), usable as `f.input :tags` within `simple_form_for` blocks. The text field should receive a list of tags separated by comma (below in this document you will see how to change the separator).

Your document will have a custom `tags=` setter which can accept either an ordinary Array or this separator-delineated String.

Tag Aggregation with Counts
---------------------------

This lib can automatically create an aggregate collection of tags and their counts for you, updated as documents are saved. This is useful for getting a list of all tags used in documents of this collection or to create a tag cloud. This is disabled by default for sake of performance where it is unneeded -- see the following example to understand how to use it:

```ruby
class Post
  include Mongoid::Document
  include Mongoid::Taggable

  field :title
  field :content

  taggable :aggregation => true
end

Post.create!(:tags => "food,ant,bee")
Post.create!(:tags => "juice,food,bee,zip")
Post.create!(:tags => "honey,strip,food")

Post.tags
# => ["ant", "bee", "food", "honey", "juice", "strip", "zip"]

Post.tags_with_weight # will retrieve:
# [
#   ['ant', 1],
#   ['bee', 2],
#   ['food', 3],
#   ['honey', 1],
#   ['juice', 1],
#   ['strip', 1],
#   ['zip', 1]
# ]
```

You may also trigger aggregation on-demand rather than setting the automatic option, to run it from a background task for instance, by calling `Post.aggregate_tags!`.

If you need to modify the criteria used for the aggregation you may do so as an option to 'taggable':

```ruby
class Post
  include Mongoid::Document
  include Mongoid::Taggable
  
  field :title
  field :content
  field :published, :type => Boolean
  
  taggable :aggregation_options => { :query => { :published => true } }
end
```

A full list of available options can be found at [the ruby driver API](http://api.mongodb.org/ruby/current/Mongo/Collection.html#map_reduce-instance_method) (consult the appropriate version).

Changing default separator
--------------------------

To change the default separator you may pass a `separator` argument to the macro:

```ruby
class Post
  include Mongoid::Document
  include Mongoid::Taggable

  field :title
  field :content

  taggable :separator => ' '    # tags will be delineated by spaces
end
```

### TODO: ###

* Should subclasses output map/reduce aggregation results to their own collections?
* Perhaps implement operators, <<, etc. for full-on set semantics. See:
    https://github.com/mlabs/mongoid_taggable/commit/13195805e110a7113b9f04710d9bade39440b63e

