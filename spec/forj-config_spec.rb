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


$APP_PATH = File.dirname(__FILE__)
$LIB_PATH = File.expand_path(File.join(File.dirname($APP_PATH),'lib'))

$LOAD_PATH << './lib'

require 'lorj' # Load lorj framework

PrcLib.log_file = 'lorj-rspec.log'
PrcLib.level = Logger::FATAL
PrcLib.app_name = 'lorj-spec'
PrcLib.app_defaults = 'lorj-spec'


describe "class: Lorj::Config," do
    context "when creating a new instance" do

      it 'should be loaded' do
         @test_config = Lorj::Config.new()
         expect(@test_config).to be
      end

    end

    context "when starting, Lorj::Config" do
      before(:all) do
         @config = Lorj::Config.new()
      end

      it 'should be able to create a key/value in local config' do
         @config.localSet(:test1,'value')
         expect(@config.localGet(:test1)).to eq('value')
      end

      it 'should be able to remove the previously created key/value from local config' do
         @config.localDel(:test1)
         expect(@config.exist?(:test1)).to equal(false)
      end
    end

    context "while updating local config file, forj-config" do
      before(:all) do
         @config = Lorj::Config.new()
      end

      after(:all)  do
        @config.localDel(:test1)
        @config.saveConfig()
      end

      it 'should save a key/value in local config' do
         @config.localSet(:test1,'value')
         expect(@config.saveConfig()).to equal(true)

         oConfig = Lorj::Config.new()
         expect(@config.localGet(:test1)).to eq('value')
      end

    end

    context "With another config file - test1.yaml, forj-config" do

      before(:all) do
        if File.exists?(File.join(PrcLib.data_path, 'test.yaml'))
           File.delete(File.join(PrcLib.data_path, 'test.yaml'))
        end
        File.open(File.join(PrcLib.data_path, 'test1.yaml'), 'w+') { |file| file.write(":default:\n") }
        @config = Lorj::Config.new('test.yaml')
        @config2 = Lorj::Config.new('test1.yaml')
      end

      after(:all)  do
        File.delete(File.join(PrcLib.data_path, 'test1.yaml'))
      end

      it 'won\'t create a new file If we request to load \'test.yaml\'' do
         expect(File.exists?(File.join(PrcLib.data_path, 'test.yaml'))).to equal(false)
      end

      it 'will load the default config file if we request to load \'test.yaml\'' do
         expect(File.basename(@config.sConfigName)).to eq('config.yaml')
      end

      it 'will confirm \'test1.yaml\' config to be loaded.' do
         expect(File.basename(@config2.sConfigName)).to eq('test1.yaml')
      end

      it 'can save \'test2=value\'' do
         @config2.localSet('test2','value')
         expect(@config2.saveConfig()).to equal(true)
         config3 = Lorj::Config.new('test1.yaml')
         expect(config3.localGet('test2')).to eq('value')
      end

    end

   context "with get/set/exists?," do
      before(:all) do
         @config = Lorj::Config.new()
         @url = @config.get('maestro_url')
      end

      it 'can set and get data,' do
         expect(@config.set(nil, nil)).to equal(false)
         expect(@config.set(:test, nil)).to equal(true)
         expect(@config.get(:test)).to equal(nil)

         expect(@config.set(:test, 'data')).to equal(true)
         expect(@config.get(:test)).to eq('data')
      end

      context 'from defaults,' do
         it 'can get application defaults' do
            expect(@config.get(:maestro_url).class).to equal(String)
            expect(@config.getAppDefault(:default, :maestro_url).class).to equal(String)
            expect(@config.getAppDefault(:description, 'FORJ_HPC').class).to equal(String)

         end
         it 'can get Local defaults instead of application' do
            expect(@config.localSet(:maestro_url,'local')).to equal(true)
            expect(@config.localGet(:maestro_url)).to eq('local')
            expect(@config.get(:maestro_url)).to eq('local')
         end

         it 'can get runtime defaults instead of Local/application' do
            expect(@config.set(:maestro_url, 'runtime')).to equal(true)
            expect(@config.get(:maestro_url)).to eq('runtime')
            expect(@config.localGet(:maestro_url)).to eq('local')
         end

         it 'can get runtime defaults instead of application' do
            expect(@config.localDel(:maestro_url)).to equal(true)
            expect(@config.get(:maestro_url)).to eq('runtime')
            expect(@config.localGet(:maestro_url)).to equal(nil)
         end

         it 'can get defaults if no key' do
            expect(@config.set(:test1, nil)).to equal(true)
            expect(@config.get(:test1, 'default')).to eq('default')
            expect(@config.get(:test1, nil)).to equal(nil)
            expect(@config.set(:maestro_url,nil)).to equal(true)
            expect(@config.get(:maestro_url)).to eq(@url)
         end
      end

   end
end

describe 'Recursive Hash functions,' do
   context "With recursive Hash functions" do
      it 'can create a 3 levels of hash' do
         yYAML = Lorj.rhSet(nil, 'level4', :level1, :level2, :level3)
         expect(yYAML[:level1][:level2][:level3]).to eq('level4')
      end

      it 'can add a 3 levels of hash in an existing hash' do
         yYAML = Lorj.rhSet(nil, 'level4', :level1, :level2, :level3)
         yYAML = Lorj.rhSet(yYAML, 'level1.1', :level1_1)
         expect(yYAML[:level1][:level2][:level3]).to eq('level4')
         expect(yYAML[:level1_1]).to eq('level1.1')
      end

      it 'can get each levels of hash data' do
         yYAML = Lorj.rhSet(nil, 'level4', :level1, :level2, :level3)
         expect(Lorj.rhGet(yYAML, :level1).class).to equal(Hash)
         expect(Lorj.rhGet(yYAML, :level1, :level2).class).to equal(Hash)
         expect(Lorj.rhGet(yYAML, :level1, :level2, :level3).class).to equal(String)
      end

      it 'can check existence of each levels of hash data' do
         yYAML = Lorj.rhSet(nil, 'level4', :level1, :level2, :level3)
         expect(Lorj.rhExist?(yYAML, :level1)).to eq(1)
         expect(Lorj.rhExist?(yYAML, :level1, :level2)).to eq(2)
         expect(Lorj.rhExist?(yYAML, :level1, :level2, :level3)).to eq(3)
         expect(Lorj.rhExist?(yYAML, :level1_1, :level2, :level3)).to eq(0)

      end
   end
end
