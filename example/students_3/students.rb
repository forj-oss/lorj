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

app_path = File.dirname(__FILE__)

if ENV['LORJ_DEV']
  require 'byebug'
  lib_path = File.expand_path(File.join(app_path, '..', '..', 'lib'))
  $LOAD_PATH << lib_path
end
require 'lorj'
require 'ansi'

# Load global Config

# This object is used to provide configuration data to lorj

# The config search is:
# 1- Application defaults (defaults.yaml) - Not defined by default. update the
# following line and create defaults.yaml
# PrcLib.app_defaults = $APP_PATH
# 2- Local defaults (~/.<Application Name>/config.yaml) - <Application Name> is
# 'Lorj' by default. Can be updated with following line.
# PrcLib.app_name = 'myapp'
# 3 - runtime. Those variables are set, with config[key] = value

config = Lorj::Config.new # Use Simple Config Object

# You can use an account object, which add an extra account level
# between runtime and config.yaml/app default
# config = Lorj::Account.new('MyAccount') #

# If you want to see what is happening in the framework, uncomment
# debug settings.
PrcLib.level = Logger::DEBUG # Printed out to your console.
PrcLib.core_level = 5 # framework debug levels.

# Initialize the framework
processes = [File.join(app_path, 'process', 'students.rb')]

# ~ student_core = Lorj::Core.new( config, processes, :mock)
student_core = Lorj::Core.new(config,
                              processes,
                              File.join(app_path,
                                        'controller',
                                        'yaml_students.rb'))

student_core.create(:connection, :connection_string => '/tmp/students.yaml')

puts ANSI.bold('Create 1st student:')

# Set the student name to use
# There is different way to set them...
# Those lines do the same using config object. Choose what you want.
config.set(:first_name, 'Robert')
config[:last_name]    = 'Redford'
config[:student_name] = 'Robert Redford'
config[:course]       = 'Art Comedy'

# Ask the framework to create the object student 'Robert Redford'
student_core.create(:student)

puts ANSI.bold('Create 2nd student:')
# We can set runtime configuration instantly from the Create call
# The following line :
student_core.create(:student,
                    :student_name => 'Anthony Hopkins',
                    :first_name => 'Anthony',
                    :last_name => 'Hopkins',
                    :course => 'Art Drama'
)
# config[:student_name] = "Anthony Hopkins"
# config[:course] = "Art Drama"
# student_core.Create(:student)

puts ANSI.bold('Create 3rd student:')
student_core.create(:student,
                    :student_name => 'Marilyn Monroe',
                    :first_name => 'Marilyn',
                    :last_name => 'Monroe',
                    :course => 'Art Drama'
)
# replaced the following :
# config[:student_name] = "Anthony Hopkins"
# student_core.Create(:student)

puts ANSI.bold('Create mistake')
student = student_core.create(:student,
                              :student_name => 'Anthony Mistake',
                              :first_name => 'Anthony',
                              :last_name => 'Mistake',
                              :course => 'what ever you want!!!'
)

puts format("Student created '%s'", student[:attrs])

# Because the last student was the mistake one, we can directly delete it.
# Usually, we use get instead.
puts ANSI.bold('Remove mistake')
student_core.delete(:student)
puts format('Wrong student to remove: %s = %s',
            student[:id], student[:student_name])

puts ANSI.bold("List of students for 'Art Drama':")
puts student_core.query(:student,  :course => 'Art Drama').to_a

puts ANSI.bold('Deleted students:')
puts student_core.query(:student, :status => :removed).to_a
