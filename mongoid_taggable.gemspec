# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'mongoid/taggable/version'

Gem::Specification.new do |s|
  s.name     = 'mongoid_taggable'
  s.version  = Mongoid::Taggable::VERSION
  s.platform = Gem::Platform::RUBY

  s.date        = '2010-07-26'
  s.authors     = ['Wilker Lúcio', 'Kris Kowalik', 'Ches Martin', 'Paulo Fagiani']
  s.email       = ['wilkerlucio@gmail.com']
  s.homepage    = 'http://github.com/wilkerlucio/mongoid_taggable'
  s.summary     = 'Mongoid taggable behaviour'
  s.description = 'Mongoid Taggable provides some helpers to create taggable documents.'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_runtime_dependency('mongoid', ['~> 2.1'])
  s.add_development_dependency("bson_ext", ["~> 1.3"])
  s.add_development_dependency('database_cleaner', ['~> 0.6.0'])
  s.add_development_dependency("rdoc", ["~> 3.5.0"])
  s.add_development_dependency('rspec', ['~> 2.6.0'])

  s.extra_rdoc_files = %w[LICENSE README.md]
  s.files = Dir.glob('lib/**/*') + %w[LICENSE README.md Rakefile]
  s.require_paths = %w[lib]
end

