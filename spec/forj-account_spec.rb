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

require 'rubygems'
require 'bundler/setup'

$APP_PATH = File.dirname(__FILE__)
$LIB_PATH = File.expand_path(File.join(File.dirname($APP_PATH), 'lib'))

$LOAD_PATH << $LIB_PATH

require 'lorj' # Load lorj framework

PrcLib.log_file = 'lorj-rspec.log'
PrcLib.level = Logger::FATAL
PrcLib.app_name = 'lorj-spec'
PrcLib.app_defaults = 'lorj-spec'

describe 'class: Lorj::Account,' do
  context 'when creating a new instance,' do
    it 'should be loaded' do
      oForjAccount = Lorj::Account.new
      expect(oForjAccount).to be
    end

    it 'should store log data in lorj-rspec.log' do
      expect(PrcLib.log_file).to eq(File.expand_path('lorj-rspec.log'))
    end
  end

  context 'when starting,' do
    before(:all) do
      File.open(File.join(PrcLib.data_path, 'config.yaml'), 'w+') { |file| file.write("default:\n  keypair_name: nova_local\n") }
      File.open(File.join(PrcLib.data_path, 'accounts', 'test1'), 'w+') { |file| file.write("credentials:\n  keypair_name: nova_test1\n  :tenant_name: test\n") }

      config = Lorj::Config.new
      config[:account_name] = 'test1'
      @ForjAccount = Lorj::Account.new(config)
      @ForjAccount.ac_load
    end

    it 'should be able to read account data' do
      expect(@ForjAccount[:keypair_name]).to eq('nova_test1')
    end

    it 'should be able to create a key/value in the account config' do
      @ForjAccount.set(:test1, 'value')
      expect(@ForjAccount.get(:test1)).to eq('value')
      @ForjAccount.set(:keypair_name, 'value')
      expect(@ForjAccount.get(:keypair_name)).to eq('value')
    end

    it 'should be able to delete a key/value in the account config and get default back.' do
      @ForjAccount.del(:keypair_name)
      expect(@ForjAccount.get(:keypair_name)).to eq('nova_local')
    end
  end
end
