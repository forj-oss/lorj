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

# This spec HAVE to the the first one executed!
# Do never create a file or rename this file, which will
# move this spec later in the spec test system
# as soon as a first message is sent, the object gets created.
# Any PrcLib::level should be moved in the first test code executed.
# otherwise, you will break the first test in this file.

describe 'Module: Lorj,' do
  context 'Initializing' do
    before(:all) do
      rel_name = format('lorj-%d', Process.pid)
      @rel_path = File.join('/tmp', rel_name) if File.exist?('/tmp')
      @rel_path = File.expand_path(File.join('~', rel_name)) if @rel_path.nil?
    end

    after(:all) do
      FileUtils.rm_rf(@rel_path)
    end

    it 'PrcLib module exist' do
      #  require 'lorj' # Load lorj framework
      expect(PrcLib.class).to equal(Module)

      expect(PrcLib.log).to be_nil
    end

    it 'log_file = [...]/lorj-rspec.log creates the path' do
      log = File.join(@rel_path, 'lorj-rspec.log')
      PrcLib.log_file = log
      expect(File.exist?(@rel_path))
    end

    it 'log_file should get absolute path to the file' do
      log = File.join(@rel_path, 'lorj-rspec.log')
      log = File.expand_path(log)
      expect(PrcLib.log_file).to eq(log)
    end

    it 'set logger level' do
      PrcLib.level = Logger::FATAL
      expect(PrcLib.level).to equal(Logger::FATAL)
    end

    it 'create PrcLib.log object at first message' do
      PrcLib.app_name = 'lorj-spec'
      PrcLib.app_defaults = File.join(File.dirname(app_path), 'lorj-spec')

      PrcLib.debug 'Rspec logging ...'

      expect(PrcLib.log).to_not be_nil
    end
  end
end
