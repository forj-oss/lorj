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
require 'ansi'

$APP_PATH = File.dirname(__FILE__)

require File.join($APP_PATH, 'yaml_students.rb')

school = YamlSchool.new('/tmp/students.yaml')

puts ANSI.bold("Create 1st student:")
if school.query_student({:name => "Robert Redford"}).length == 0
   school.create_student("Robert Redford", {
      first_name: 'Robert',
      last_name:  'Redford',
      training:   'Art Comedy'
   })
end

puts ANSI.bold("Create 2nd student:")
if school.query_student({:name => "Anthony Hopkins"}).length == 0
   school.create_student("Anthony Hopkins", {
      first_name: 'Anthony',
      last_name:  'Hopkins',
      training:   'Art Drama'
   })
end

puts ANSI.bold("Create 3rd student:")
if school.query_student({:name => "Marilyn Monroe"}).length == 0
   school.create_student("Marilyn Monroe", {
      first_name: 'Marilyn',
      last_name:  'Mistake',
      training:   'Art Drama'
   })
end

puts ANSI.bold("Create mistake")
oStudent = school.create_student("Anthony Mistake", {
   first_name: 'Anthony',
   last_name:  'Mistake',
   training:   'what ever you want!!!'
})

puts "Student created: '%s'" % oStudent

puts ANSI.bold("Remove mistake")
result = school.query_student({:name => "Anthony Mistake"})
if result.length > 0
   result.each { | student |
      puts "Wrong student to remove: %s = %s" % [student[:id], student[:name]]
      school.delete_student(student[:id])
   }
end


puts ANSI.bold("List of students for 'Art Drama':")
puts school.query_student({ :training => "Art Drama"})

puts ANSI.bold("Deleted students:")
puts school.query_student({ :status => :removed})
