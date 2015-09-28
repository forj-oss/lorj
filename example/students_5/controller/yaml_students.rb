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
# - Definition class
#   This class declare any kind of mapping or additional attributes to consider.
controller_file = File.join(cur_path, 'yaml_students_controller.rb')
require controller_file # Load controller mapping

# Declare
# - additional objects and their specific process (:connection using basic
# predefined :controller_create process)
# - data_mapping :
#   :connection_string => :file_name
#   :course            => :training
#
# If some data has been added by the controller, the main and process,
# won't take care and the framework will fails.
# To eliminate this errors, there is 2 cases:
# - detect this change in the process or the main.
# - set it up, using lorj setup function, if the data is declared askable by
#   the controller.
#   The controller can define how the setup have to ask values, and even can get
#   data from itself.
class YamlStudents
  # This is a new object which is known by the controller only.
  # Used to open the yaml file. Generically, I named it :connection.
  # But this can be any name you want. Only the controller will deal with it.
  define_obj(:connection,
             # Nothing complex to do. So, simply call the controller create.
             :create_e => :controller_create
            )

  obj_needs :data,   :connection_string, :mapping => :file_name
  undefine_attribute :id    # Do not return any predefined ID
  undefine_attribute :name  # Do not return any predefined NAME

  # The student model have to be expanded.
  define_obj(:student)
  # It requires to create a connection to the data, ie opening the yaml file.
  # So, before working with the :student object, the controller requires a
  # connection
  # This connection will be loaded in the memory and provided to the controller
  # when needed.
  # obj_needs :CloudObject update the :student object to requires a connection
  # before.
  obj_needs :CloudObject, :connection

  # To simplify controller wrapper, we use hdata built by lorj, and passed to
  # the API
  # This hdata is a hash containing mapped data, thanks to def_hdata.
  def_hdata :first_name
  def_hdata :last_name
  # Instead of 'course', the yaml API uses 'training'
  def_hdata :course, :mapping => :training

  def_attr_mapping :course, :training
  # instead of 'student_name', the yaml API uses 'name'
  def_attr_mapping :student_name, :name

  # This controller will know how to manage a student file with those data.
  # But note that the file can have a lot of more data than what the process
  # usually manage. It is up to you to increase your process to manage more data
  # Then each controller may need to define mapping fields.
end
