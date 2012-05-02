## Integration branch

I have continued to track Wilker's original `master` in hopes that we can merge
them some day -- we initially had some differences of opinion and I maintained
this fork for my own needs as well as pulling in a few ideas from forks. Changes
on this fork are noted here, with backwards-incompatible changes emphasized.

### Features

- Ability to pass map/reduce options to the Mongo driver for the aggregation
  feature ([andresf][])
- Tag aggregation can be called on-demand when it is not enabled to run
  automatically with callbacks ([adkron][])
- Options given to the `taggable` macro that don't apply to the plugin are
  passed to the Mongoid `field` definition ([ches][])
- Tag de-duplication (probably ought to just use Set...) (Wei Kong @
  [cocoafish][])
- More robust parsing of tags from string input ([fagiani][])
- **Consolidation of `tags` and `tags_array` instance methods**. This is the
  primary API wart I wanted to change -- the `tags` accessor (or whatever custom
  field name you use) always returns an Array, and if a String is given to the
  setter it is tokenized and stored as an Array. ([ches][])
- Field name for tags can be specified explicitly, instead of being forced as
  `tags` ([ches][])
- Tag "indexing" feature renamed to "aggregation" **and disabled by default**.
  This seems a more accurate named for map/reduce tag counting. ([ches][])
- **Use `taggable` macro method to invoke the plugin's behavior on a model**,
  allowing plugin options to passed in one sensible place ([ches][])
- Spec suite isolated from needing a sample app ([ches][])
- Use ActiveSupport::Concern in the style of Mongoid 2.x ([ches][])
- `tagged_with` class method to find records by an Array or String of tags
  ([petRUShka][])
- Drop use of Jeweler, use Bundler ([ches][])


### Bug Fixes

- Rails 3.1 deprecation and gemspec warning fixes ([JangoSteve][])
- Aggregation skipping fixed for Mongoid 2.1's switch to ActiveModel-compliant
  dirty tracking ([ches][])
- Map/reduce aggregation isn't run on record save if tags weren't changed
  ([ches][])


## 0.1.1 - 26 July, 2010

Wilker's last official gem release before this fork.


[andresf]: https://github.com/andresf
[JangoSteve]: https://github.com/JangoSteve
[adkron]: https://github.com/adkron
[ches]: https://github.com/ches
[cocoafish]: https://github.com/cocoafish
[fagiani]: https://github.com/fagiani
[petRUShka]: https://github.com/petRUShka

