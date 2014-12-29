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

# Students process
class StudentsProcess
  def create_student(sObjectType, hParams)
    PrcLib.state(format("Running creation process for object '%s' = '%s'",
                        sObjectType, hParams[:student_name]))

    object = controller_create(sObjectType)
    fail format("Student '%s' not created.",
                hParams[:student_name]) if object.nil?
    PrcLib.info(format("'%s': '%s' created with id %s",
                       sObjectType, hParams[:student_name],  object[:id]))
    object
  end
end

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

  obj_needs :data, :student_name, :for => [:create_e], :mapping => :name
end
