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
    it 'rh_lexist?(:test) '"\n    => "' 1' do
      expect(@hdata.rh_lexist?(:test)).to eq(1)
    end

    it 'rh_lexist?(:test5) '"\n    => "' 0' do
      expect(@hdata.rh_lexist?(:test5)).to eq(0)
    end

    it 'rh_lexist?(:test, :test2) '"\n    => "' 2' do
      expect(@hdata.rh_lexist?(:test, :test2)).to eq(2)
    end

    it 'rh_lexist?(:test, :test2, :test5) '"\n    => "' 2' do
      expect(@hdata.rh_lexist?(:test, :test2, :test5)).to eq(2)
    end

    it 'rh_lexist?(:test, :test5 ) '"\n    => "' 1' do
      expect(@hdata.rh_lexist?(:test, :test5)).to eq(1)
    end

    it 'rh_lexist? '"\n    => "' 0' do
      expect(@hdata.rh_lexist?).to eq(0)
    end
  end

  context "With { :test => {:test2 => 'value1', :test3 => 'value2'},"\
          ":test4 => 'value3'}" do
    before(:all) do
      @hdata = { :test => { :test2 => 'value1', :test3 => 'value2' },
                 :test4 => 'value3' }
    end
    it 'rh_exist?(:test) '"\n    => "' true' do
      expect(@hdata.rh_exist?(:test)).to equal(true)
    end

    it 'rh_exist?(:test5) '"\n    => "' false' do
      expect(@hdata.rh_exist?(:test5)).to equal(false)
    end

    it 'rh_exist?(:test, :test2) '"\n    => "' true' do
      expect(@hdata.rh_exist?(:test, :test2)).to equal(true)
    end

    it 'rh_exist?(:test, :test2, :test5) '"\n    => "' false' do
      expect(@hdata.rh_exist?(:test, :test2, :test5)).to equal(false)
    end

    it 'rh_exist?(:test, :test5 ) '"\n    => "' false' do
      expect(@hdata.rh_exist?(:test, :test5)).to equal(false)
    end

    it 'rh_exist? '"\n    => "' nil' do
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
    it "rh_get(:test) \n    => {:test2 => 'value1', :test3 => 'value2'}" do
      expect(@hdata.rh_get(:test)).to eq(:test2 => 'value1',
                                         :test3 => 'value2')
    end

    it 'rh_get(:test5) '"\n    => "' nil' do
      expect(@hdata.rh_get(:test5)).to equal(nil)
    end

    it "rh_get(:test, :test2) \n    => 'value1'" do
      expect(@hdata.rh_get(:test, :test2)).to eq('value1')
    end

    it 'rh_get(:test, :test2, :test5) '"\n    => "' nil' do
      expect(@hdata.rh_get(:test, :test2, :test5)).to equal(nil)
    end

    it 'rh_get(:test, :test5) '"\n    => "' nil' do
      expect(@hdata.rh_get(:test, :test5)).to equal(nil)
    end

    it 'rh_get '"\n    => "' original data' do
      expect(@hdata.rh_get).to eq(:test => { :test2 => 'value1',
                                             :test3 => 'value2' },
                                  :test4 => 'value3')
    end
  end

  context 'With hdata = {}' do
    before(:all) do
      @hdata = {}
    end
    it 'rh_set(:test) '"\n    => "' nil, with no change to hdata.' do
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
    it 'rh_del(:test) '"\n    => "' nil, with no change to hdata.' do
      expect(@hdata.rh_del(:test)).to equal(nil)
      expect(@hdata).to eq(:test2 => { :test5 => :test,
                                       'text' => 'blabla' },
                           :test5 => :test)
    end

    it 'rh_del(:test, :test2) '"\n    => "' nil, with no change to hdata.' do
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

  context 'with orig = {:data1 => {:prop1 => :val1}}' do
    before(:all) do
      @orig = { :data1 => { :prop1 => :val1 } }
    end

    it 'rh_merge(:data2 => {:prop1 => :val2}) '"\n    => "' '\
       '{:data1 => {:prop1 => :val1}, :data2 => {:prop1 => :val2}}' do
      expect(@orig.rh_merge(:data2 => { :prop1 => :val2 }
                           )).to eq(:data1 => { :prop1 => :val1 },
                                    :data2 => { :prop1 => :val2 })
    end

    it 'rh_merge(:data1 => {:prop1 => :val2}) '"\n    => "' '\
       '{:data1 => {:prop1 => :val2}}' do
      expect(@orig.rh_merge(:data1 => { :prop1 => :val2 }
                           )).to eq(:data1 => { :prop1 => :val2 })
    end

    it 'rh_merge(:data1 => {:prop1 => :unset}) '"\n    => "' '\
       '{:data1 => {}}' do
      expect(@orig.rh_merge(:data1 => { :prop1 => :unset }
                           )).to eq(:data1 => {})
    end

    it 'rh_merge(:data1 => {:__protected => [:prop1],'\
                           ':prop1 => :unset}) '"\n    => "' '\
       '{:data1 => {:__protected => [:prop1]}}' do
      expect(@orig.rh_merge(:data1 => { :__protected => [:prop1],
                                        :prop1 => :unset }
                           )).to eq(:data1 => { :__protected => [:prop1] })
    end

    it 'rh_merge(:data1 => :val2) '"\n    => "' '\
       '{:data1 => {:prop1 => :val1}}' do
      expect(@orig.rh_merge(:data1 => :val2
                           )).to eq(:data1 => { :prop1 => :val1 })
    end

    it 'rh_merge(:data1 => :unset) '"\n    => "' '\
       '{:data1 => {:prop1 => :val1}}' do
      expect(@orig.rh_merge(:data1 => :unset
                           )).to eq(:data1 => { :prop1 => :val1 })
    end

    it 'rh_merge(:data1 => {:prop1 => {}}) '"\n    => "' '\
        ':data1 => {:prop1 => :val1}}' do
      expect(@orig.rh_merge(:data1 => { :prop1 => {} }
                           )).to eq(:data1 => { :prop1 => :val1 })
    end
  end

  context 'with orig = [:data1, :data2, :data3]' do
    before(:all) do
      @orig = [:data1, :data2, :data3]
    end

    # Replace index 0
    it 'rh_merge([:data4])'\
       "\n    => "'[{:__control => true}, :data4, :data2, :data3]' do
      expect(@orig.rh_merge([:data4])
            ).to eq([{ :__control => true }, :data4, :data2, :data3])
      expect(@orig).to eq([:data1, :data2, :data3])
    end

    # add :data4 at the end
    it 'rh_merge([{:__add => [:data4]}])'"\n    => "'[{:__control => true},'\
                                            ':data1, :data2, :data3, :data4]' do
      expect(@orig.rh_merge([{ :__add => [:data4] }])
            ).to eq([{ :__control => true }, :data1, :data2, :data3, :data4])
    end

    # add :data4 at index 3
    it 'rh_merge([:kept, :kept, :kept, :data4])'\
       "\n    => "'[{:__control => true},'\
                                            ':data1, :data2, :data3, :data4]' do
      expect(@orig.rh_merge([{ :__add => [:data4] }])
            ).to eq([{ :__control => true }, :data1, :data2, :data3, :data4])
    end

    # add :data4 at index 3
    it 'rh_merge([{:__add_index => {3 => [:data4]}}]) '\
       ''"\n    => "'[{:__control => true}, :data1, :data2, :data3, :data4]' do
      expect(@orig.rh_merge([{ :__add_index => { 3 => [:data4] } }])
            ).to eq([{ :__control => true }, :data1, :data2, :data3, :data4])
    end

    # add :data4, :data5 at index 3
    it 'rh_merge([{:__add_index => {3 => [:data4, :data5]}}]) '\
       "\n    => [{:__control => true}, "\
                   ':data1, :data2, :data3, :data4, :data5]' do
      expect(@orig.rh_merge([{ :__add_index => { 3 => [:data4, :data5] } }])
            ).to eq([{ :__control => true },
                     :data1, :data2, :data3, :data4, :data5])
    end

    # add :data4, :data5 at index 3 or :data6 element => choose :data6
    it 'rh_merge([{:__add_index => {3 => [:data4, :data5]},'\
                  ':__add => [:data6]}]) '\
       ''"\n    => "'[{:__control => true}, :data1, :data2, :data3, :data6]' do
      expect(@orig.rh_merge([{ :__add_index => { 3 => [:data4, :data5] },
                               :__add => [:data6] }])
            ).to eq([{ :__control => true }, :data1, :data2, :data3, :data6])
    end

    # Remove index 1
    it 'rh_merge([{:__remove => [:data2]}])'\
       "\n    => "'[{:__control => true}, '\
       ':data1, :data3]' do
      expect(@orig.rh_merge([{ :__remove => [:data2] }])
            ).to eq([{ :__control => true }, :data1, :data3])
    end

    # replace index 0 and remove index 1
    it 'rh_merge([{:__remove => [:data2]}, :data4])'"\n    => "''\
       ' [{:__control => true}, :data4, :data3]' do
      expect(@orig.rh_merge([{ :__remove => [:data2] }, :data4])
            ).to eq([{ :__control => true }, :data4, :data3])
    end

    # remove index 0
    it 'rh_merge([{:__remove_index => [0]}])'"\n    => "''\
       ' [{:__control => true}, :data2, :data3]' do
      expect(@orig.rh_merge([{ :__remove_index => [0] }])
            ).to eq([{ :__control => true }, :data2, :data3])
    end

    # remove index 0
    it 'rh_merge([{:__remove_index => [0, 0]}])'"\n    => "''\
       ' [{:__control => true}, :data1, :data3]' do
      expect(@orig.rh_merge([{ :__remove_index => [0, 0] }])
            ).to eq([{ :__control => true }, :data2, :data3])
    end

    # remove index 1, 0
    it 'rh_merge([{:__remove_index => [1, 0]}])'\
       "\n    => "'[{:__control => true}, '\
                                                   ':data3]' do
      expect(@orig.rh_merge([{ :__remove_index => [1, 0] }])
            ).to eq([{ :__control => true }, :data3])
    end

    # remove index 0, 1
    it 'rh_merge([{:__remove_index => [0, 1]}])'\
       "\n    => "'[{:__control => true}, '\
                                                   ':data3]' do
      expect(@orig.rh_merge([{ :__remove_index => [0, 1] }])
            ).to eq([{ :__control => true }, :data3])
    end

    # remove element :data3, or index 0 => :data3
    it 'rh_merge([{:__remove_index => [0],'\
                  ':__remove => [:data3]}])'"\n    => "''\
       ' [{:__control => true}, :data1, :data2]' do
      expect(@orig.rh_merge([{ :__remove_index => [0],
                               :__remove => [:data3] }])
            ).to eq([{ :__control => true }, :data1, :data2])
    end

    # replace index 0 and 1. index 0: Refuse to change symbol to Hash
    it 'rh_merge([{:blabla => [:data2]}, :data4])'"\n    => "''\
       ' [{:__control => true}, :data1, :data4, :data3]' do
      expect(@orig.rh_merge([{ :blabla => [:data2] }, :data4])
            ).to eq([{ :__control => true }, :data1, :data4, :data3])
    end

    # replace index 0 and 1. index 0: Refuse to change symbol to Hash
    it 'rh_merge([{:__struct_changing => [0]}, '\
                 '{:blabla => [:data2]}, :data4])'"\n    => "''\
       ' [{:__control => true, :__struct_changing => [0]}, '\
         ':data1, :data4, :data3]' do
      expect(@orig.rh_merge([{ :__struct_changing => [0] },
                             { :blabla => [:data2] },
                             :data4])
            ).to eq([{ :__control => true, :__struct_changing => [0] },
                     :data1, :data4, :data3])
    end

    # update control on @config
    it 'rh_merge!([{:__struct_changing => [0]}])'"\n    => "''\
       ' [{:__control => true, :__struct_changing => [0]}, '\
         ':data1, :data2, :data3]' do
      expect(@orig.rh_merge!([{ :__struct_changing => [0] }])
            ).to eq([{ :__control => true, :__struct_changing => [0] },
                     :data1, :data2, :data3])

      expect(@orig).to eq([{ :__control => true, :__struct_changing => [0] },
                           :data1, :data2, :data3])
    end

    # See struct_changing working
    it 'rh_merge!([{:blabla => [:data2]}])'"\n    => "''\
       ' [{:__control => true, :__struct_changing => [0]}, '\
         '{:blabla => [:data2]}, :data2, :data3,  :data4]' do
      expect(@orig.rh_merge!([{ :blabla => [:data2] }])
            ).to eq([{ :__control => true, :__struct_changing => [0] },
                     { :blabla => [:data2] }, :data2, :data3])
    end

    # See recursivity in place.
    it 'rh_merge([{:blabla => [:data2]}])'"\n    => "''\
       ' [{:__control => true, :__struct_changing => [0]},
          {:blabla => [{:__control=>true}, :data1], '\
          ':test => :ok }, '\
         ':data2, :data3]' do
      expect(@orig.rh_merge([{ :blabla => [:data1], :test => :ok }])
            ).to eq([{ :__control => true, :__struct_changing => [0] },
                     { :blabla => [{ :__control => true },
                                   :data1],
                       :test => :ok },
                     :data2, :data3])
    end
  end

  context 'with orig = {:__struct_changing => [:data1], '\
                  ':data1 => {:prop1 => :val1}}' do
    before(:all) do
      @orig = { :__struct_changing => [:data1], :data1 => { :prop1 => :val1 } }
    end

    it 'rh_merge(:data1 => :val2) '"\n    => "' '\
       '{:__struct_changing => [:data1], '\
        ':data1 => :val2}' do
      expect(@orig.rh_merge(:data1 => :val2
                           )).to eq(:__struct_changing => [:data1],
                                    :data1 => :val2)
    end

    it 'rh_merge(:data1 => {}) '"\n    => "' '\
       '{:__struct_changing => [:data1], '\
        ':data1 => { :prop1 => :val1 }}' do
      expect(@orig.rh_merge(:data1 => {}
                           )).to eq(:__struct_changing => [:data1],
                                    :data1 => { :prop1 => :val1 })
    end

    it 'rh_merge(:data1 => {:prop1 => :unset}) '"\n    => "' '\
       '{:__struct_changing => [:data1], '\
        ':data1 => {}}' do
      expect(@orig.rh_merge(:data1 => { :prop1 => :unset }
                           )).to eq(:__struct_changing => [:data1],
                                    :data1 => {})
    end

    it 'rh_merge(:data1 => :unset) '"\n    => "' '\
       '{:__struct_changing => [:data1]}' do
      expect(@orig.rh_merge(:data1 => :unset
                           )).to eq(:__struct_changing => [:data1])
    end

    it 'rh_merge(:data2 => {:prop1 => :val2}) '"\n    => "' '\
       '{:__struct_changing => [:data1], '\
        ':data1 => {:prop1 => :val1}, '\
        ':data2 => {:prop1 => :val2}}' do
      expect(@orig.rh_merge(:data2 => { :prop1 => :val2 }
                           )).to eq(:__struct_changing => [:data1],
                                    :data1 => { :prop1 => :val1 },
                                    :data2 => { :prop1 => :val2 })
    end

    it 'rh_merge(:__struct_changing => [{:__add => [:data2]}], '\
                     ':data2 => {:prop1 => :val2}) '"\n    => "' '\
       '{:__struct_changing => [:data1, :data2], '\
        ':data1 => {:prop1 => :val1}, '\
        ':data2 => {:prop1 => :val2}}' do
      expect(@orig.rh_merge(:__struct_changing => [{ :__add => [:data2] }],
                            :data2 => { :prop1 => :val2 }
                           )).to eq(:__struct_changing => [:data1, :data2],
                                    :data1 => { :prop1 => :val1 },
                                    :data2 => { :prop1 => :val2 })
    end

    it 'rh_merge(:__struct_changing => [{:__remove => [:data1]}, :data2], '\
                     ':data2 => {:prop1 => :val2}) '"\n    => "' '\
       '{:__struct_changing => [:data1, :data2], '\
        ':data1 => {:prop1 => :val1}, '\
        ':data2 => {:prop1 => :val2}}' do
      expect(@orig.rh_merge(:__struct_changing => [{ :__remove => [:data1] },
                                                   :data2],
                            :data2 => { :prop1 => :val2 })
            ).to eq(:__struct_changing => [:data2],
                    :data1 => { :prop1 => :val1 },
                    :data2 => { :prop1 => :val2 })
    end

    it 'rh_merge(:__struct_changing => [{:__remove => [:data1]}, :data2], '\
                     ':data1 => :unset,'\
                     ':data2 => {:prop1 => :val2}) '"\n    => "' '\
       '{:__struct_changing => [:data1, :data2], '\
        ':data2 => {:prop1 => :val2}}' do
      expect(@orig.rh_merge(:__struct_changing => [{ :__remove => [:data1] },
                                                   :data2],
                            :data1 => :unset,
                            :data2 => { :prop1 => :val2 }
                           )).to eq(:__struct_changing => [:data2],
                                    :data2 => { :prop1 => :val2 })
    end
  end

  context 'with orig = {:data1 => {:__protected => [:prop1], '\
          ':prop1 => :val1}}' do
    before(:all) do
      @orig = { :data1 => { :__protected => [:prop1], :prop1 => :val1 } }
    end

    it 'rh_merge(:data2 => {:prop1 => :val2}) '"\n    => "' '\
       '{:data1 => {:prop1 => :val1}, :data2 => {:prop1 => :val2}}' do
      expect(@orig.rh_merge(:data2 => { :prop1 => :val2 }
                           )).to eq(:data1 => { :__protected => [:prop1],
                                                :prop1 => :val1 },
                                    :data2 => { :prop1 => :val2 })
    end

    it 'rh_merge(:data1 => {:prop1 => :val2}) '"\n    => "' '\
       '{:data1 => {:prop1 => :val1}}' do
      expect(@orig.rh_merge(:data1 => { :prop1 => :val2 }
                           )).to eq(:data1 => { :__protected => [:prop1],
                                                :prop1 => :val1 })
    end

    it 'rh_merge(:data1 => {:prop1 => :unset}) '"\n    => "' '\
       '{:data1 => {:prop1 => :val1}}' do
      expect(@orig.rh_merge(:data1 => { :prop1 => :unset }
                           )).to eq(:data1 => { :__protected => [:prop1],
                                                :prop1 => :val1 })
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
    it 'rh_key_to_symbol?(1) '"\n    => "' false' do
      expect(@hdata.rh_key_to_symbol?(1)).to equal(false)
    end
    it 'rh_key_to_symbol?(2) '"\n    => "' true' do
      expect(@hdata.rh_key_to_symbol?(2)).to equal(true)
    end
    it 'rh_key_to_symbol?(3) '"\n    => "' true' do
      expect(@hdata.rh_key_to_symbol?(3)).to equal(true)
    end
    it 'rh_key_to_symbol?(4) '"\n    => "' true' do
      expect(@hdata.rh_key_to_symbol?(4)).to equal(true)
    end

    it 'rh_key_to_symbol(1) '"\n    => "' no diff' do
      expect(@hdata.rh_key_to_symbol(1)
            ).to eq(:test => { :test2 => { :test5 => :test,
                                           'text' => 'blabla' },
                               'test5' => 'test' })
    end
    it 'rh_key_to_symbol(2) '"\n    => "' "test5" is replaced by :ẗest5' do
      expect(@hdata.rh_key_to_symbol(2)
            ).to eq(:test => { :test2 => { :test5 => :test,
                                           'text' => 'blabla' },
                               :test5 => 'test' })
    end
    it 'rh_key_to_symbol(3) '"\n    => "' "test5" replaced by :ẗest5, '\
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
