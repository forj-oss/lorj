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

# require 'rubygems'
#  require 'byebug'
#  require 'debugger'
# require 'bundler/setup'

app_path = File.dirname(__FILE__)

$LOAD_PATH << File.join(app_path, '..', 'lib')

require 'lorj' # Load lorj framework

describe 'Lorj::Process,' do
  context 'Lorj::ProcessResource,' do
    before(:all) do
      @lorj_spec = 'lorj-spec'
      @process_path = File.expand_path(File.join(app_path, '..', @lorj_spec))
    end

    it 'default initialization is ok' do
      process_file = File.join(@process_path, 'process', 'mock_process.rb')
      controllers = { 'mock' => File.join(@process_path, 'process', 'mock',
                                          'controllers', 'mock', 'mock.rb') }
      default = File.join(@process_path, 'process', 'mock', 'defaults.yaml')
      data = File.join(@process_path, 'process', 'mock', 'data.yaml')
      process_data = Lorj::ProcessResource.new('mock', @process_path)
      expect(process_data).to be
      expect(process_data.name).to eq('mock')
      expect(process_data.process).to eq(process_file)
      expect(process_data.controllers).to eq(controllers)
      expect(process_data.defaults_file).to eq(default)
      expect(process_data.data_file).to eq(data)
    end

    it 'reports missing elements not set' do
      process_data = Lorj::ProcessResource.new('mock', app_path)
      expect(process_data).to be
      expect(process_data.name).to equal(nil)
      expect(process_data.process).to equal(nil)
      expect(process_data.controllers).to equal(nil)
      expect(process_data.defaults_file).to equal(nil)
      expect(process_data.data_file).to equal(nil)
    end

    it 'accepts symbol as name, but converted.' do
      process_file = File.join(@process_path, 'process', 'mock_process.rb')
      controllers = { 'mock' => File.join(@process_path, 'process', 'mock',
                                          'controllers', 'mock', 'mock.rb') }
      default = File.join(@process_path, 'process', 'mock', 'defaults.yaml')
      data = File.join(@process_path, 'process', 'mock', 'data.yaml')
      process_data = Lorj::ProcessResource.new(:mock, @process_path)
      expect(process_data).to be
      expect(process_data.name).to eq('mock')
      expect(process_data.process).to eq(process_file)
      expect(process_data.controllers).to eq(controllers)
      expect(process_data.defaults_file).to eq(default)
      expect(process_data.data_file).to eq(data)
    end

    it 'initialization with :controllers_dir is ok' do
      controllers = { 'mock2' => File.join(@process_path, 'process', 'mock',
                                           'providers', 'mock2', 'mock2.rb') }

      process_data = Lorj::ProcessResource.new('mock', @process_path,
                                               :controllers_dir => 'providers')
      expect(process_data).to be
      expect(process_data.name).to eq('mock')
      expect(process_data.controllers).to eq(controllers)
    end

    it 'initialization with :controllers_path is ok' do
      controller_path = File.join(@process_path, 'providers_extra')
      controllers = { 'mock3' => File.join(controller_path,
                                           'mock3', 'mock3.rb') }
      process_data = Lorj::ProcessResource.new('mock', @process_path,
                                               :controllers_path =>
                                                 controller_path)
      expect(process_data).to be
      expect(process_data.controllers).to eq(controllers)
    end

    it 'initialization with :default_file is ok' do
      defaults_file = File.join(@process_path, 'defaults.yaml')
      process_data = Lorj::ProcessResource.new('mock', @process_path,
                                               :defaults_file => defaults_file)
      expect(process_data).to be
      expect(process_data.defaults_file).to eq(defaults_file)
    end

    it 'initialization with :data_file is ok' do
      data_file = File.join(@process_path, 'process', 'mock', 'data.yaml')
      process_data = Lorj::ProcessResource.new('mock', @process_path,
                                               :data_file => data_file)
      expect(process_data).to be
      expect(process_data.data_file).to eq(data_file)
    end
  end

  context('Lorj.declare_process, ') do
    before(:all) do
      @lorj_spec = 'lorj-spec'
      @process_path = File.expand_path(File.join(app_path, '..', @lorj_spec))
    end

    it 'can declare a module process' do
      expect(Lorj.declare_process('mock', @process_path)).to be
    end

    it 'kept module in Lorj.processes' do
      expect(Lorj.processes.key?('mock')).to equal(true)
      expect(Lorj.processes['mock'].class).to equal(Lorj::ProcessResource)
    end

    it 'Lorj.declare_process, can declare several module processes' do
      expect(Lorj.declare_process('mock', @process_path)).to be
      expect(Lorj.declare_process(:mock2, @process_path)).to be
      expect(Lorj.declare_process('mock3', @process_path)).to equal(nil)
    end

    it 'become empty, if name or process_path are incorrect' do
      expect(Lorj.declare_process(nil, @process_path)).to equal(nil)
      expect(Lorj.declare_process('mock', nil)).to equal(nil)
    end

    it 'all kept module processes in Lorj.processes not duplicated.' do
      expect(Lorj.processes.length).to eq(2)
      expect(Lorj.processes.keys).to eq(%w(mock mock2))
    end
  end
end
