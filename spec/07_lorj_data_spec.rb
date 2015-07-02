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

describe 'Lorj::Data' do
  context 'initialize' do
    it 'data.type? == :object by default' do
      expect(Lorj::Data.new).to be
      data = Lorj::Data.new
      expect(data.type).to equal(:object)
      expect(data.object_type?).to equal(nil)
      expect(data.empty?).to equal(true)
    end

    it 'data.type? == :list if requested' do
      expect(Lorj::Data.new :list).to be
      data = Lorj::Data.new :list
      expect(data.type).to equal(:list)
      expect(data.object_type?).to equal(nil)
      expect(data.empty?).to equal(true)
    end
  end

  context 'as :object' do
    before(:all) do
      # Spec testing for process refresh
      class SpecObject < Lorj::BaseDefinition
        def initialize
        end

        def process_refresh(*_p)
          true
        end
      end
      @spec_object = SpecObject.new
      @data = Lorj::Data.new
    end

    it 'data.object_type?'
    it 'data.set(...)'
    it 'data.exist?'
    it 'data.empty?'
    it 'data.type'
    it 'data.type = '
    it 'data.get'
    it 'data[...]'
    it 'data.length'
    it 'data.each'
    it 'data.each_index'
    it 'data.to_a'
    it 'data.is_registered'
    it 'data.register'
    it 'data.unregister'

    it 'data.base = BaseDefinition instance should expose process_refresh' do
      expect(@data.refresh).to equal(false)
      expect(@data.base = @spec_object).to equal(@spec_object)
      expect(@data.refresh).to equal(false)
      data = { :test => 'toto' }
      @data.set(data, :test) { |_t, o| o }
      # It requires data and process to refresh itself.
      expect(@data.refresh).to equal(true)
    end
  end
end
