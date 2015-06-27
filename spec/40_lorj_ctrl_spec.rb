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

describe 'Controller features' do
  context 'internal filters' do
    before(:all) do
      # BaseControllerSpec
      class BaseControllerSpec < Lorj::BaseController
        def self.def_internal(name)
          spec_name = 'spec_' + name

          # To call the function identified internally with 'spec' prefix
          define_method(spec_name) do |*p|
            send(name, *p)
          end
        end

        # Internal function to test.
        def_internal 'lorj_filter_regexp'
        def_internal 'lorj_filter_array'
        def_internal 'lorj_filter_hash'
        def_internal 'lorj_filter_default'
      end
      PrcLib.spec_cleanup
      PrcLib.data_path = File.join(app_path, '..', 'lorj-spec', 'data')
      @o = BaseControllerSpec.new
    end

    it 'lorj_filter_default(..., ...) is accepted'\
       ' (treated = false)' do
      expect(@o.spec_lorj_filter_default('', '')[0]).to equal(true)
      expect(@o.spec_lorj_filter_default('', //)[0]).to equal(true)
      expect(@o.spec_lorj_filter_default([], '')[0]).to equal(true)
      expect(@o.spec_lorj_filter_default({}, '')[0]).to equal(true)
    end

    it "lorj_filter_default('test2', 'test') return [true, false]" do
      expect(@o.spec_lorj_filter_default('test2',
                                         'test')[1]).to equal(false)
    end

    it "lorj_filter_default('test', 'test') return [true, true]" do
      expect(@o.spec_lorj_filter_default('test', 'test')[1]).to equal(true)
    end

    it "lorj_filter_regexp('test2', ... except Regexp) is not recognized"\
       ' (treated = false)' do
      expect(@o.spec_lorj_filter_regexp('', '')[0]).to equal(false)
      expect(@o.spec_lorj_filter_regexp('', //)[0]).to equal(true)
      expect(@o.spec_lorj_filter_regexp([], '')[0]).to equal(false)
      expect(@o.spec_lorj_filter_regexp({}, '')[0]).to equal(false)
    end

    it "lorj_filter_regexp('test2', /toto/) not match" do
      expect(@o.spec_lorj_filter_regexp('test2', /toto/)[1]).to equal(false)
    end

    it "lorj_filter_regexp('test2', /test/) match" do
      expect(@o.spec_lorj_filter_regexp('test2', /test/)[1]).to equal(true)
    end

    it "lorj_filter_array(... except Array, '') is not recognized"\
       ' (treated = false)' do
      expect(@o.spec_lorj_filter_array('', '')[0]).to equal(false)
      expect(@o.spec_lorj_filter_array('', //)[0]).to equal(false)
      expect(@o.spec_lorj_filter_array([], '')[0]).to equal(true)
      expect(@o.spec_lorj_filter_array({}, '')[0]).to equal(false)
    end

    it "lorj_filter_array(['test2', :toto], 'test') not match" do
      expect(@o.spec_lorj_filter_array(['test2', :toto],
                                       'test')[1]).to equal(false)
    end

    it "lorj_filter_array(['test2', :toto], 'test2') match" do
      expect(@o.spec_lorj_filter_array(['test2', :toto],
                                       'test2')[1]).to equal(true)
    end

    it "lorj_filter_array(['test2', :toto], []) match" do
      expect(@o.spec_lorj_filter_array(['test2', :toto],
                                       [])[1]).to eq(true)
    end

    it "lorj_filter_array(['test2', :toto], [:test]) not match" do
      expect(@o.spec_lorj_filter_array(['test2', :toto],
                                       [:test])[1]).to equal(false)
    end

    it "lorj_filter_array(['test2', :toto], [:test]) match" do
      expect(@o.spec_lorj_filter_array(['test2', :toto],
                                       [:toto])[1]).to equal(true)
    end

    it "lorj_filter_array(['test2', :toto], [:toto, 'test2']) match" do
      expect(@o.spec_lorj_filter_array(['test2', :toto],
                                       [:toto, 'test2'])[1]).to equal(true)
    end

    it "lorj_filter_hash(... except Hash, '') is not recognized "\
       '(treated = false)' do
      expect(@o.spec_lorj_filter_hash('', '')[0]).to equal(false)
      expect(@o.spec_lorj_filter_hash('', //)[0]).to equal(false)
      expect(@o.spec_lorj_filter_hash([], '')[0]).to equal(false)
      expect(@o.spec_lorj_filter_hash({}, '')[0]).to equal(true)
    end

    it "lorj_filter_hash({:test => 'value'}, :test2) not match" do
      data = { :test => 'value' }
      expect(@o.spec_lorj_filter_hash(data, :test2)[1]).to equal(false)
    end

    it "lorj_filter_hash({:test => 'value'}, :test) not match" do
      data = { :test => 'value' }
      expect(@o.spec_lorj_filter_hash(data, :test)[1]).to equal(false)
    end

    it "lorj_filter_hash({:test => 'value'}, ':test/:toto') not match" do
      data = { :test => 'value' }
      expect(@o.spec_lorj_filter_hash(data, ':test/:toto')[1]).to equal(false)
    end

    it "lorj_filter_hash({:test => 'value'}, [:test, 'value']) not match" do
      data = { :test => 'value' }
      expect(@o.spec_lorj_filter_hash(data, [:test, 'value'])[1]).to equal(true)
      expect(@o.spec_lorj_filter_hash(data, ':test/value')[1]).to equal(true)
    end

    it "lorj_filter_hash({:test => {:toto => 'value'}}, "\
       "':test/:toto/value') match" do
      data = { :test => { :toto => 'value' } }
      expect(@o.spec_lorj_filter_hash(data,
                                      ':test/:toto/value')[1]).to equal(true)
      expect(@o.spec_lorj_filter_hash(data,
                                      [:test, :toto,
                                       'value'])[1]).to equal(true)
    end
  end
  context 'Data extract' do
    before(:all) do
      # BaseControllerSpec
      class BaseControllerSpec < Lorj::BaseController
        def self.def_internal(name)
          spec_name = 'spec_' + name

          # To call the function identified internally with 'spec' prefix
          define_method(spec_name) do |*p|
            if p[-1].is_a?(Proc)
              proc = p.pop
              send(name, *p) { |*a| proc.call(*a) }
            else
              send(name, *p)
            end
          end
        end

        # Internal function to test.
        def_internal 'ctrl_query_each'
        def_internal '_run_trigger'
        def_internal 'ctrl_do_query_match'
        def_internal '_get_from'
        def_internal '_get_from_func'
      end

      # TestData
      class TestData
        attr_accessor :attr1, :attr2

        def initialize(attr1, attr2)
          @attr1 = attr1
          @attr2 = attr2
        end

        def all
          { :attr1 => @attr1, :attr2 => @attr2 }
        end
      end
      @o = BaseControllerSpec.new
      @data = TestData.new('value1', 'value2')
      @list = [@data, TestData.new('value3', 'value4'),
               { :attr1 => 'value5', :attr2 => 'value6' },
               { :attr1 => 'value7', :attr2 => 'value6' }]
    end

    it '_get_from_func(data) works' do
      expect(@o.spec__get_from_func(@data, 'attr1')).to eq([true, 'value1'])
      expect(@o.spec__get_from_func(@data, :attr1)).to eq([true, 'value1'])
      expect(@o.spec__get_from_func(@data, :attr3)).to eq([false, nil])
      expect(@o.spec__get_from_func(@data, :attr2)).to eq([true, 'value2'])
      expect(@o.spec__get_from_func(@data, :'@attr2',
                                    :instance_variable_get)
            ).to eq([true, 'value2'])
    end

    it '_get_from(data, *key) works' do
      expect(@o.spec__get_from(@data, :attr1)).to eq([true, 'value1'])
      expect(@o.spec__get_from(@list[1], :attr1)).to eq([true, 'value3'])
      # Uses [] internally
      expect(@o.spec__get_from(@list[2], :attr1)).to eq([true, 'value5'])
      expect(@o.spec__get_from(@data, :all, :attr1)).to eq([true, 'value1'])
      expect(@o.spec__get_from(@data, :diff, lambda do |o, *k|
        o.attr1 if k[0] == :diff
      end)).to eq([true, 'value1'])
    end

    it 'ctrl_do_query_match works' do
      expect(@o.spec_ctrl_do_query_match(@data,
                                         {})).to equal(true)
      expect do
        @o.spec_ctrl_do_query_match(@data, :attr3 => '')
      end.to raise_error(Lorj::PrcError)

      expect(@o.spec_ctrl_do_query_match(@data,
                                         :attr1 => 'value1')).to equal(true)
      expect(@o.spec_ctrl_do_query_match(@data,
                                         :attr1 => 'value1',
                                         :attr2 => 'value3')).to equal(false)
      expect(@o.spec_ctrl_do_query_match(@data,
                                         :attr1 => 'value1',
                                         :attr2 => /value$/)).to equal(false)
      expect(@o.spec_ctrl_do_query_match(@data,
                                         :attr1 => 'value1',
                                         :attr2 => /value/)).to equal(true)
      expect(@o.spec_ctrl_do_query_match(@data,
                                         :attr1 => 'value1',
                                         :attr2 => 'value2')).to equal(true)
    end

    it '_run_trigger works' do
      def trigger1(*p)
        p
      end

      def trigger2(*_p)
        true
      end
      triggers = { :trig1 => method(:trigger1), :trig2 => method(:trigger2) }

      expect(@o.spec__run_trigger({}, :blabla, [], nil)).to equal(nil)
      expect(@o.spec__run_trigger({}, :blabla, [], true)).to equal(true)
      expect(@o.spec__run_trigger(triggers, :blabla, [], nil)).to equal(nil)

      expect(@o.spec__run_trigger(triggers, :trig1, [], nil,
                                  'value1')).to eq(%w(value1))
      expect(@o.spec__run_trigger(triggers, :trig1, [FalseClass], nil,
                                  'value1')).to eq(nil)
      expect(@o.spec__run_trigger(triggers, :trig2, [FalseClass, TrueClass],
                                  nil, 'value1')).to eq(true)
    end

    it 'ctrl_query_each works' do
      expect(@o.spec_ctrl_query_each(@list,
                                     :attr1 => /value/,
                                     :attr2 => 'value6').length).to eq(2)
      expect(@o.spec_ctrl_query_each(@list,
                                     :attr1 => 'value',
                                     :attr2 => 'value6').length).to eq(0)
    end
  end
end
