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
# require 'bundler/setup'

app_path = File.dirname(File.dirname(__FILE__))

$LOAD_PATH << './lib'

# This spec HAVE to the the first one executed!
# Do never create a file or rename this file, which will
# move this spec later in the spec test system
# as soon as a first message is sent, the object gets created.
# Any PrcLib::level should be moved in the first test code executed.
# otherwise, you will break the first test in this file.

describe 'Module: Lorj,' do
  context 'Initializing' do
    it 'PrcLib module exist' do
      require 'lorj' # Load lorj framework
      expect(PrcLib.class).to equal(Module)

      expect(PrcLib.log).to be_nil
    end

    it 'create PrcLib.log object at first message' do
      PrcLib.log_file = 'lorj-rspec.log'
      PrcLib.level = Logger::FATAL
      PrcLib.app_name = 'lorj-spec'
      PrcLib.app_defaults = File.join(app_path, 'lorj-spec')

      PrcLib.debug 'Rspec logging ...'

      expect(PrcLib.log).to_not be_nil
    end
  end
end
