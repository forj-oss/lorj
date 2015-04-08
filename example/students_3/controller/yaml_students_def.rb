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

# Declare
# - additional objects and their specific process (:connection using basic
# predefined :controller_create process)
# - data_mapping :
#   :connection_string => :file_name
#   :course            => :training
#
# If some meta objects attributes has been added by the controller,
# the main program and the GENERIC process will ignore them.
#
# If your controller will requires to have some data in this specific controller
# attributes, you will have 2 options:
# - Write a controller process which can take care of those new attributes
#   This controller process will need to execute the original GENERIC process
#   and then complete the task, with specific controller process to set
#   these specific controller attributes.
# - Set it up, using lorj setup function, if the data is declared setup-able by
#   the controller.
#   The controller can define how the setup have to ask values, and even can get
#   data from the GENERIC process.
class YamlStudents
  # This is a new object which is known by the controller only.
  # Used to open the yaml file. Generically, I named it :connection.
  # But this can be any name you want. Only the controller will deal with it.
  define_obj(:connection,
             # Nothing complex to do. So, simply call the controller create.
             :create_e => :controller_create
            )

  obj_needs :data,   :connection_string,  :mapping => :file_name
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
  obj_needs :CloudObject,              :connection

  # instead of 'student_name', the yaml API uses 'name'
  def_attr_mapping :student_name, :name

  # This controller will know how to manage a student file with those data.
  # But note that the file can have a lot of more data than what the process
  # usually manage. It is up to you to increase your process to manage more data
  # Then each controller may need to define mapping fields.
  # The example 4 shows those mapping definition.
end
