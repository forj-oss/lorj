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

app_path = File.dirname(__FILE__)
$LOAD_PATH << File.join(app_path, '..', 'lib')

describe 'Module PrcLib: ' do
  after(:all) do
    Object.send(:remove_const, :PrcLib)
    load File.join(app_path, '..', 'lib', 'prc.rb') # Load prc
    load File.join(app_path, '..', 'lib', 'logging.rb') # Load logging
  end

  it 'load Lorj and PrcLib Modules' do
    require 'lorj' # Load lorj framework
    expect(Lorj).to be
    expect(PrcLib).to be
  end

  it 'lib_path is set' do
    file = File.expand_path(File.join(app_path, '..', 'lib'))
    expect(PrcLib.lib_path).to eq(file)
  end

  it 'default app is lorj and cannot be updated.' do
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