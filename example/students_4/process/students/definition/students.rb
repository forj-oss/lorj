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

# In this version 4, The process will ensure a student is created only if
# missing and remove duplicates.

# Declaring your data model and handlers.
class Lorj::BaseDefinition # rubocop: disable Style/ClassAndModuleChildren
  # We need to define the student object and the handler to use while we need to
  # create it.
  define_obj(:student,
             # The function to call in the class Students
             :create_e => :create_student,
             # We use predefined call to the controller query
             :query_e => :controller_query,
             # We use predefined call to the controller get
             :get_e => :controller_get,
             # We use predefined call to the controller delete
             :delete_e => :controller_delete
             )

  # obj_needs is used to declare parameters to pass to handlers.
  # :for indicates those parameters to be passed to create_e handler only.
  # Those data (or objects) will be collected and passed to the process
  # handler as hParams.

  obj_needs :data,   :student_name,           :for => [:create_e]

  # By default, all data are required.
  # You can set it as optional. Your process will need to deal with this
  # optional data.
  obj_needs_optional
  obj_needs :data,   :first_name,             :for => [:create_e]
  obj_needs :data,   :last_name,              :for => [:create_e]
  obj_needs :data,   :course
  # Note that in this model, the training is renamed as course.

  # the controller will need to map it to 'training'.

  # def_attribute defines the data model.
  # The process will be able to access those data
  def_attribute :course
  def_attribute :student_name
  def_attribute :first_name
  def_attribute :last_name
  def_attribute :status
end
