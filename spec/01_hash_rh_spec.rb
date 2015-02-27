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

#  require 'byebug'

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rh'

describe 'Recursive Hash/Array extension,' do
  context "With { :test => {:test2 => 'value1', :test3 => 'value2'},"\
          ":test4 => 'value3'}" do
    before(:all) do
      @hdata = { :test => { :test2 => 'value1', :test3 => 'value2' },
                 :test4 => 'value3' }
    end
    it 'rh_lexist?(:test) return 1' do
      expect(@hdata.rh_lexist?(:test)).to eq(1)
    end

    it 'rh_lexist?(:test5) return 0' do
      expect(@hdata.rh_lexist?(:test5)).to eq(0)
    end

    it 'rh_lexist?(:test, :test2) return 2' do
      expect(@hdata.rh_lexist?(:test, :test2)).to eq(2)
    end

    it 'rh_lexist?(:test, :test2, :test5) return 2' do
      expect(@hdata.rh_lexist?(:test, :test2, :test5)).to eq(2)
    end

    it 'rh_lexist?(:test, :test5 ) return 1' do
      expect(@hdata.rh_lexist?(:test, :test5)).to eq(1)
    end

    it 'rh_lexist? return 0' do
      expect(@hdata.rh_lexist?).to eq(0)
    end
  end

  context "With { :test => {:test2 => 'value1', :test3 => 'value2'},"\
          ":test4 => 'value3'}" do
    before(:all) do
      @hdata = { :test => { :test2 => 'value1', :test3 => 'value2' },
                 :test4 => 'value3' }
    end
    it 'rh_exist?(:test) return true' do
      expect(@hdata.rh_exist?(:test)).to equal(true)
    end

    it 'rh_exist?(:test5) return false' do
      expect(@hdata.rh_exist?(:test5)).to equal(false)
    end

    it 'rh_exist?(:test, :test2) return true' do
      expect(@hdata.rh_exist?(:test, :test2)).to equal(true)
    end

    it 'rh_exist?(:test, :test2, :test5) return false' do
      expect(@hdata.rh_exist?(:test, :test2, :test5)).to equal(false)
    end

    it 'rh_exist?(:test, :test5 ) return false' do
      expect(@hdata.rh_exist?(:test, :test5)).to equal(false)
    end

    it 'rh_exist? return nil' do
      expect(@hdata.rh_exist?).to eq(nil)
    end
  end

  context "With { :test => {:test2 => 'value1', :test3 => 'value2'},"\
          ":test4 => 'value3'}" do
    before(:all) do
      @hdata = { :test => { :test2 => 'value1',
                            :test3 => 'value2' },
                 :test4 => 'value3' }
    end
    it "rh_get(:test) return {:test2 => 'value1', :test3 => 'value2'}" do
      expect(@hdata.rh_get(:test)).to eq(:test2 => 'value1',
                                         :test3 => 'value2')
    end

    it 'rh_get(:test5) return nil' do
      expect(@hdata.rh_get(:test5)).to equal(nil)
    end

    it "rh_get(:test, :test2) return 'value1'" do
      expect(@hdata.rh_get(:test, :test2)).to eq('value1')
    end

    it 'rh_get(:test, :test2, :test5) return nil' do
      expect(@hdata.rh_get(:test, :test2, :test5)).to equal(nil)
    end

    it 'rh_get(:test, :test5) return nil' do
      expect(@hdata.rh_get(:test, :test5)).to equal(nil)
    end

    it 'rh_get return original data' do
      expect(@hdata.rh_get).to eq(:test => { :test2 => 'value1',
                                             :test3 => 'value2' },
                                  :test4 => 'value3')
    end
  end

  context 'With hdata = {}' do
    before(:all) do
      @hdata = {}
    end
    it 'rh_set(:test) return nil, with no change to hdata.' do
      expect(@hdata.rh_set(:test)).to equal(nil)
      expect(@hdata).to eq({})
    end

    it 'rh_set(:test, :test2) add a new element :test2 => :test' do
      expect(@hdata.rh_set(:test, :test2)).to eq(:test)
      expect(@hdata).to eq(:test2 => :test)
    end

    it 'rh_set(:test, :test2, :test5) replace :test2 by :test5 => :test' do
      expect(@hdata.rh_set(:test, :test2, :test5)).to eq(:test)
      expect(@hdata).to eq(:test2 => { :test5 => :test })
    end

    it 'rh_set(:test, :test5 ) add :test5 => :test, colocated with :test2' do
      expect(@hdata.rh_set(:test, :test5)).to equal(:test)
      expect(@hdata).to eq(:test2 => { :test5 => :test },
                           :test5 => :test)
    end

    it "rh_set('blabla', :test2, 'text') add a 'test' => 'blabla' under"\
       ' :test2, colocated with ẗest5 ' do
      expect(@hdata.rh_set('blabla', :test2, 'text')).to eq('blabla')
      expect(@hdata).to eq(:test2 => { :test5 => :test,
                                       'text' => 'blabla' },
                           :test5 => :test)
    end

    it 'rh_set(nil, :test2) remove :test2 value' do
      expect(@hdata.rh_set(nil, :test2)).to equal(nil)
      expect(@hdata).to eq(:test2 => nil,
                           :test5 => :test)
    end
  end

  context 'With hdata = {:test2 => { :test5 => :test,'\
          "'text' => 'blabla' },"\
          ':test5 => :test}' do
    before(:all) do
      @hdata = { :test2 => { :test5 => :test,
                             'text' => 'blabla' },
                 :test5 => :test }
    end
    it 'rh_del(:test) return nil, with no change to hdata.' do
      expect(@hdata.rh_del(:test)).to equal(nil)
      expect(@hdata).to eq(:test2 => { :test5 => :test,
                                       'text' => 'blabla' },
                           :test5 => :test)
    end

    it 'rh_del(:test, :test2) return nil, with no change to hdata.' do
      expect(@hdata.rh_del(:test, :test2)).to eq(nil)
      expect(@hdata).to eq(:test2 => { :test5 => :test,
                                       'text' => 'blabla' },
                           :test5 => :test)
    end

    it 'rh_del(:test2, :test5) remove :test5 keys tree from :test2' do
      expect(@hdata.rh_del(:test2, :test5)).to eq(:test)
      expect(@hdata).to eq(:test2 => { 'text' => 'blabla' },
                           :test5 => :test)
    end

    it 'rh_del(:test5 ) remove :test5' do
      expect(@hdata.rh_del(:test5)).to equal(:test)
      expect(@hdata).to eq(:test2 => { 'text' => 'blabla' })
    end

    it 'rh_del(:test2) remove the :test2. hdata is now {}.'\
       ' :test2, colocated with ẗest5 ' do
      expect(@hdata.rh_del(:test2)).to eq('text' => 'blabla')
      expect(@hdata).to eq({})
    end
  end

  context "With hdata = { :test => { :test2 => { :test5 => :test,\n"\
          "                                        'text' => 'blabla' },\n"\
          "                            'test5' => 'test' },\n"\
          '                 :array => [{ :test => :value1 }, '\
          '2, { :test => :value3 }]}' do
    before(:all) do
      @hdata = { :test => { :test2 => { :test5 => :test,
                                        'text' => 'blabla' },
                            'test5' => 'test' },
                 :array => [{ :test => :value1 }, 2, { :test => :value3 }]
               }
    end
    it 'rh_clone is done without error' do
      expect { @hdata.rh_clone }.to_not raise_error
    end
    it 'hclone[:test] = "test" => hdata[:test] != hclone[:test]' do
      hclone = @hdata.rh_clone
      hclone[:test] = 'test'
      expect(@hdata[:test]).to eq(:test2 => { :test5 => :test,
                                              'text' => 'blabla' },
                                  'test5' => 'test')
    end
    it 'hclone[:array].pop => hdata[:array].length != hclone[:array].length' do
      hclone = @hdata.rh_clone
      hclone[:array].pop
      expect(@hdata[:array].length).not_to eq(hclone[:array].length)
    end

    it 'hclone[:array][0][:test] = "value2" '\
       '=> hdata[:array][0][:test] != hclone[:array][0][:test]' do
      hclone = @hdata.rh_clone
      hclone[:array][0][:test] = 'value2'
      expect(@hdata[:array][0][:test]).to eq(:value1)
    end
  end

  context 'With hdata = { :test => { :test2 => { :test5 => :test,'\
          "'text' => 'blabla' },"\
          "'test5' => 'test' }}" do
    before(:all) do
      @hdata = { :test => { :test2 => { :test5 => :test,
                                        'text' => 'blabla' },
                            'test5' => 'test' } }
    end
    it 'rh_key_to_symbol?(1) return false' do
      expect(@hdata.rh_key_to_symbol?(1)).to equal(false)
    end
    it 'rh_key_to_symbol?(2) return true' do
      expect(@hdata.rh_key_to_symbol?(2)).to equal(true)
    end
    it 'rh_key_to_symbol?(3) return true' do
      expect(@hdata.rh_key_to_symbol?(3)).to equal(true)
    end
    it 'rh_key_to_symbol?(4) return true' do
      expect(@hdata.rh_key_to_symbol?(4)).to equal(true)
    end

    it 'rh_key_to_symbol(1) return no diff' do
      expect(@hdata.rh_key_to_symbol(1)
            ).to eq(:test => { :test2 => { :test5 => :test,
                                           'text' => 'blabla' },
                               'test5' => 'test' })
    end
    it 'rh_key_to_symbol(2) return "test5" is replaced by :ẗest5' do
      expect(@hdata.rh_key_to_symbol(2)
            ).to eq(:test => { :test2 => { :test5 => :test,
                                           'text' => 'blabla' },
                               :test5 => 'test' })
    end
    it 'rh_key_to_symbol(3) return "test5" replaced by :ẗest5, '\
       'and "text" to :text' do
      expect(@hdata.rh_key_to_symbol(3)
            ).to eq(:test => { :test2 => { :test5 => :test,
                                           :text => 'blabla' },
                               :test5 => 'test' })
    end
    it 'rh_key_to_symbol(4) same like rh_key_to_symbol(3)' do
      expect(@hdata.rh_key_to_symbol(4)).to eq(@hdata.rh_key_to_symbol(3))
    end
  end
end
