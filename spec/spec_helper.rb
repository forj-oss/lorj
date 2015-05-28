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

require 'rubygems'
if ENV['RSPEC_DEBUG'] == 'true'
  if /1\.8/ =~ RUBY_VERSION
    require 'ruby-debug'
    Debugger.start
    alias stop debugger # rubocop: disable Style/Alias
  elsif /1\.9/ =~ RUBY_VERSION
    require 'debugger'
    alias stop debugger # rubocop: disable Style/Alias
  else
    require 'byebug'
    alias stop byebug # rubocop: disable Style/Alias
  end
else
  def stop
  end
end
