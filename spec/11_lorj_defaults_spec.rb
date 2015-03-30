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

app_path = File.dirname(__FILE__)

$LOAD_PATH << File.join(app_path, '..', 'lib')

require 'lorj' # Load lorj framework

describe 'class: Lorj::Default loaded lorj_spec/defaults.yaml, '\
         'no controller data,' do
  context 'from PrcLib module,' do
    before(:all) do
      log_file = File.expand_path(File.join('~', 'lorj-rspec.log'))
      File.delete(log_file) if File.exist?(log_file)

      PrcLib.log_file = log_file
      PrcLib.level = Logger::FATAL
      PrcLib.app_name = 'lorj-spec'
      PrcLib.app_defaults = File.expand_path(File.join(app_path, '..',
                                                       'lorj-spec'))
    end

    it 'PrcLib.defaults returns a Lorj::Defaults instance.' do
      expect(Lorj.defaults).to be
      expect(Lorj.defaults.class).to equal(Lorj::Defaults)
    end
  end

  context 'Default instance' do
    before(:all) do
      @defaults = Lorj.defaults
    end

    context 'Features to be removed at version 2.0,' do
      # TODO: Feature to be removed at version 2.0.
      it 'meta_each provides list of section/key/values' do
        @defaults.meta_each do |section, key, values|
          expect([:credentials, :maestro].include?(section))
          expect([:keypair_name, :data, :maestro_url].include?(key))
          expect([nil, { :account_exclusive => true }].include?(values))
        end
      end

      it 'meta_exist?(:data) return true' do
        expect(@defaults.meta_exist?(:data)).to equal(true)
      end

      it 'meta_exist?(:test1) return false' do
        expect(@defaults.meta_exist?(:test1)).to equal(false)
      end

      it 'get_meta_auto(:data) return {:account_exclusive => true}' do
        expect(@defaults.get_meta_auto(:data)).to eq(:account_exclusive => true)
      end

      it 'get_meta(:credentials, :data) return {:account_exclusive => true}' do
        expect(@defaults.get_meta(:credentials,
                                  :data)).to eq(:account_exclusive => true)
      end

      it 'get_meta_section(:data) return :credentials' do
        expect(@defaults.get_meta_section(:data)).to eq(:credentials)
      end

      it 'with :metadata_section => :lorj_default_missing, '\
         'exist?[:default_case] return false' do
        @defaults.data_options(:metadata_section => :lorj_default_missing)
        expect(@defaults.exist?(:default_case)).to equal(false)
      end
    end
    context 'defaults.yaml loaded, with :metadata_section => :lorj_default,' do
      before(:all) do
        @defaults.data_options(:metadata_section => :lorj_default)
      end

      it 'exist?[:default_case] return true' do
        expect(@defaults.exist?(:default_case)).to equal(true)
      end

      it 'exist?[:default_case2] return true' do
        expect(@defaults.exist?(:default_case2)).to equal(true)
      end

      it 'exist?[:default_case3] return false' do
        expect(@defaults.exist?(:default_case3)).to equal(false)
      end

      it 'get[:default_case] return "success"' do
        expect(@defaults[:default_case]).to eq('success')
      end

      it 'get[:default_case2] return "success"' do
        expect(@defaults[:default_case2]).to eq('success')
      end
    end
  end
end
