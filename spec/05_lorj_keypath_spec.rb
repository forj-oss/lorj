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

describe 'Lorj::KeyPath' do
  context '.new(:test)' do
    before(:all) do
      @o_key = Lorj::KeyPath.new(:test)
    end
    it '#length return 1' do
      expect(@o_key.length).to eq(1)
    end
    it '#to_s return "test"' do
      expect(@o_key.to_s).to eq('test')
    end
    it '#key return :test' do
      expect(@o_key.key).to eq(:test)
    end
    it '#key(0) return :test' do
      expect(@o_key.key(0)).to eq(:test)
    end
    it '#key(1) return nil' do
      expect(@o_key.key(1)).to eq(nil)
    end
    it '#fpath return ":test"' do
      expect(@o_key.fpath).to eq(':test')
    end
    it '#tree return :test' do
      expect(@o_key.key).to eq(:test)
    end
    it '#key_tree return :test' do
      expect(@o_key.key_tree).to eq(:test)
    end
  end

  context '.new([:test,:test2,:test3])' do
    before(:all) do
      @o_key = Lorj::KeyPath.new([:test, :test2, :test3])
    end
    it '#length return 3' do
      expect(@o_key.length).to eq(3)
    end
    it '#to_s return "test/test2/test"' do
      expect(@o_key.to_s).to eq('test/test2/test3')
    end
    it '#key return :test3' do
      expect(@o_key.key).to eq(:test3)
    end
    it '#key(0) return :test' do
      expect(@o_key.key(0)).to eq(:test)
    end
    it '#key(1) return :test2' do
      expect(@o_key.key(1)).to eq(:test2)
    end
    it '#fpath return ":test/:test2/:test3"' do
      expect(@o_key.fpath).to eq(':test/:test2/:test3')
    end
    it '#tree return [:test, :test2, :test3]' do
      expect(@o_key.tree).to eq([:test, :test2, :test3])
    end
    it '#key_tree return ":test/:test2/:test"' do
      expect(@o_key.key_tree).to eq(':test/:test2/:test3')
    end
  end

  context '.new([:test, "/", :test3])' do
    before(:all) do
      @o_key = Lorj::KeyPath.new([:test, '/', :test3])
    end
    it '#length return 3' do
      expect(@o_key.length).to eq(3)
    end
    it '#to_s return "test/\//test"' do
      expect(@o_key.to_s).to eq('test/\//test3')
    end
    it '#key return :test3' do
      expect(@o_key.key).to eq(:test3)
    end
    it '#key(0) return :test' do
      expect(@o_key.key(0)).to eq(:test)
    end
    it '#key(1) return "/"' do
      expect(@o_key.key(1)).to eq('/')
    end
    it '#fpath return ":test/\//:test3"' do
      expect(@o_key.fpath).to eq(':test/\//:test3')
    end
    it '#tree return [:test, "/", :test3]' do
      expect(@o_key.tree).to eq([:test, '/', :test3])
    end
    it '#key_tree return ":test/\//:test3"' do
      expect(@o_key.key_tree).to eq(':test/\//:test3')
    end
  end

  context '.new(":test/\//test3")' do
    before(:all) do
      @o_key = Lorj::KeyPath.new(':test/\//test3')
    end
    it 'is equivalent to .new([:test, "/", "test3"])' do
      compare = Lorj::KeyPath.new([:test, '/', 'test3'])
      expect(@o_key.tree).to eq(compare.tree)
    end
  end

  context '.new("test1/test2")' do
    before(:all) do
      @o_key = Lorj::KeyPath.new('test1/test2')
    end
    it '#length return 2' do
      expect(@o_key.length).to eq(2)
    end
    it '#to_s return "test1/test2"' do
      expect(@o_key.to_s).to eq('test1/test2')
    end
    it '#key return "test2"' do
      expect(@o_key.key).to eq('test2')
    end
    it '#key(0) return "test"' do
      expect(@o_key.key(0)).to eq('test1')
    end
    it '#key(1) return "test2"' do
      expect(@o_key.key(1)).to eq('test2')
    end
    it '#fpath return "test1/test2"' do
      expect(@o_key.fpath).to eq('test1/test2')
    end
    it '#tree return %w(test1 test2)' do
      expect(@o_key.tree).to eq(%w(test1 test2))
    end
    it '#key_tree return "test1/test2"' do
      expect(@o_key.key_tree).to eq('test1/test2')
    end
  end

  context '.new(":test")' do
    before(:all) do
      @o_key = Lorj::KeyPath.new(':test')
    end
    it '#length return 1' do
      expect(@o_key.length).to eq(1)
    end
    it '#to_s return "test"' do
      expect(@o_key.to_s).to eq('test')
    end
    it '#key return :test' do
      expect(@o_key.key).to eq(:test)
    end
    it '#key(0) return :test' do
      expect(@o_key.key(0)).to eq(:test)
    end
    it '#key(1) return nil' do
      expect(@o_key.key(1)).to eq(nil)
    end
    it '#fpath return ":test"' do
      expect(@o_key.fpath).to eq(':test')
    end
    it '#tree return [:test]' do
      expect(@o_key.tree).to eq([:test])
    end
    it '#key_tree return :test' do
      expect(@o_key.key_tree).to eq(:test)
    end
  end

  context '.new("test")' do
    before(:all) do
      @o_key = Lorj::KeyPath.new('test')
    end
    it '#length return 1' do
      expect(@o_key.length).to eq(1)
    end
    it '#to_s return "test"' do
      expect(@o_key.to_s).to eq('test')
    end
    it '#key return "test"' do
      expect(@o_key.key).to eq('test')
    end
    it '#key(0) return "test"' do
      expect(@o_key.key(0)).to eq('test')
    end
    it '#key(1) return nil' do
      expect(@o_key.key(1)).to eq(nil)
    end
    it '#fpath return "test"' do
      expect(@o_key.fpath).to eq('test')
    end
    it '#tree return "test"' do
      expect(@o_key.tree).to eq(['test'])
    end
    it '#key_tree return "test"' do
      expect(@o_key.key_tree).to eq('test')
    end
  end

  context '.new(nil)' do
    before(:all) do
      @o_key = Lorj::KeyPath.new(nil)
    end
    it '#length return 0' do
      expect(@o_key.length).to eq(0)
    end
    it '#to_s return nil' do
      expect(@o_key.to_s).to eq(nil)
    end
    it '#key return nil' do
      expect(@o_key.key).to eq(nil)
    end
    it '#key(0) return nil' do
      expect(@o_key.key(0)).to eq(nil)
    end
    it '#key(1) return nil' do
      expect(@o_key.key(1)).to eq(nil)
    end
    it '#fpath return nil' do
      expect(@o_key.fpath).to eq(nil)
    end
    it '#tree return []' do
      expect(@o_key.tree).to eq([])
    end
    it '#key_tree return nil' do
      expect(@o_key.key_tree).to eq(nil)
    end
  end
end
