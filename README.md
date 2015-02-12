# ActiveadminPolymorphic

Activeadmin Polymorphic gem is made to bring has_many polymorphic nested forms into your ActiveAdmin. ActiveAdmin users formtastic to build awesome forms, but formatstic itself doesn't support polymorphic relations. `activeadmin_polymorphic` gem is trying to solve that problem.

![](https://s3.amazonaws.com/f.cl.ly/items/0b2F2t2R3D0o1O3F1R3e/Screen%20Shot%202015-02-05%20at%2012.57.04.png)

# Features

* polymorphic forms
* validation
* sortable behaviour
* file uploads

# Installation

Add this to your Gemfile:

``` ruby
gem "activeadmin_polymorphic"
```

and run `bundle install`.

Include assets in JS and CSS manifests

JS:
```
#= require activeadmin_polymorphic
```

CSS:
```
@import "activeadmin_polymorphic";
```

# Usage

To use the gem, your model should have a related model, which works as a proxy to polymorphic relations.

![](https://s3.amazonaws.com/f.cl.ly/items/2Z3M2V0b3Z342L2Z2R0N/Screen%20Shot%202015-02-05%20at%2013.37.36.png)

The gem extends activeadmin's form builder, so to enable the `has_many_polymorphic` method you need to override form builder using the `builder` option:

```
...
SECTIONABLES = [Image, Text]

form builder: ActiveadminPolymorphic::FormBuilder do |f|
  f.polymorphic_has_many :sections, :sectionable, types: SECTIONABLES
end
...
```

There are few options available:
* first option, the name of polymorphic has_many association
* second option, referes to polymorphied version of an association name (sectionable_id and sectaionable_type for example)
* `types` - list of related models you want to use
* `allow_destroy` - whether or not to allow destroying related objects
* `sortable` - enables drag'n'drop for nested forms, accepts sortable column name, for example `sortable: :priority`

Subforms for polymorphic relations are forms which you define in your ActiveAdmin. The gem fetches and submits them using some ajax magic.

# Under the hood

This gem is a set of dirty hacks and tricks. Calling `polymorphic_has_many` makes it do the following things:

* for new records it generates a dropdown with polymorphic types
* for exising records it generates two hidden fields with `id` and `type`
* then the real JavaScript starts, it extracts whole forms from polymorphic models new or edit pages, strips form actions, and inserts those forms right into the parent form
* when you try to submit forms, JavaScript submits subforms first; if subforms are invalid, it reloads them with erros and interupts the main form's submission process
* after all subforms have been successfully saved, it strips them (because forms nested into other forms are simantically invalid, right?) and submits the parent form

# File uploads in subforms

The gem relies on [rails ajax](https://github.com/rails/jquery-rails)'s form submissions, which doesn't allow to submit files directly. Workaround for this is asynchronous file submission using, for example [remotipart](https://github.com/JangoSteve/remotipart) for CarrierWave, or [refile](https://github.com/elabs/refile) with [refile-input](https://github.com/hyperoslo/refile-input). Note: before subforms submissions JavaScript strips all file inputs from the forms.

# Testing

Test's stucture is mostly copied from the original ActiveAdmin.

Install development dependencies with `bundle install`. To setup the test suit run `rake test`. Run tests with `bundle exec guard`. There aren't many of them, let's say there are quite a few.

# In plan

* allow to reuse existing polymorphic objects
* check who it works with: models under a certain namespace
* improve tests

# License

[MIT](LICENSE.txt)
