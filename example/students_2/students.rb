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

lib_path = File.expand_path(File.join(app_path, '..', '..', 'lib'))
$LOAD_PATH << lib_path

require 'byebug' if ENV['BYEBUG']

require 'lorj'

# If you want to see what is happening in the framework, uncomment debug
# settings.
#  PrcLib.level = Logger::DEBUG # Printed out to your console.
#  PrcLib.core_level = 3 # framework debug levels.

# Initialize the framework
processes = []
processes << { :process_path => File.join(app_path, 'process', 'students.rb'),
               :controller_name => :mock }

#  byebug if ENV['BYEBUG'] # rubocop: disable Debugger
student_core = Lorj::Core.new(nil, processes)
# Ask the framework to create the object student 'Robert Redford'
student_core.create(:student, :student_name => 'Robert Redford')

# Want to create a duplicated student 'Robert Redford'?
student_core.create(:student, :student_name => 'Robert Redford')
# no problem. The key is the key in the Mock controller array.

student_core.create(:student, :student_name => 'Anthony Hopkins')

# Let's create a third different student.
students = student_core.query(:student, :name => 'Robert Redford')

puts format('%s students found', students.length)

students.each do |a_student|
  puts format('%s: %s', a_student[:id], a_student[:name])
end

# let's check the get function, who is the ID 2?
student = student_core.get(:student, 2)

puts format('The student ID 2 is %s', student[:name])
