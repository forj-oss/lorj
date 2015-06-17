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

# This spec manipulate Lorj and PrcLib module
#
# In the context on a complete rspec run (rake spec)
# modules required are loaded once only.
# So, PrcLib will need to be reloaded (load) with the spec addon.

# spec_helper added:
# PrcLib.spec_cleanup, to simply cleanup the library loaded.
# This is easier than unload module and reload them later with load from all
# Files which update PrcLib.
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

describe 'Module PrcLib: ' do
  after(:all) do
    Object.send(:remove_const, :PrcLib)
    load File.join(app_path, '..', 'lib', 'prc.rb') # Load prc
    load File.join(app_path, '..', 'lib', 'logging.rb') # Load logging
    load File.join(app_path, '..', 'lib', 'lorj.rb') # Load prc
    load File.join(app_path, 'spec_helper.rb') # Reload spec PrcLib addon
  end

  it 'load Lorj and PrcLib Modules' do
    expect(Lorj).to be
    expect(PrcLib).to be
  end

  it 'lib_path is set' do
    file = File.expand_path(File.join(app_path, '..', 'lib'))
    expect(PrcLib.lib_path).to eq(file)
  end

  it 'default app is lorj and cannot be updated.' do
    stop
    PrcLib.spec_cleanup
    expect(PrcLib.app_name).to eq('lorj')
    PrcLib.app_name = 'lorj-spec'
    expect(PrcLib.app_name).to eq('lorj')
  end

  it 'after load cleanup, set default app to lorj-spec is ok' do
    Object.send(:remove_const, :PrcLib)
    load File.join(app_path, '..', 'lib', 'prc.rb') # Load lorj framework
    PrcLib.app_name = 'lorj-spec'
    expect(PrcLib.app_name).to eq('lorj-spec')
  end

  it 'default pdata_path to ~/.config/lorj, and not updatable' do
    Object.send(:remove_const, :PrcLib)
    load File.join(app_path, '..', 'lib', 'prc.rb') # Load lorj framework
    file = File.expand_path(File.join('~', '.config', PrcLib.app_name))
    expect(PrcLib.pdata_path).to eq(file)
    PrcLib.pdata_path = File.join('~', '.test')
    expect(PrcLib.pdata_path).to eq(file)
  end

  it 'after load cleanup, set default pdata_path to ~/.test is ok.' do
    Object.send(:remove_const, :PrcLib)
    load File.join(app_path, '..', 'lib', 'prc.rb') # Load lorj framework
    file = File.expand_path(File.join('~', '.test'))
    PrcLib.pdata_path = file
    expect(PrcLib.pdata_path).to eq(file)
  end

  it 'default data_path to ~/.config/lorj, and not updatable' do
    Object.send(:remove_const, :PrcLib)
    load File.join(app_path, '..', 'lib', 'prc.rb') # Load lorj framework
    file = File.expand_path(File.join('~', '.lorj'))
    expect(PrcLib.data_path).to eq(file)
    PrcLib.data_path = File.join('~', '.test')
    expect(PrcLib.data_path).to eq(file)
  end

  it 'after load cleanup, set default data_path to ~/.test is ok.' do
    Object.send(:remove_const, :PrcLib)
    load File.join(app_path, '..', 'lib', 'prc.rb') # Load lorj framework
    file = File.expand_path(File.join('~', '.test'))
    PrcLib.data_path = file
    expect(PrcLib.data_path).to eq(file)
  end

  it 'model is initialized automatically.' do
    expect(PrcLib.model).to be
    expect(PrcLib.model.class).to be(Lorj::Model)
  end

  it 'app_defaults is nil (no defaults)' do
    expect(PrcLib.app_defaults).to equal(nil)
  end

  it 'app_defaults is set and not updatable' do
    file = File.expand_path(File.join('~', 'src', 'lorj'))
    PrcLib.app_defaults = file
    expect(PrcLib.app_defaults).to eq(file)
    PrcLib.app_defaults = File.expand_path(File.join('~', '.test'))
    expect(PrcLib.app_defaults).to eq(file)
  end
end
