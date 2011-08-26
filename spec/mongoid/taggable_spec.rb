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

require File.join(File.dirname(__FILE__), %w[.. spec_helper])

class MyModel
  include Mongoid::Document
  include Mongoid::Taggable

  field :attr
  taggable
end

class Article
  include Mongoid::Document
  include Mongoid::Taggable

  taggable :keywords, :default => []
end

class Editorial < Article
  self.tags_separator = ' '
  self.tag_aggregation = true
end

class Template
  include Mongoid::Document
  include Mongoid::Taggable
  include Mongoid::Timestamps

  taggable :aggregation => true
end

describe Mongoid::Taggable do
  context "saving tags" do
    let(:model) { MyModel.new }

    context "from plain text" do
      it "sets tags array from string" do
        model.tags = "some,new,tag"
        model.tags.should == %w[some new tag]
      end

      it "strips tags before adding to array" do
        model.tags = "now ,  with, some spaces  , in places "
        model.tags.should == ["now", "with", "some spaces", "in places"]
      end

      it "rejects blank tags" do
        model.tags = "repetitive,, commas, shouldn't cause,,, empty tags"
        model.tags.should == ["repetitive", "commas", "shouldn't cause", "empty tags"]
      end
    end

    context "from array of strings" do
      it "ignores blank strings in array" do
        model.tags = ["some", "", "new", "", "tag"]
        model.tags.should == %w[some new tag]
      end

      it "splits any string within the array" do
        model.tags = ["favorite", "colors", "blue, green"]
        model.tags.should == %w[favorite colors blue green]
      end
    end

    it "de-duplicates tags case-insensitively" do
      model.tags = "sometimes, Sometimes, I, repeat, myself"
      model.save
      model.tags.should == %w[sometimes I repeat myself]
    end

    it "preserves case of first-used duplicate" do
      model.update_attribute(:tags, ['repeat'])
      model.tags << 'RePeat'
      model.save
      model.tags.should == ['repeat']
    end

    it "skips de-deduplication on save if tags are unchanged" do
      model.should_not_receive(:dedup_tags!)
      model.update_attribute(:attr, 'changed')
    end
  end

  context "with unrecognized options to taggable" do
    it "passes them to the Mongoid field definition" do
      Article.defaults.should eq 'keywords' => []
    end
  end

  context "with customized tag field name" do
    let(:article) { Article.new }

    it "sets tags array from string" do
      article.keywords = "some,new,tag"
      article.keywords.should == %w[some new tag]
    end
  end

  context "changing separator" do
    before :all do
      MyModel.tags_separator = ";"
    end

    after :all do
      MyModel.tags_separator = ","
    end

    let(:model) { MyModel.new }

    it "splits with custom separator" do
      model.tags = "some;other;separator"
      model.tags.should == %w[some other separator]
    end
  end

  context "tag & count aggregation" do
    it "generates the aggregate collection name based on model" do
      MyModel.tags_aggregation_collection.should == "my_models_tags_aggregation"
    end

    it "is disabled by default" do
      MyModel.create!(:tags => "sample,tags")
      MyModel.tags.should == []
    end

    it "can be forced" do
      MyModel.create!(:tags => "sample,tags")
      MyModel.aggregate_tags!
      MyModel.tags.should == %w[sample tags]
    end

    context "when enabled" do
      before :all do
        MyModel.tag_aggregation = true
      end

      after :all do
        MyModel.tag_aggregation = false
      end

      let!(:models) do
        [
          MyModel.create!(:tags => "food,ant,bee"),
          MyModel.create!(:tags => "juice,food,bee,zip"),
          MyModel.create!(:tags => "honey,strip,food")
        ]
      end

      it "lists all saved tags distinct and ordered" do
        MyModel.tags.should == %w[ant bee food honey juice strip zip]
      end

      it "lists all tags with their weights" do
        MyModel.tags_with_weight.should == [
          ['ant', 1],
          ['bee', 2],
          ['food', 3],
          ['honey', 1],
          ['juice', 1],
          ['strip', 1],
          ['zip', 1]
        ]
      end

      it "updates when tags are edited" do
        MyModel.should_receive(:aggregate_tags!)
        models.first.update_attributes(:tags => 'changed')
      end

      it "does not update if tags are unchanged" do
        MyModel.should_not_receive(:aggregate_tags!)
        models.first.update_attributes(:attr => "changed")
      end

      it "updates if tags are removed" do
        MyModel.should_receive(:aggregate_tags!)
        models.first.destroy
      end
    end

    context "with custom tag field name" do
      before :all do
        Article.tag_aggregation = true
      end

      after :all do
        Article.tag_aggregation = false
      end

      it "uses custom field name for aggregates" do
        Article.create!(:keywords => "some, tags")
        Article.create!(:keywords => "more, tags")
        Article.keywords.should == ["more", "some", "tags"]
        Article.keywords_with_weight.should include(['tags', 2])
      end
    end
  end

  context "#self.tagged_with" do
    let!(:models) do
      [
        MyModel.create!(:tags => "tag1,tag2,tag3"),
        MyModel.create!(:tags => "tag2"),
        MyModel.create!(:tags => "tag1", :attr => "value")
      ]
    end

    it "returns all tags with single tag input" do
      MyModel.tagged_with("tag2").sort_by{|a| a.id.to_s}.should == [models.first, models.second].sort_by{|a| a.id.to_s}
    end

    it "returns all tags with tags array input" do
      MyModel.tagged_with(%w{tag2 tag1}).should == [models.first]
    end

    it "returns all tags with tags string input" do
      MyModel.tagged_with("tag2, tag1").should == [models.first]
    end

    it "can be chained with other criteria" do
      MyModel.tagged_with("tag1").where(:attr => "value").should == [models.last]
    end
  end

  context "a subclass of a taggable document" do
    let(:editorial) { Editorial.new }

    it "can enable tag aggregation exclusively" do
      Article.tag_aggregation.should == false
      Editorial.tag_aggregation.should == true
    end

    it "can split with a different separator" do
      editorial.keywords = 'opinion politics'
      editorial.keywords.should == %w[opinion politics]
    end

    # This is kind of surprising -- subclasses are stored in the same Mongo
    # collection. Should we change the map/reduce output collection?
    it "counts aggregates including parent" do
      Article.create!(:keywords => 'satire, politics')
      Editorial.create!(:keywords => 'satire politics')
      Editorial.create!(:keywords => 'satire politics')
      Article.keywords_with_weight.should include(['satire', 3])
      Editorial.keywords_with_weight.should include(['satire', 3])
    end
  end

  context "using taggable module along with other mongoid modules" do
    it "lists all saved tags distinct and ordered with custom tag attribute" do
      Template.create!(:tags => 'food, ant, bee')
      Template.tags.should == %w[ant bee food]
    end
  end
end

