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


# This class describes how to process some actions, and will do everything prior
# this task to make it to work.

# This Mock controller keep the data in memory in hash/Array data.

# declare yaml student API to the controller
cur_path = File.dirname(__FILE__)
api_file = File.expand_path(File.join(cur_path, "..", "..", "yaml_students", 'yaml_students.rb'))
require api_file

# The controller is a combination of 2 elements:
# - Controller class
#   Code which will interfere with the external API.
#
#   The file name must respect the name of the class. 1st letter already capitalized and letter after _ is capitalized.
#   file: my_code.rb => needs to create MyCodeController class
#
# - Definition class
#   This class declare any kind of mapping or additional fields to consider.
#   Additionnal fields are unknow by the process. So, those fields will needs to be setup before.
#
#   file name convention is identical than controller class.
#   file: my_code.rb => needs to create MyCode class

controller_file = File.expand_path(File.join(cur_path,'yaml_students_controller.rb'))
require controller_file # Load controller mapping

# Declare
# - additional objects and their specific process (:connection using basic predefined :controller_create process)
# - data_mapping :
#   :connection_string => :file_name
#   :course            => :training
#
# If some data has been added by the controller, the main and process, won't take care and the framework will fails.
# To eliminate this errors, there is 2 cases:
# - detect this change in the process or the main.
# - set it up, using lorj setup function, if the data is declared askable by the controller.
#   The controller can define how the setup have to ask values, and even can get data
#   from itself.

class YamlStudents

   define_obj(:connection,{
      :create_e => :controller_create # Nothing complex to do. So, simply call the controller create.
   })

   obj_needs   :data,   :connection_string,  :mapping => :file_name
   undefine_attribute :id    # Do not return any predefined ID
   undefine_attribute :name  # Do not return any predefined NAME

   # The student model has been expanded. The object name will be built from first and last name
   define_obj(:student)
   obj_needs   :CloudObject,              :connection

   set_hdata   :first_name
   set_hdata   :last_name
   set_hdata   :course,      :mapping => :training

   get_attr_mapping :course, :training

   # This controller will know how to manage a student file with those data.
   # But note that the file can have a lot of more data than what the process
   # usually manage. It is up to you to increase your process to manage more data.
   # Then each controller may need to define mapping fields.
end