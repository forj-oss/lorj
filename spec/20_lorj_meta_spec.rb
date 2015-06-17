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

require 'spec_helper'

describe 'Lorj::MetaAppConfig,' do
  context 'core with sample initialized,' do
    before(:all) do
      data = <<YAMLDOC
---
:setup:
  :ask_step:
  - :desc: 'Small description'
    :explanation: |-
      My complete explanation is in
      multiple lines <%= config['text'] %>
    :add:
    - :key_pair_files
    - :ssh_user
:sections:
  :section1:
    :data1:
      :option1: value1
    :data2:
      :option1: value2
  :section2:
    :data2:
      :option2: value3
  :section3:
    :data3:
      :option3: value4
YAMLDOC
      # MetaAppConfig spec class.
      class MetaAppConfigSpec < Lorj::MetaAppConfig
        def get(options)
          p_get(options)
        end
      end

      @metadata = MetaAppConfigSpec.new YAML.load(data)
    end

    it 'sections returns [:section1, :section2].' do
      # Ruby 1.8 requires to use sort, as Hash do not have order garantee
      expect(@metadata.sections.sort).to eq([:section1, :section2, :section3])
    end

    it 'sections(:data1) returns [:section1].' do
      expect(@metadata.sections(:data1)).to eq([:section1])
    end

    it 'sections(:data2) returns [:section1, :section2].' do
      # Ruby 1.8 requires to use sort, as Hash do not have order garantee
      expect(@metadata.sections(:data2).sort).to eq([:section1, :section2])
    end

    it 'datas returns [:data1, :data2, :data3].' do
      # Ruby 1.8 requires to use sort, as Hash do not have order garantee
      expect(@metadata.datas.sort).to eq([:data1, :data2, :data3].sort)
    end

    if /1\.8/ =~ RUBY_VERSION
      puts "WARNING! first_section(:data2) won't work well on ruby 1.8 : "\
           'Hash is not keys order preserved.'
    else
      it 'first_section(:data2) returns [:section1, :data2]' do
        expect(@metadata.first_section(:data2)).to eq([:section1, :data2])
      end
    end

    it 'first_section("section2#data2") returns [:section2, :data2]' do
      expect(@metadata.first_section('section2#data2')
            ).to eq([:section2, :data2])
    end

    it 'first_section("section3#data2") returns [:section3, :data2]' do
      expect(@metadata.first_section('section3#data2')
            ).to eq([:section3, :data2])
    end

    it 'first_section(:data1) returns [:section1, :data1]' do
      expect(@metadata.first_section(:data1)).to eq([:section1, :data1])
    end

    it 'first_section(:data3) returns [:section3, :data3]' do
      expect(@metadata.first_section(:data3)).to eq([:section3, :data3])
    end

    it 'meta_exist?(:section1, :data1) returns true' do
      expect(@metadata.meta_exist?(:section1, :data1)).to equal(true)
    end

    it 'meta_exist?(:section2, :data1) returns false' do
      expect(@metadata.meta_exist?(:section2, :data1)).to equal(false)
    end

    it 'meta_exist?(:section2, :data2) returns true' do
      expect(@metadata.meta_exist?(:section2, :data2)).to equal(true)
    end

    it 'auto_meta_exist?(:data2) returns true' do
      expect(@metadata.auto_meta_exist?(:data2)).to equal(true)
    end

    it 'auto_meta_exist?(:data3) returns true' do
      expect(@metadata.auto_meta_exist?(:data3)).to equal(true)
    end

    it 'auto_meta_exist?(:data4) returns false' do
      expect(@metadata.auto_meta_exist?(:data4)).to equal(false)
    end

    it 'meta_each provides list of section/key/values' do
      @metadata.meta_each do |section, key, _values|
        expect(@metadata.sections.include?(section))
        expect(@metadata.datas.include?(key))
      end
    end
    it 'parent data[:sections, :section5, :data5] returns nil' do
      expect(@metadata[:sections, :section5, :data5]).to equal(nil)
    end

    it 'data[:sections, :section5, :data5] = {:option5 => value5}' do
      @metadata[:sections, :section5, :data5] = { :option5 => :value5 }
      expect(@metadata[:sections, :section5, :data5]).to eq(:option5 => :value5)
      option = {}
      option[:keys] = [:sections, :section5, :data5, :option5]
      option[:name] = 'app'
      expect(@metadata.get(option)).to equal(nil)
      option[:name] = 'map'
      expect(@metadata.get(option)).to equal(nil)

      # section mapping should be updated.
      expect(@metadata.sections(:data5)).to eq([:section5])
    end

    # To simplify spec code, app layer contains String values for each options
    # while controller options values are Symbol.
    # This helps to identify if the merge works.
    it 'define_controller_data(:section2, :data2, :option2 => :value4) works' do
      data = { :option2 => :value4 }
      expect(@metadata[:sections, :section2, :data2, :option2]).to eq('value3')
      expect(@metadata.define_controller_data(:section2,
                                              :data2, data)).to eq(data)
      # Ruby 1.8 requires to use sort, as Hash do not have order garantee
      expect(@metadata.sections(:data2).sort).to eq([:section1, :section2])
      expect(@metadata[:sections, :section2, :data2, :option2]).to eq(:value4)
    end

    it 'update_controller_data(:section2, :data2, :option3 => value1) works' do
      data = { :option3 => :value1 }
      result = data.clone
      result[:option2] = :value4
      expect(@metadata.update_controller_data(:section2,
                                              :data2, data)).to eq(result)
      expect(@metadata[:sections, :section2, :data2, :option2]).to eq(:value4)
      expect(@metadata[:sections, :section2, :data2, :option3]).to eq(:value1)
    end

    it 'section_data(:section1, :data1) returns {:option1 => "value1"}' do
      expect(@metadata.section_data(:section1, :data1
                                   )).to eq(:option1 => 'value1')
    end

    it 'section_data(:section1, :data1, :option1) returns "value1"' do
      expect(@metadata.section_data(:section1, :data1,
                                    :option1)).to eq('value1')
    end

    it 'section_data(:section2, :data2) returns Merged hash' do
      expect(@metadata.section_data(:section2, :data2
                                   )).to eq(:option2 => :value4,
                                            :option3 => :value1)
      # Expect no change (internal reverse is not impacting)
      expect(@metadata.section_data(:section2, :data2
                                   )).to eq(:option2 => :value4,
                                            :option3 => :value1)
      # 'App' option value already exists and has not been updated.
      option = {}
      option[:keys] = [:sections, :section2, :data2, :option2]
      option[:name] = 'app'
      expect(@metadata.get(option)).to eq('value3')
    end

    it 'With :section3 => :data3 => :option1 => :value1,'\
       ' section_data(:section3, :data3) returns {:option1=>:value1,'\
       ':option3=> "value4"}' do
      @metadata.define_controller_data(:section3,
                                       :data3, :option1 => :value1)
      expect(@metadata.section_data(:section3, :data3
                                   )).to eq(:option1 => :value1,
                                            :option3 => 'value4')
    end

    it 'auto_section_data(:data3) returns {:option1=>:value1,'\
       ':option3=> "value4"}' do
      expect(@metadata.auto_section_data(:data3)).to eq(:option1 => :value1,
                                                        :option3 => 'value4')
    end

    it 'set(:sections, :section6, :data6, {:option6 => :value6}) returns '\
       ':option6 => :value6' do
      expect(@metadata.set(:sections, :section6, :data6,
                           :option6 => :value6)).to eq(:option6 => :value6)

      option = {}
      option[:keys] = [:sections, :section6, :data6, :option6]
      option[:name] = 'app'
      expect(@metadata.get(option)).to equal(nil)
      option[:name] = 'map'
      expect(@metadata.get(option)).to equal(nil)
      option[:name] = 'controller'
      expect(@metadata.get(option)).to eq(:value6)
      expect(@metadata.sections(:data6)).to eq([:section6])
    end

    it 'set(:sections, :section6, :data6, {:option6 => :value7}, "app") '\
       'returns :option6 => :value7. but controller is only updated.' do
      expect(@metadata.set(:sections, :section6, :data6,
                           { :option6 => :value7 },
                           'app')).to eq(:option6 => :value7)

      option = {}
      option[:keys] = [:sections, :section6, :data6, :option6]
      option[:name] = 'app'
      expect(@metadata.get(option)).to equal(nil)
      option[:name] = 'map'
      expect(@metadata.get(option)).to equal(nil)
      option[:name] = 'controller'
      expect(@metadata.get(option)).to eq(:value7)
    end

    it 'set(:any, :kind_of, :data1, {:option1 => :value1}) '\
       'returns :option1 => :value1' do
      expect(@metadata.where?(:any, :kind_of, :data1, :option1)).to equal(false)
      expect(@metadata.set(:any, :kind_of, :data1, :option1 => :value1
                          )).to eq(:option1 => :value1)
      expect(@metadata.where?(:any, :kind_of, :data1,
                              :option1)).to eq(['controller'])
    end

    it 'del(:any, :kind_of, :data1) returns :option1 => :value1 and '\
       'is deleted' do
      expect(@metadata.del(:any, :kind_of, :data1)).to eq(:option1 => :value1)

      expect(@metadata.where?(:any, :kind_of, :data1, :option1)).to equal(false)
    end

    it 'setup_options(:ask_step) returns a merged data' do
      expect(@metadata.setup_options(:ask_step).class).to equal(Array)
      expect(@metadata.setup_options(:ask_step).length).to equal(1)
    end

    it 'setup_data(:ask_step) returns a merged data' do
      data = @metadata.setup_data(:ask_step)
      expect(data.class).to equal(Array)
      expect(data.length).to equal(1)
    end
  end

  context 'from Lorj.data,' do
    it 'gets loaded.' do
      PrcLib.level = Logger::FATAL
      expect(Lorj.data).to be
      expect(Lorj.data.class).to equal(Lorj::MetaAppConfig)
    end
  end
end
