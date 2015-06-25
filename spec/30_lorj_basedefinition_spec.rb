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
      # Spec class for BaseDefinition
      class BaseDefinitionSpec < Lorj::BaseDefinition
        def initialize
        end

        def self.def_internal(name)
          spec_name = 'spec' + name

          # To call the function identified internally with 'spec' prefix
          define_method(spec_name) do |*p|
            send(name, *p)
          end
        end

        # Internal function to test.
        def_internal '_get_encrypt_key'
        def_internal '_get_encrypted_value_hidden'
        def_internal '_account_map'
      end

      @spec_obj = BaseDefinitionSpec.new

      PrcLib.pdata_path = File.join(app_path, 'lorj-spec')
      @key_file = File.join(PrcLib.pdata_path, '.key')
      File.delete(@key_file) if File.exist?(@key_file)
    end

    after(:all) do
      File.delete(@key_file) if File.exist?(@key_file)
    end

    it 'Lorj::SSLCrypt.new_encrypt_key return a new entr hash' do
      ret = Lorj::SSLCrypt.new_encrypt_key
      expect(ret.class).to equal(Hash)
      expect(ret.keys.sort).to eq([:key, :salt, :iv].sort)
      expect(ret[:key].class).to equal(String)
      expect(ret[:salt].class).to equal(String)
      expect(ret[:iv].class).to equal(String)
    end

    it '_get_encrypt_key return entr, .key file created' do
      ret = @spec_obj.spec_get_encrypt_key
      expect(ret.class).to equal(Hash)
      expect(ret.keys.sort).to eq([:key, :salt, :iv].sort)
      expect(ret[:key].class).to equal(String)
      expect(ret[:salt].class).to equal(String)
      expect(ret[:iv].class).to equal(String)
      expect(File.exist?(@key_file)).to equal(true)
      expect(@spec_obj.spec_get_encrypt_key).to eq(ret)
    end

    it 'Lorj::SSLCrypt.encrypt_value return a strict base64 data' do
      to_enc = 'Data to encrypt'
      entr = @spec_obj.spec_get_encrypt_key
      ret = Lorj::SSLCrypt.encrypt_value(to_enc, entr)

      expect(Base64.strict_decode64(ret).class).to eq(String)
      expect(ret).to eq(Lorj::SSLCrypt.encrypt_value(to_enc, entr))
    end

    it 'Lorj::SSLCrypt.get_encrypted_value return is decryptable' do
      to_enc = 'Data to encrypt'
      entr = @spec_obj.spec_get_encrypt_key
      ret = Lorj::SSLCrypt.encrypt_value(to_enc, entr)

      expect(Lorj::SSLCrypt.get_encrypted_value(ret, entr,
                                                'value')).to eq(to_enc)
    end

    it '_get_encrypted_value_hidden string contains count of * equal to '\
       'original value' do
      to_enc = 'Data to encrypt'
      entr = @spec_obj.spec_get_encrypt_key
      ret = Lorj::SSLCrypt.encrypt_value(to_enc, entr)
      hidden = @spec_obj.spec_get_encrypted_value_hidden('value', ret, entr)

      expect(hidden.include?('*')).to equal(true)
      expect('*' * to_enc.length).to eq(hidden)
    end
  end
end
