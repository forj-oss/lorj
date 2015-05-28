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
require 'spec_helper'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib/core')

require 'lorj'

describe 'Lorj::ObjectData' do
  context 'initialize with internal false' do
    before(:all) do
      @obj_data = Lorj::ObjectData.new
      @obj_data[[:key1]] = 'value1'
      @obj_data[[:key2, :key22]] = 'value2'
    end
    it 'Test method #[]' do
      expect(@obj_data[[:key1]]).to eq('value1')
      expect(@obj_data[[:key2, :key22]]).to eq('value2')
    end
    it 'Test method #exist?' do
      expect(@obj_data.exist?(:key1)).to eq(true)
      expect(@obj_data.exist?([:key2, :key22])).to eq(true)
      expect(@obj_data.exist?(:otherkey)).to eq(false)
    end
    it 'Test method #<<' do
      h_hash = { :key3 => [:key31, :key32] }
      @obj_data.<< h_hash
      expect(@obj_data[[:key3]]).to eq([:key31, :key32])
    end
    # In version Ruby 1.8, Yaml Hash load is unstable.
    # Seems related to some context, where to_s provides all
    # but the order printed out depends on some context that I do not understand
    if RUBY_VERSION.match(/1\.8/)
      puts "WARNING! Lorj::ObjectData.to_s won't work well on ruby 1.8 : "\
           'Hash is not keys order preserved.'
    else
      it 'Test method #to_s' do
        ref = "-- Lorj::ObjectData --\nhdata:\n{}\nkey1:\nvalue1\nkey2:\n"\
              "{:key22=>\"value2\"}\nkey3:\n[:key31, :key32]\n"
        expect(@obj_data.to_s).to eq(ref)
      end
    end
  end
  context 'initialize with internal true' do
    before(:all) do
      @obj_data = Lorj::ObjectData.new(true)
      @internal_data = Lorj::Data.new
      data = [{ :name => 'toto' }]
      @internal_data.set(data, :list, :name => /^t/) { |oObject| oObject }
    end
    it 'Test method #add' do
      @obj_data.add(@internal_data)
      expect(@obj_data.exist?(:list)).to eq(true)
    end
    it 'Test method #delete' do
      deleted_data = @obj_data.delete(@internal_data)
      expect(@obj_data.exist?(:list)).to eq(false)
      expect(deleted_data.is_registered).to eq(false)
    end
  end
end
