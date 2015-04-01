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

# require 'byebug'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rh.rb'
require 'prc.rb'
require 'prc_base_config.rb' # Load PRC_core framework

describe 'class: PRC::BaseConfig,' do
  context 'when creating a new instance' do
    it 'should be loaded' do
      config = PRC::BaseConfig.new
      expect(config).to be
    end

    it 'should be initialized with Hash data.' do
      config = PRC::BaseConfig.new(:test => :toto)
      expect(config.data).to eq(:test => :toto)
    end
  end

  context 'config[*keys] = value' do
    before(:all) do
      @config = PRC::BaseConfig.new
    end

    it 'should be able to create a key/value in the config object.' do
      @config[:test1] = 'value'
      expect(@config.data).to eq(:test1 => 'value')
    end

    it 'should be able to create a key tree/value in the config object.' do
      @config[:test1, :test2] = 'value'
      expect(@config.data).to eq(:test1 => { :test2 => 'value' })
    end

    it 'version = "0.1" can be set and get' do
      expect(@config.version).to equal(nil)
      @config.version = '0.1'
      expect(@config.version).to eq('0.1')
    end
  end

  context 'config.del(*keys)' do
    before(:all) do
      @config = PRC::BaseConfig.new(:test1 => 'value',
                                    :test2 => { :test2 => 'value' })
    end

    it 'should be able to delete a key/value in the config object.' do
      expect(@config.del(:test1)).to eq('value')
      expect(@config.data).to eq(:test2 => { :test2 => 'value' })
    end

    it 'should be able to delete a key/value in the config object.' do
      expect(@config.del(:test2)).to eq(:test2 => 'value')
      expect(@config.data).to eq({})
    end
  end

  context 'config[*keys]' do
    before(:all) do
      @config = PRC::BaseConfig.new(:test1 => { :test2 => 'value' })
    end

    it 'with no parameter should return nil' do
      expect(@config[]).to equal(nil)
    end

    it "with keys = [:test1], should return {:test2 =>'value'}." do
      expect(@config[:test1]).to eq(:test2 => 'value')
    end

    it "with keys = [:test1, :test2], should return {:test2 =>'value'}." do
      expect(@config[:test1, :test2]).to eq('value')
    end
  end

  context 'config.exist?(*keys)' do
    before(:all) do
      @config = PRC::BaseConfig.new(:test1 => { :test2 => 'value' })
    end

    it 'with no parameter should return nil' do
      expect(@config.exist?).to equal(nil)
    end

    it 'with keys = [test1], should return true.' do
      expect(@config.exist?(:test1)).to equal(true)
    end

    it 'with keys = [:test1, :test2], should return true.' do
      expect(@config.exist?(:test1, :test2)).to equal(true)
    end

    it 'with keys = [:test], should return false.' do
      expect(@config.exist?(:test)).to equal(false)
    end

    it 'with keys = [:test1, :test], should return false.' do
      expect(@config.exist?(:test1, :test)).to equal(false)
    end

    it 'with keys = [:test1, :test2, :test3], should return false.' do
      expect(@config.exist?(:test1, :test2, :test3)).to equal(false)
    end
  end

  context "config.erase on :test1 => { :test2 => 'value' }" do
    it 'with no parameter should return {} and cleanup internal data.' do
      config = PRC::BaseConfig.new(:test1 => { :test2 => 'value' })
      config.version = '0.1'

      expect(config.erase).to eq({})
      expect(config.data).to eq({})
      expect(config.version).to eq(nil)
    end
  end

  context 'config.save and config.load' do
    before(:all) do
      @config = PRC::BaseConfig.new(:test1 => { :test2 => 'value' })
    end

    it 'save with no parameter should fail' do
      expect { @config.save }.to raise_error RuntimeError
    end

    it 'save with filename set, save should true' do
      file = '~/.lorj_rspec.yaml'
      @config.filename = file
      filename = File.expand_path(file)

      expect(@config.filename).to eq(filename)
      expect(@config.save).to equal(true)

      File.delete(filename)
    end

    it 'save with filename given, returns true, and file saved.' do
      file = '~/.lorj_rspec2.yaml'
      old_file = @config.filename
      filename = File.expand_path(file)

      @config.version = '1'
      expect(@config.save(file)).to equal(true)
      expect(@config.filename).not_to eq(old_file)
      expect(@config.filename).to eq(filename)
    end

    it 'load returns true and file is loaded.' do
      @config.erase

      expect(@config.load).to equal(true)
      expect(@config.data).to eq(:test1 => { :test2 => 'value' })
      expect(@config.version).to eq('1')

      File.delete(@config.filename)
    end

    it 'load raises if file given is not found.' do
      @config.erase

      expect { @config.load('~/.lorj_rspec.yaml') }.to raise_error
    end
  end

  context 'config.data_options(options)' do
    it 'with no parameter should return {} ie no options.' do
      config = PRC::BaseConfig.new
      expect(config.data_options).to eq({})
    end

    it 'with :readonly => true should return {} ie no options.' do
      config = PRC::BaseConfig.new
      expect(config.data_options(:readonly => true)).to eq(:readonly => true)
    end

    it 'with any unknown options like :section => "test" should return '\
       '{:section => "test"}.' do
      config = PRC::BaseConfig.new
      expect(config.data_options(:section => 'test')).to eq(:section => 'test')
    end

    it 'with any existing options set we replace it all.' do
      config = PRC::BaseConfig.new
      config.data_options(:section => 'test')
      expect(config.data_options(:toto => 'tata')).to eq(:toto => 'tata')
    end

    it 'with :data_readonly => true, we cannot set a data.' do
      config = PRC::BaseConfig.new(:test => 'toto')
      config.data_options(:data_readonly => true)
      config[:test] = 'titi'
      expect(config.data).to eq(:test => 'toto')
    end

    it 'with :file_readonly => true, we cannot save data to a file.' do
      config = PRC::BaseConfig.new(:test => 'toto')
      file = '~/.rspec_test.yaml'
      file_path = File.expand_path(file)
      config.data_options(:file_readonly => true)
      system('rm -f ~/.rspec_test.yaml')
      expect(config.save(file)).to equal(false)
      expect(config.filename).to equal(nil)
      expect { config.load(file) }.to raise_error
      expect(config.filename).to eq(file_path)
    end
  end
end
