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

app_path = File.dirname(__FILE__)

$LOAD_PATH << File.join(app_path, '..', 'lib')

require 'lorj' # Load lorj framework

describe 'class: Lorj::Config,' do
  context 'new instance, with no default local config files, ' do
    before(:all) do
      log_file = File.expand_path(File.join('~', 'lorj-rspec.log'))
      File.delete(log_file) if File.exist?(log_file)

      PrcLib.log = nil
      PrcLib.log_file = log_file
      PrcLib.level = Logger::FATAL
      PrcLib.app_name = 'lorj-spec'
      PrcLib.app_defaults = File.expand_path(File.join(app_path, '..',
                                                       'lorj-spec'))
      @local = File.join(PrcLib.data_path, 'config.yaml')
      File.delete(@local) if File.exist?(@local)
    end

    it 'should be loaded' do
      expect(File.exist?(@local)).to equal(false)
      config = Lorj::Config.new
      expect(config).to be
    end
    it 'local config file gets created.' do
      expect(File.exist?(@local)).to equal(true)
    end
    it 'local config is empty.' do
      expect(YAML.load_file(@local)).to eq(:default => nil)
    end
  end

  context 'CoreConfig original functions,' do
    before(:all) do
      @config = Lorj::Config.new
    end

    it 'config.file return nil. (runtime)' do
      expect(@config.file).to equal(nil)
    end

    it "config.file(nil, :name => 'local') return local config file." do
      file = File.join(PrcLib.data_path, 'config.yaml')
      expect(@config.file(nil, :name => 'local')).to eq(file)
    end

    it "config.file(nil, :name => 'default') return default "\
       'application file.' do
      file = File.join(PrcLib.app_defaults, 'defaults.yaml')
      expect(@config.file(nil, :name => 'default')).to eq(file)
    end

    it 'config.layers returns all config names.' do
      expect(@config.layers).to eq(%w(runtime local controller default))
    end

    it 'config.where?(:test1) return false' do
      expect(@config.where?(:test1)).to equal(false)
    end

    it 'config.exist?(:test1) returns false' do
      expect(@config.exist?(:test1)).to equal(false)
    end

    it "config.where?(:maestro_url) return ['defaults'] "\
       '(see lorj-spec/defaults.yaml)' do
      expect(@config.where?(:maestro_url)).to eq(['default'])
    end

    it 'config.exist?(:maestro_url) returns true' do
      expect(@config.exist?(:maestro_url)).to equal(true)
    end
  end

  context 'redefined CoreConfig functions' do
    before(:all) do
      @config = Lorj::Config.new
    end

    it "config[:maestro_url] returns 'http://example.org'" do
      expect(@config[:maestro_url]).to eq('http://example.org')
    end

    it "config.get(:maestro_url) returns 'http://example.org'" do
      expect(@config.get(:maestro_url)).to eq('http://example.org')
    end

    it 'config[:test1, :none] returns :none' do
      expect(@config[:test1, :none]).to equal(:none)
    end

    it "config[:maestro_url, :none] returns 'http://example.org'" do
      expect(@config[:maestro_url, :none]).to eq('http://example.org')
    end

    it 'config[:maestro_url] = :none returns :none' do
      expect(@config[:maestro_url] = :none).to eq(:none)
    end

    it 'config[:maestro_url, :none] returns :none' do
      expect(@config[:maestro_url]).to eq(:none)
    end

    it 'config.where?(:maestro_url) returns [runtime, default]' do
      expect(@config.where?(:maestro_url)).to eq(%w(runtime default))
    end

    it 'config.del(:maestro_url) returns :none' do
      expect(@config.del(:maestro_url)).to eq(:none)
    end
    it 'config.where?(:maestro_url) now returns [default]' do
      expect(@config.where?(:maestro_url)).to eq(%w(default))
    end

    it 'config.set(:maestro_url, :none) is equivalent as '\
       'config[:maestro_url] = :none' do
      expect(@config.set(:maestro_url, :none)).to eq(:none)
      expect(@config.where?(:maestro_url)).to eq(%w(runtime default))
    end
  end

  context 'Lorj::Config specific functions' do
    before(:all) do
      @config = Lorj::Config.new
    end

    it 'config.config_filename is identical than '\
       "config.file(nil, :name => 'local')" do
      file = @config.file(nil, :name => 'local')
      expect(@config.config_filename).to eq(file)
    end

    it "config.config_filename('default') is identical than "\
       "config.file(nil, :name => 'default')" do
      file = @config.file(nil, :name => 'default')
      expect(@config.config_filename('default')).to eq(file)
    end

    it "config.file('test2.yaml', 'runtime') returns false - not authorized." do
      expect(@config.file('test2.yaml', :name => 'runtime')).to equal(false)
      expect(@config.config_filename('runtime')).to equal(nil)
    end

    it "config.file('test2.yaml', 'local') returns false - not authorized." do
      expect(@config.file('test2.yaml', :name => 'local')).to equal(false)
      file = File.join(PrcLib.data_path, 'config.yaml')
      expect(@config.config_filename).to eq(file)
    end

    it "config.file('test2.yaml', 'default') returns false - not authorized." do
      expect(@config.file('test2.yaml', :name => 'default')).to equal(false)
      file = File.join(PrcLib.app_defaults, 'defaults.yaml')
      expect(@config.config_filename('default')).to eq(file)
    end

    it 'config.local_exist?(:test1) returns false' do
      expect(@config.local_exist?(:test1)).to equal(false)
    end

    it "config.local_set(:test1, 'value') returns 'value' and saved in"\
       " 'local' config" do
      expect(@config.local_set(:test1, 'value')).to eq('value')
      expect(@config.where?(:test1)).to eq(%w(local))
    end

    it 'config.local_exist?(:test1) returns true' do
      expect(@config.local_exist?(:test1)).to equal(true)
    end

    it "config.local_get(:test1) returns 'value'" do
      expect(@config.local_get(:test1)).to eq('value')
    end

    it 'config.save_local_config returns true and is really saved.' do
      config = Lorj::Config.new
      expect(config.where?(:test1)).to equal(false)
      expect(@config.save_local_config).to equal(true)
      config2 = Lorj::Config.new
      expect(config2.where?(:test1)).to eq(%w(local))
    end

    it "config.local_del(:test1) returns 'value'" do
      expect(@config.local_del(:test1)).to eq('value')
      expect(@config.where?(:test1)).to equal(false)
    end

    it 'default_dump return all in a Hash, without :setup and :sections' do
      default_file = @config.config_filename('default')
      # Following will split defaults.yaml to 2 differents config
      # values config layers and metadata config layers.
      Lorj.defaults
      default = YAML.load_file(default_file)
      default.delete(:setup)
      default.delete(:sections)

      res = { 'local' => { :default => {} },
              'default' => default
            }

      expect(@config.config_dump).to eq(res)
    end

    it 'config.get_section(:maestro_url) returns :maestro' do
      expect(@config.get_section(:maestro_url)).to equal(:maestro)
    end

    it 'config.get_section(:test1, :default) returns :default' do
      expect(@config.get_section(:test1)).to equal(nil)
    end

    it 'config.runtime_exist?(:test1) returns false - no :test1 available in '\
       'runtime.' do
      expect(@config.runtime_exist?(:test1)).to equal(false)
    end

    context 'setting :test1 => :value,' do
      before(:all) do
        @config[:test1] = :value
      end
      it 'config.runtime_get(:test1) returns :value' do
        expect(@config.runtime_get(:test1)).to equal(:value)
      end
      it 'config.runtime_exist?(:test1) returns true' do
        expect(@config.runtime_exist?(:test1)).to equal(true)
      end
    end
  end
end
