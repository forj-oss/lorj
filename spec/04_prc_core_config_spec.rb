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

$LOAD_PATH << File.join('..', 'lib')

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

  context 'from a child class, with local layer set to :test => :found_local'\
          ' and runtime layer' do
    before(:all) do
      # Child class definition for rSpec.
      class Test1 < PRC::CoreConfig
        def initialize
          local = PRC::BaseConfig.new(:test => :found_local)
          layers = []
          layers << PRC::CoreConfig.define_layer(:name => 'local',
                                                 :config => local)
          layers << PRC::CoreConfig.define_layer # runtime

          initialize_layers(layers)
        end
      end
      @config = Test1.new
    end

    it 'should be loaded' do
      expect(@config).to be
      expect(@config.layers).to eq(%w(runtime local))
    end

    it 'config.where?(:test) should be ["local"]' do
      expect(@config.where?(:test)).to eq(['local'])
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
  end
end
