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

# To debug spec, depending on Ruby version, you may need to install
# 1.8 => ruby-debug
# 1.9 => debugger
# 2.0+ => byebug
# The right debugger should be installed by default by bundle
# So, just call:
#
#     bundle
#
# Then set RSPEC_DEBUG=true, put a 'stop' where you want in the spec code
# and start rspec or even rake spec.
#
#     RSPEC_DEBUG=true rake spec_local (or spec which includes docker spec)
# OR
#     RSPEC_DEBUG=true rspec -f doc --color spec/<file>_spec.rb
#

app_path = File.dirname(__FILE__)
$LOAD_PATH << app_path unless $LOAD_PATH.include?(app_path)
require 'spec_helper'

describe 'Internal BaseDefinition features' do
  context 'From a derived class' do
    before(:all) do
      # Used to help en/decrypting
      class BaseDefinitionSpec < Lorj::BaseDefinition
        def initialize
        end

        def self.def_internal(name)
          spec_name = 's' + name

          # To call the function identified internally with 'spec' prefix
          define_method(spec_name) do |*p|
            send(name, *p)
          end
        end

        # Internal function to test.
        def_internal '_get_encrypt_key'
      end

      # Spec class for ImportExport feature spec
      class ImportExportSpec < Lorj::BaseDefinition
        # Simplified BaseDefinition class for spec only
        def initialize(config)
          @config = config
        end

        def self.def_internal(name)
          spec_name = 'spec' + name

          # To call the function identified internally with 'spec' prefix
          define_method(spec_name) do |*p|
            send(name, *p)
          end
        end

        # Internal function to test.
        def_internal '_account_map'
      end

      PrcLib.spec_cleanup
      Lorj.spec_cleanup
      PrcLib.app_name = 'lorj-rspec'
      PrcLib.pdata_path = File.join(app_path, '..', 'lorj-spec', 'cache')
      PrcLib.data_path = File.join(app_path, '..', 'lorj-spec', 'data')

      @config = Lorj::Account.new
      @spec_obj = ImportExportSpec.new(@config)

      process_path = File.expand_path(File.join(app_path, '..', 'lorj-spec'))
      Lorj.declare_process('mock', process_path, :lib_name => 'lorj')

      @core = Lorj::Core.new(@config, [{ :process_module => :mock,
                                         :controller_name => :mock }])

      @key_file = File.join(PrcLib.pdata_path, '.key')
      @crypt = BaseDefinitionSpec.new
      @config[:keypair_name] = 'another_key'
    end

    it '_account_map return {} as no account loaded.' do
      expect(@spec_obj.spec_account_map).to eq({})
    end

    it 'Load test account and _account_map return valid data.' do
      # Load lorj-spec/data/accounts/test.yaml
      expect(@config.ac_load 'test.yaml').to equal(true)
      res = %w(credentials#key credentials#keypair_name)
      expect(@spec_obj.spec_account_map.keys.sort).to eq(res)
      expect(@spec_obj.spec_account_map['credentials#key']).to eq({})
    end

    it 'account_export() returns valid [entr, export_dat]' do
      export = @spec_obj.account_export
      expect(export.class).to equal(Array)
      entr, export_dat = export
      expect(export_dat.key?(:enc_data)).to equal(true)
      expect(export_dat.key?(:processes)).to equal(true)
      expect(export_dat[:processes].class).to equal(Array)
      expect(export_dat[:processes][0].key?(:process_module)).to equal(true)
      expect(export_dat[:processes][0].key?(:lib_name)).to equal(true)
      dat_decrypted = Lorj::SSLCrypt.get_encrypted_value(export_dat[:enc_data],
                                                         entr, 'data encrypted')
      expect(dat_decrypted.class).to equal(String)
      data = YAML.load(dat_decrypted)
      expect(data.rh_exist?(:account, :name)).to equal(true)
      expect(data.rh_get(:account, :name)).to eq('test')
      expect(data.rh_exist?(:credentials, :keypair_name)).to equal(true)
      expect(data.rh_get(:credentials, :keypair_name)).to eq('mykey')
      expect(data.rh_exist?(:credentials, :key)).to equal(true)
      expect(data.rh_get(:credentials, :key)).to eq('DataEncrypted')
    end

    it 'account_export(nil, false) returns account@name and credentials#key' do
      entr, export_dat = @spec_obj.account_export(nil, false)
      dat_decrypted = Lorj::SSLCrypt.get_encrypted_value(export_dat[:enc_data],
                                                         entr, 'data encrypted')
      data = YAML.load(dat_decrypted)
      expect(data.rh_exist?(:account, :name)).to equal(false)
      expect(data.rh_exist?(:credentials, :key)).to equal(true)
    end

    it 'account_export(nil, false, false) returns "runtime" keypair_name'\
       ' value' do
      entr, export_dat = @spec_obj.account_export(nil, false, false)
      dat_decrypted = Lorj::SSLCrypt.get_encrypted_value(export_dat[:enc_data],
                                                         entr, 'data encrypted')
      data = YAML.load(dat_decrypted)
      expect(data.rh_exist?(:credentials, :keypair_name)).to equal(true)
      expect(data.rh_get(:credentials, :keypair_name)).to eq('another_key')
    end

    it 'account_export({"credentials#key" => {}}) returns key, '\
       'name & provider' do
      entr, export_dat = @spec_obj.account_export('credentials#key' => {})
      dat_decrypted = Lorj::SSLCrypt.get_encrypted_value(export_dat[:enc_data],
                                                         entr, 'data encrypted')
      data = YAML.load(dat_decrypted)
      expect(data.rh_exist?(:credentials, :keypair_name)).to equal(false)
      expect(data.rh_exist?(:credentials, :key)).to equal(true)
      expect(data.rh_exist?(:account, :name)).to equal(true)
    end

    it 'account_export({"credentials#key" => {:keys => [:server, :key]}})'\
       ' returns ' do
      map = { 'credentials#key' => { :keys => [:server, :key] } }
      entr, export_dat = @spec_obj.account_export(map)
      dat_decrypted = Lorj::SSLCrypt.get_encrypted_value(export_dat[:enc_data],
                                                         entr, 'data encrypted')
      data = YAML.load(dat_decrypted)
      expect(data.rh_exist?(:credentials, :key)).to equal(false)
      expect(data.rh_exist?(:server, :key)).to equal(true)
      expect(data.rh_exist?(:account, :name)).to equal(true)
    end

    it 'account_data_import(data) update the "account layer"' do
      entr, export_dat = @spec_obj.account_export
      @config.ac_erase
      dat_decrypted = Lorj::SSLCrypt.get_encrypted_value(export_dat[:enc_data],
                                                         entr, 'data encrypted')
      data = YAML.load(dat_decrypted)
      res = @spec_obj.account_data_import(data)
      expect(res.class).to equal(Hash)
      expect(@config['account#name']).to eq('test')
      expect(@config[:keypair_name]).to eq('another_key')
      expect(@config.get(:keypair_name, nil,
                         :name => 'account')).to eq('mykey')
    end

    it 'Lorj.account_import(entr, enc_hash) update the "account layer"' do
      entr, export_dat = @spec_obj.account_export
      core = Lorj.account_import(entr, export_dat)
      expect(core).to be
      expect(core.config['account#name']).to eq('test')
      expect(core.config[:keypair_name]).to eq('mykey')
      expect(core.config.get(:keypair_name, nil,
                             :name => 'account')).to eq('mykey')
    end
  end
end
