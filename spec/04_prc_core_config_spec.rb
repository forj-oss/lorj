#!/usr/bin/env ruby
# encoding: UTF-8

# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

#  require 'byebug'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rh.rb'
require 'prc.rb'
require 'prc_base_config.rb'
require 'prc_core_config.rb'

describe 'class: PRC::CoreConfig,' do
  context 'when creating a new instance' do
    before(:all) do
      @config = PRC::CoreConfig.new
    end

    it 'should be loaded' do
      expect(@config).to be
    end

    it 'runtime set works' do
      expect(@config[:test] = :toto).to eq(:toto)
      expect(@config.exist?(:test)).to eq(true)
      expect(@config[:test]).to eq(:toto)
    end
  end

  context 'from a child class, with local layer set to :test => :found_local, '\
          ':test2 => {:test => :subhash} and runtime layer' do
    before(:all) do
      # Child class definition for rSpec.
      class Test1 < PRC::CoreConfig
        def initialize
          local = PRC::BaseConfig.new(:test => :found_local,
                                      :test2 => { :test => :subhash })
          layers = []
          layers << PRC::CoreConfig.define_layer(:name => 'local',
                                                 :config => local)
          layers << PRC::CoreConfig.define_layer # runtime

          initialize_layers(layers)
        end

        def set(options)
          p_set(options)
        end

        def get(options)
          p_get(options)
        end
      end
      @config = Test1.new
    end

    it 'should be loaded' do
      expect(@config).to be
      expect(@config.layers).to eq(%w(runtime local))
    end

    it 'config.exist?(:test) returns true' do
      expect(@config.exist?(:test)).to equal(true)
    end

    it 'config.exist?(:test2, :test) returns true' do
      expect(@config.exist?(:test2, :test)).to equal(true)
    end

    it 'config.where?(:test) should be ["local"]' do
      expect(@config.where?(:test)).to eq(['local'])
    end

    it 'config.where?(:test2) should be ["local"]' do
      expect(@config.where?(:test2)).to eq(['local'])
    end

    it 'config.where?(:test2, :test) should be ["local"]' do
      expect(@config.where?(:test2, :test)).to eq(['local'])
    end

    it 'config.[:test] = :where set in "runtime".' do
      expect(@config[:test] = :where).to eq(:where)
      expect(@config.where?(:test)).to eq(%w(runtime local))
      expect(@config[:test]).to equal(:where)
    end

    it 'config.del(:test) remove the data from runtime, '\
       'and restore from local.' do
      expect(@config.del(:test)).to eq(:where)
      expect(@config[:test]).to equal(:found_local)
    end

    it 'PRC::CoreConfig.define_layer(...) return a valid standalone layer' do
      config = PRC::BaseConfig.new
      layer = PRC::CoreConfig.define_layer(:name => 'instant',
                                           :config => config)
      expect(layer).to be
      expect(layer[:name]).to eq('instant')
      expect(layer[:config]).to eq(config)
      expect(layer[:set]).to equal(true)
      expect(layer[:load]).to equal(false)
      expect(layer[:save]).to equal(false)
      expect(layer[:file_set]).to equal(false)
    end

    it "config.layer_add(:name => 'instant') return true if layer is added" do
      layer = PRC::CoreConfig.define_layer(:name => 'instant')
      expect(@config.layer_add layer).to equal(true)
    end

    it 'config.layers return %w(instant runtime local)' do
      expect(@config.layers).to eq(%w(instant runtime local))
    end

    it 'config.layer_add(layer) return nil if layer name already exist '\
       'in layers' do
      config = PRC::BaseConfig.new
      layer = PRC::CoreConfig.define_layer(:name => 'instant',
                                           :config => config)
      expect(@config.layers).to eq(%w(instant runtime local))
      expect(@config.layer_add layer).to equal(nil)
      expect(@config.layers).to eq(%w(instant runtime local))
    end

    it "config['test'] = 'toto' is added in the 'instant' layer" do
      @config['test'] = 'toto'
      expect(@config.where?('test')).to eq(%w(instant))
    end

    it "config.layer_remove(:name => 'instant') return true" do
      expect(@config.layer_remove(:name => 'instant')).to equal(true)
    end

    it "config.where?('test') return false - The layer is inexistent." do
      expect(@config.where?('test')).to equal(false)
    end

    it "config.layer_remove(:name => 'runtime') return nil"\
       ' - Unable to remove a layer not added at runtime' do
      expect(@config.layers).to eq(%w(runtime local))
      expect(@config.layer_remove(:name => 'runtime')).to equal(nil)
      expect(@config.layers).to eq(%w(runtime local))
    end

    it 'a child set(keys, value, name => "local") works.' do
      value = { :data1 => 'test_data1', :data2 => 'test_data2' }
      expect(@config.set(:keys => [:merge1],
                         :value => value,
                         :name => 'local')).to eq(value)
      expect(@config.where?(:merge1)).to eq(%w(local))
    end

    it 'a child set(keys, value, names => ["local"]) works '\
       'but set in runtime. :names is ignored.' do
      value = { :data1 => 'test_data1', :data2 => 'test_data3' }
      expect(@config.set(:keys => [:merge1],
                         :value => value,
                         :names => ['local'])).to eq(value)
      expect(@config.where?(:merge1)).to eq(%w(runtime local))
    end

    it 'a child set(keys, value, name => "runtime") works.' do
      value = { :data2 => 'value_runtime', :test_runtime => true }
      expect(@config.set(:keys => [:merge1],
                         :value => value,
                         :name => 'runtime')).to eq(value)
      expect(@config.where?(:merge1)).to eq(%w(runtime local))
      expect(@config[:merge1]).to eq(value)
    end

    it 'a child get(keys, name) can do merge '\
       'even with only one layer selected.' do
      value_local = { :data1 => 'test_data1', :data2 => 'test_data2' }
      expect(@config.get(:keys => [:merge1], :merge => true,
                         :names => ['local'])).to eq(value_local)
      value_runtime = { :data2 => 'value_runtime', :test_runtime => true }
      expect(@config.get(:keys => [:merge1], :merge => true,
                         :names => ['runtime'])).to eq(value_runtime)
    end

    context "with config[:merge1] = {:data2 => {:test_runtime => true} }\n"\
            'and local: :merge1: => {:data1: test_data1, :data2: test_data3}' do
      before(:all) do
        @config[:merge1] = { :data2 => { :test_runtime => true } }
        value = { :data1 => 'test_data1', :data2 => 'test_data3' }
        @config.set(:keys => [:merge1], :value => value, :name => 'local')
      end

      it 'config.mergeable?(:keys => [:merge1, :data2]) return false, '\
         'because the first found in the deepest layers is not a Hash/Array.' do
        expect(@config.where?(:merge1, :data2)).to eq(%w(runtime local))
        expect(@config.mergeable?(:keys => [:merge1, :data2])).to equal(false)
      end

      it 'config.mergeable?(:keys => [:merge1, :data2], '\
         ':exclusive => true) return false '\
         '- "runtime" layer :data2 is not a Hash' do
        expect(@config.where?(:merge1, :data2)).to eq(%w(runtime local))
        expect(@config.mergeable?(:keys => [:merge1, :data2],
                                  :exclusive => true)).to equal(false)
      end

      it 'config.merge() return "test_data3" a single data, first found in '\
         'the deepest layers.' do
        expect(@config.merge(:merge1, :data2)).to eq('test_data3')
      end
    end

    context "with config[:merge1] = {:data2 => :test_runtime}\n"\
            'and local: :merge1: => {:data2 => {:test => :test_data2} }' do
      before(:all) do
        @config[:merge1] = { :data2 => :test_runtime }
        value = { :data2 => { :test => :test_data2 } }
        @config.set(:keys => [:merge1], :value => value, :name => 'local')
      end

      it 'config.mergeable?(:keys => [:merge1, :data2]) return true, '\
         'because the first found in the deepest layers is a Hash.' do
        expect(@config.where?(:merge1)).to eq(%w(runtime local))
        expect(@config.mergeable?(:keys => [:merge1, :data2])).to equal(true)
      end

      it 'config.mergeable?(:keys => [:merge1, :data2], '\
         ':exclusive => true) return false '\
         '- "runtime" layer :data2 is not a Hash' do
        expect(@config.mergeable?(:keys => [:merge1, :data2],
                                  :exclusive => true)).to equal(false)
      end

      it 'config.merge() return a single data, first found in the '\
         'deepest layers.' do
        expect(@config.merge(:merge1, :data2)).to eq(:test => :test_data2)
      end
    end

    context "with config[:merge1] = {:data2 => {:test_runtime => true} }\n"\
            'and local: :merge1: => {:data2 => {:test => :test_data2} }' do
      before(:all) do
        @config[:merge1] = { :data2 => { :test_runtime => true } }
        value = { :data2 => { :test => :test_data2 } }
        @config.set(:keys => [:merge1], :value => value, :name => 'local')
      end

      it 'config.mergeable?(:keys => [:merge1, :data2]) return true, '\
         'because the first found in the deepest layers is a Hash.' do
        expect(@config.where?(:merge1, :data2)).to eq(%w(runtime local))
        expect(@config.mergeable?(:keys => [:merge1, :data2])).to equal(true)
      end

      it 'config.mergeable?(:keys => [:merge1, :data2], '\
         ':exclusive => true) return true '\
         '- All layers data found are Hash type.' do
        expect(@config.mergeable?(:keys => [:merge1, :data2],
                                  :exclusive => true)).to equal(true)
      end

      it 'config.merge() return a single data, first found in the '\
         'deepest layers.' do
        expect(@config.merge(:merge1, :data2)).to eq(:test_runtime => true,
                                                     :test => :test_data2)
      end
    end
  end
end
