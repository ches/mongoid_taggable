# -*- coding: utf-8 -*-
# Copyright (c) 2010 Wilker Lúcio <wilkerlucio@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongoid::Taggable
  extend ActiveSupport::Concern

  included do
    class_attribute :tags_field, :tags_separator, :tag_aggregation,
      :tag_aggregation_options, :instance_writer => false

    delegate :convert_string_tags_to_array, :aggregate_tags!, :aggregate_tags?,
      :to => 'self.class'

    set_callback :create,  :after,  :aggregate_tags!, :if => proc { aggregate_tags? }
    set_callback :destroy, :after,  :aggregate_tags!, :if => proc { aggregate_tags? }
    set_callback :save,    :before, :dedup_tags!,     :if => proc { changes.include?(tags_field.to_s) }
    set_callback :save,    :after,  :aggregate_tags!, :if => proc { changes.include?(tags_field.to_s) and aggregate_tags? }
  end

  module ClassMethods
    # Macro to declare a document class as taggable, specify field name
    # for tags, and set options for tagging behavior. Additional options
    # are passed to the Mongoid field definition call.
    #
    # @example Define a taggable document.
    #
    #   class Article
    #     include Mongoid::Document
    #     include Mongoid::Taggable
    #     taggable :keywords, :separator => ' ', :aggregation => true,
    #       :aggregation_options => {}
    #   end
    #
    # @param [ Symbol ] field The name of the field for tags.
    # @param [ Hash ] options Options for taggable behavior.
    #
    # @option options [ String ] :separator The tag separator to
    #   convert from; defaults to ','
    # @option options [ true, false ] :aggregation Whether or not to
    #   aggregate counts of tags within the document collection using
    #   map/reduce; defaults to false
    # @option options [ Hash ] :aggregation_options Options for the
    #   map/reduce ruby-driver method; defaults to {}
    def taggable(*args)
      options = args.extract_options!

      self.tags_field = args.blank? ? :tags : args.shift
      self.tags_separator  = options.delete(:separator) { ',' }
      self.tag_aggregation = options.delete(:aggregation) { false }
      self.tag_aggregation_options = options.delete(:aggregation_options) { {} }

      field tags_field, options.merge(:type => Array)
      index tags_field

      define_tag_field_accessors(tags_field)
    end

    # Find documents tagged with all tags passed as a parameter, given
    # as an Array or a String using the configured separator.
    #
    # @example Find matching all tags in an Array.
    #   Article.tagged_with(['ruby', 'mongodb'])
    # @example Find matching all tags in a String.
    #   Article.tagged_with('ruby, mongodb')
    #
    # @param [ Array<String, Symbol>, String ] _tags Tags to match.
    # @return [ Criteria ] A new criteria.
    def tagged_with(_tags)
      _tags = convert_string_tags_to_array(_tags) if _tags.is_a? String
      criteria.all_in(tags_field => _tags)
    end

    # Predicate for whether or not map/reduce aggregation is enabled
    def aggregate_tags?
      !!tag_aggregation
    end

    # Collection name for storing results of tag count aggregation
    def tags_aggregation_collection
      @tags_aggregation_collection ||= "#{collection_name}_tags_aggregation"
    end

    # Execute map/reduce operation to aggregate tag counts for document
    # class
    def aggregate_tags!
      map = "function() {
        if (!this.#{tags_field}) {
          return;
        }

        for (index in this.#{tags_field}) {
          emit(this.#{tags_field}[index], 1);
        }
      }"

      reduce = "function(previous, current) {
        var count = 0;

        for (index in current) {
          count += current[index]
        }

        return count;
      }"

      map_reduce_options = { :out => tags_aggregation_collection }.
        merge(tag_aggregation_options)
      collection.master.map_reduce(map, reduce, map_reduce_options)
    end

  private

    # Helper method to convert a String to an Array based on the
    # configured tag separator.
    def convert_string_tags_to_array(_tags)
      (_tags).split(tags_separator).map(&:strip).reject(&:blank?)
    end

    def define_tag_field_accessors(name)
      # Define modifier for the configured tag field name that overrides
      # the default to transparently convert tags given as a String.
      define_method "#{name}_with_taggable=" do |values|
        case values
        when String
          values = convert_string_tags_to_array(values)
        when Array
          values = values.inject([]) { |final, value| final.concat convert_string_tags_to_array(value) }
        end
        send("#{name}_without_taggable=", values)
      end
      alias_method_chain "#{name}=", :taggable

      # Define value_before_type_cast method to format array in input field as comma separated list
      # @see ActionView::Helpers::InstanceTag::value_before_type_cast
      define_method "#{name}_before_type_cast" do
        self.send(name).join("#{tags_separator} ") if self.send(name)
      end

      # Dynamically named class methods, for aggregation
      (class << self; self; end).instance_eval do
        # get an array with all defined tags for this model, this list returns
        # an array of distinct ordered list of tags defined in all documents
        # of this model
        define_method "#{name}" do
          db.collection(tags_aggregation_collection).find.to_a.map{ |r| r["_id"] }
        end

        # retrieve the list of tags with weight(count), this is useful for
        # creating tag clouds
        define_method "#{name}_with_weight" do
          db.collection(tags_aggregation_collection).find.to_a.map{ |r| [r["_id"], r["value"]] }
        end
      end
    end
  end

  module InstanceMethods
    # De-duplicate tags, case-insensitively, but preserve case given first
    def dedup_tags!
      tags = read_attribute(tags_field)
      tags = tags.reduce([]) do |uniques, tag|
        uniques << tag unless uniques.map(&:downcase).include?(tag.downcase)
        uniques
      end
      write_attribute(tags_field, tags)
    end
  end
end
