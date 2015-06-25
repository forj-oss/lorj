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

require 'lorj'

# Define some spec addon
module PrcLib
  module_function

  # Attribute app_name
  #
  # app_name is set to 'lorj' if not set.
  #
  def spec_cleanup
    instance_variables.each do |v|
      # @lib_path is set by require 'lorj'. We should never update it.
      # @core_level is set by require 'lorj'. We should never update it.
      next if [:'@lib_path', :'@core_level'].include?(v)
      instance_variable_set(v, nil)
    end
  end

  def to_s
    a = {}
    instance_variables.each do |v|
      a[v] = instance_variable_get(v)
    end
    a
  end
end

# Define some spec addon
module Lorj
  module_function

  # Attribute app_name
  #
  # app_name is set to 'lorj' if not set.
  #
  def spec_cleanup
    instance_variables.each do |v|
      # @lib_path is set by require 'lorj'. We should never update it.
      # @core_level is set by require 'lorj'. We should never update it.
      next if [:'@lib_path', :'@core_level'].include?(v)
      instance_variable_set(v, nil)
    end
  end

  def to_s
    a = {}
    instance_variables.each do |v|
      a[v] = instance_variable_get(v)
    end
    a
  end
end

RSpec.configure do |config|
  config.before(:all, &:silence_output)
  config.after(:all,  &:enable_output)
end

public

# Redirects stderr and stout to /dev/null.txt
def silence_output
  # Store the original stderr and stdout in order to restore them later
  @original_stderr = $stderr
  @original_stdout = $stdout

  # Redirect stderr and stdout
  $stderr = File.open(File.join('', 'dev', 'null'), 'w')
  $stdout = File.open(File.join('', 'dev', 'null'), 'w')
end

# Replace stderr and stdout so anything else is output correctly
def enable_output
  $stderr = @original_stderr
  $stdout = @original_stdout
  @original_stderr = nil
  @original_stdout = nil
end
