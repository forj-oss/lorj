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

require 'lorj'

# If you want to see what is happening in the framework, uncomment debug
# settings.
# PrcLib.level = Logger::DEBUG # Printed out to your console.
# PrcLib.core_level = 3 # framework debug levels.

# Initialize the framework
processes = [File.join(app_path, 'process', 'students.rb')]

student_core = Lorj::Core.new(nil, processes)

# Ask the framework to create the object student 'Robert Redford'
student_core.create(:student, :student_name => 'Robert Redford')
