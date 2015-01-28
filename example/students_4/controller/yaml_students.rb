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

# when you declare this controller with a file name, lorj expect this file
# to contains the controller code and the controller definition.
# The code have to be declared in a class which is named as follow from the file
# name:
#   1st letter is capitalized
#   A '_' followed by a letterif replaced by the capicatl letter.
#   Ex: my_code.rb => assume to declare MyCode class
#
# The controller code class is built from the source file name as explained
# below + 'Controller'
#  Ex: my_code.rb => assume to use MyCodeController for controller handlers and
#                    functions.
#
# The controller definition class is build from the file name only.
#  Ex: my_code.rb => assume to use MyCode for controller definition.

# This class describes how to process some actions, and will do everything prior
# this task to make it to work.

# declare yaml student API to the controller
cur_path = File.expand_path(File.dirname(__FILE__))
api_file = File.join(cur_path, '..', '..', 'yaml_students', 'yaml_students.rb')

require api_file

# The controller is a combination of 2 elements:
# - Controller class
#   Code which will interfere with the external API.
#
controller_file = File.join(cur_path, 'yaml_students_code.rb')
require controller_file # Load controller mapping

# - Definition class
#   This class declare any kind of mapping or additional attributes to consider.
require File.join(cur_path, 'yaml_students_def.rb')
