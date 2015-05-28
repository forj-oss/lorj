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

describe 'Lorj::KeyPath,' do
  context 'initialize with :test' do
    before(:all) do
      @o_key = Lorj::KeyPath.new(:test)
    end
    it 'Test method #length' do
      expect(@o_key.length).to eq(1)
    end
    it 'Test method #to_s' do
      expect(@o_key.to_s).to eq('test')
    end
    it 'Test method #key' do
      expect(@o_key.key).to eq(:test)
    end
    it 'Test method #key(0)' do
      expect(@o_key.key(0)).to eq(:test)
    end
    it 'Test method #key(1)' do
      expect(@o_key.key(1)).to eq(nil)
    end
    it 'Test method #fpath' do
      expect(@o_key.fpath).to eq(':test')
    end
    it 'Test method #tree' do
      expect(@o_key.key).to eq(:test)
    end
    it 'Test method #key_tree' do
      expect(@o_key.key_tree).to eq(:test)
    end
  end

  context 'initialize with [:test,:test2,:test3]' do
    before(:all) do
      @o_key = Lorj::KeyPath.new([:test, :test2, :test3])
    end
    it 'Test method #length' do
      expect(@o_key.length).to eq(3)
    end
    it 'Test method #to_s' do
      expect(@o_key.to_s).to eq('test/test2/test3')
    end
    it 'Test method #key' do
      expect(@o_key.key).to eq(:test3)
    end
    it 'Test method #key(0)' do
      expect(@o_key.key(0)).to eq(:test)
    end
    it 'Test method #key(1)' do
      expect(@o_key.key(1)).to eq(:test2)
    end
    it 'Test method #fpath' do
      expect(@o_key.fpath).to eq(':test/:test2/:test3')
    end
    it 'Test method #tree' do
      expect(@o_key.tree).to eq([:test, :test2, :test3])
    end
    it 'Test method #key_tree' do
      expect(@o_key.key_tree).to eq(':test/:test2/:test3')
    end
  end

  context 'initialize with string test1/test2' do
    before(:all) do
      @o_key = Lorj::KeyPath.new('test1/test2')
    end
    it 'Test method #length' do
      expect(@o_key.length).to eq(2)
    end
    it 'Test method #to_s' do
      expect(@o_key.to_s).to eq('test1/test2')
    end
    it 'Test method #key' do
      expect(@o_key.key).to eq('test2')
    end
    it 'Test method #key(0)' do
      expect(@o_key.key(0)).to eq('test1')
    end
    it 'Test method #key(1)' do
      expect(@o_key.key(1)).to eq('test2')
    end
    it 'Test method #fpath' do
      expect(@o_key.fpath).to eq('test1/test2')
    end
    it 'Test method #tree' do
      expect(@o_key.tree).to eq(%w(test1 test2))
    end
    it 'Test method #key_tree' do
      expect(@o_key.key_tree).to eq('test1/test2')
    end
  end

  context 'initialize with string :test' do
    before(:all) do
      @o_key = Lorj::KeyPath.new(':test')
    end
    it 'Test method #length' do
      expect(@o_key.length).to eq(1)
    end
    it 'Test method #to_s' do
      expect(@o_key.to_s).to eq('test')
    end
    it 'Test method #key' do
      expect(@o_key.key).to eq(:test)
    end
    it 'Test method #key(0)' do
      expect(@o_key.key(0)).to eq(:test)
    end
    it 'Test method #key(1)' do
      expect(@o_key.key(1)).to eq(nil)
    end
    it 'Test method #fpath' do
      expect(@o_key.fpath).to eq(':test')
    end
    it 'Test method #tree' do
      expect(@o_key.tree).to eq([:test])
    end
    it 'Test method #key_tree' do
      expect(@o_key.key_tree).to eq(:test)
    end
  end

  context 'initialize with string test' do
    before(:all) do
      @o_key = Lorj::KeyPath.new('test')
    end
    it 'Test method #length' do
      expect(@o_key.length).to eq(1)
    end
    it 'Test method #to_s' do
      expect(@o_key.to_s).to eq('test')
    end
    it 'Test method #key' do
      expect(@o_key.key).to eq('test')
    end
    it 'Test method #key(0)' do
      expect(@o_key.key(0)).to eq('test')
    end
    it 'Test method #key(1)' do
      expect(@o_key.key(1)).to eq(nil)
    end
    it 'Test method #fpath' do
      expect(@o_key.fpath).to eq('test')
    end
    it 'Test method #tree' do
      expect(@o_key.tree).to eq(['test'])
    end
    it 'Test method #key_tree' do
      expect(@o_key.key_tree).to eq('test')
    end
  end

  context 'initialize with nil' do
    before(:all) do
      @o_key = Lorj::KeyPath.new(nil)
    end
    it 'Test method #length' do
      expect(@o_key.length).to eq(0)
    end
    it 'Test method #to_s' do
      expect(@o_key.to_s).to eq(nil)
    end
    it 'Test method #key' do
      expect(@o_key.key).to eq(nil)
    end
    it 'Test method #key(0)' do
      expect(@o_key.key(0)).to eq(nil)
    end
    it 'Test method #key(1)' do
      expect(@o_key.key(1)).to eq(nil)
    end
    it 'Test method #fpath' do
      expect(@o_key.fpath).to eq(nil)
    end
    it 'Test method #tree' do
      expect(@o_key.tree).to eq([])
    end
    it 'Test method #key_tree' do
      expect(@o_key.key_tree).to eq(nil)
    end
  end
end
