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

# require 'rubygems'
# require 'byebug'
# require 'bundler/setup'

app_path = File.dirname(File.dirname(__FILE__))

$LOAD_PATH << '../lib'

require 'lorj' # Load lorj framework

describe 'class: Lorj::Account,' do
  context 'Lorj::Account.new,' do
    it 'instance is created.' do
      PrcLib.log_file = 'lorj-rspec.log'
      PrcLib.level = Logger::FATAL
      PrcLib.app_name = 'lorj-spec'
      PrcLib.app_defaults = File.join(app_path, 'lorj-spec')

      account = Lorj::Account.new
      expect(account).to be
    end

    it 'account.layers is compliant' do
      account = Lorj::Account.new
      expect(account.layers).to eq(%w(runtime account local default))
    end
  end

  context "Key      | runtime | accounts   | local     | default)\n"\
          "  :keypair | nil     | nil        | nova_local| default_key\n"\
          "  :data    | nil     | nil        | no effect | None\n"\
          "  :data is account exclusive\n  => accounts/test1 not set:" do
    before(:all) do
      File.open(File.join(PrcLib.data_path, 'config.yaml'),
                'w+') do |file|
        file.write(":default:\n  :keypair_name: nova_local\n  :data: no effect")
      end
      File.open(File.join(PrcLib.data_path, 'accounts', 'test1'),
                'w+') do |file|
        file.write(":credentials:\n  :keypair_name: nova_test1\n  "\
                   ":tenant_name: test\n  :data: ac_data")
      end

      @account = Lorj::Account.new
    end

    it 'account.exist?(:keypair_name) return true, stored only in local.' do
      expect(@account.exist?(:keypair_name)).to equal(true)
    end

    it "account[:keypair_name] return 'nova_local', stored only in local." do
      expect(@account[:keypair_name]).to eq('nova_local')
    end

    it 'account.where?(:keypair_name) return %w(local default)' do
      expect(@account.where?(:keypair_name)).to eq(%w(local default))
    end

    it 'account.where?(:keypair_name, :names => %w(default)) '\
       'return %w(default)' do
      expect(@account.where?(:keypair_name,
                             :names => %w(default))).to eq(%w(default))
    end

    it 'account.where?(:keypair_name, :names => %w(runtime account)) '\
       'return false' do
      expect(@account.where?(:keypair_name,
                             :names => %w(runtime account))).to equal(false)
    end

    it 'account.where?(:keypair_name, :names => %w(default runtime default)) '\
       'return %w(default default)' do
      expect(@account.where?(:keypair_name,
                             :names => %w(default runtime
                                          default))).to eq(%w(default default))
    end

    it 'account.where?(:keypair_name, :names => %w(default runtime)) '\
       'return %w(default)' do
      expect(@account.where?(:keypair_name,
                             :names => %w(default runtime))).to eq(%w(default))
    end

    it 'account.where?(:keypair_name, :names => %w(runtime default)) '\
       'return %w(default)' do
      expect(@account.where?(:keypair_name,
                             :names => %w(runtime default))).to eq(%w(default))
    end

    it "after account.local_del(:keypair_name) value is 'default_key'" do
      expect(@account.local_del(:keypair_name)).to eq('nova_local')
      expect(@account.where?(:keypair_name)).to eq(%w(default))
      expect(@account[:keypair_name]).to eq('default_key')
    end

    it 'account.exist?(:data) return false, stored only in local.' do
      expect(@account.exist?(:data)).to equal(false)
    end

    it "account[:data] return 'nova_local', stored only in local." do
      expect(@account[:data]).to eq(nil)
    end
    it 'account.where?(:data) return false, as account not loaded.' do
      expect(@account.where?(:data)).to equal(false)
    end
  end

  context "Key      | runtime | accounts   | local     | default)\n"\
          "  :keypair | none    | nova_test1 | nova_local| default_key\n"\
          "  :data    | none    | ac_data    | no effect | None\n"\
          "  :data is account exclusive\n  => accounts/test1 not set:" do
    before(:all) do
      @account = Lorj::Account.new
    end
    it 'account.load return true' do
      expect(@account.ac_load 'test1').to equal(true)
      expect(@account.where?(:data)).to eq(%w(account))
    end

    it "account[:data] = 'value' return 'value'" do
      expect(@account[:data] = 'value').to eq('value')
      expect(@account.where?(:data)).to eq(%w(runtime account))
    end

    it 'runtime data structure is valid' do
      runtime = @account.config_dump(%w(runtime))
      expect(runtime).to eq(:data => 'value')
    end

    it "account[:data] return 'value'" do
      expect(@account[:data]).to eq('value')
    end

    it 'account.where?(:keypair_name) return %w(account local default)' do
      expect(@account.where?(:keypair_name)).to eq(%w(account local default))
    end
    it "account[:keypair_name] = 'value' return 'value'" do
      expect(@account[:keypair_name] = 'value').to eq('value')
      expect(@account.where?(:keypair_name)).to eq(%w(runtime account local
                                                      default))
    end

    it "account.del(:keypair_name) return 'value'" do
      expect(@account.del(:keypair_name)).to eq('value')
      expect(@account.where?(:keypair_name)).to eq(%w(account local default))
    end

    it "account.get(:keypair_name) return back default value 'nova_test1'" do
      expect(@account.get(:keypair_name)).to eq('nova_test1')
    end

    it "account.set(:keypair_name, 'nova_test2', :name => 'account') return "\
       " 'nova_test2'" do
      expect(@account.set(:keypair_name, 'nova_test2',
                          :name => 'account')).to eq('nova_test2')
      expect(@account.where?(:keypair_name)).to eq(%w(account local default))
    end

    it "account.get(:keypair_name, :name => 'account') return 'nova_test2'" do
      expect(@account.get(:keypair_name,
                          :name => 'account')).to eq('nova_test2')
    end

    it 'account.ac_save return false - '\
       'file has no valid provider name' do
      expect(@account.ac_save).to equal(false)
    end

    it 'set provider name' do
      expect(@account.set(:provider, 'myprovider',
                          :name => 'account',
                          :section => :account)).to eq('myprovider')
    end

    it 'account.ac_save return true' do
      expect(@account.ac_save).to equal(true)
    end

    it 'account.ac_new return true, and :data disappeared.' do
      expect(@account.ac_new 'test1').to equal(true)
      expect(@account.where?(:data)).to eq(%w(runtime))
    end

    it 'account.load return true, and :data is back' do
      expect(@account.ac_load 'test1').to equal(true)
      expect(@account.where?(:data)).to eq(%w(runtime account))
    end

    it "account.get(:keypair_name, :name => 'account') return "\
       "saved 'nova_test2'" do
      expect(@account.get(:keypair_name,
                          :name => 'account')).to eq('nova_test2')
    end
  end
end
