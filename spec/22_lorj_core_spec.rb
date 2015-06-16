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

app_path = File.dirname(__FILE__)

describe 'Lorj::Core,' do
  context 'Using lorj-spec process, ' do
    process_path = File.expand_path(File.join(app_path, '..', 'lorj-spec'))
    Lorj.declare_process('mock', process_path)
    Lorj.declare_process('mock2', process_path,
                         :controllers_path => File.join(process_path,
                                                        'providers_extra'))
  end

  it 'Lorj::Core.new(nil, :mock) return an error' do
    expect { Lorj::Core.new(nil, :mock) }.to raise_error(Lorj::PrcError)
  end

  it 'Lorj::Core.new(nil, [{ :process_module => :mock}]) gets loaded.' do
    expect(core = Lorj::Core.new(nil, [{ :process_module => :mock }])).to be
    expect(core.config).to be
    expect(core.config.layers.include?('mock')).to equal(true)
    expect(core.config.layer_index('mock')).to equal(4)
    expect(Lorj.data.layers.include?('mock')).to equal(true)
    expect(Lorj.data.layer_index('mock')).to equal(3)
  end
end
