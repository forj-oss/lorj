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
    puts format("Running creation process for object '%s' = '%s'",
                sObjectType, hParams[:student_name])
    # If you prefer to print out to the log system instead:
    # PrcLib::debug(format("Running creation process for object '%s' = '%s'",
    #                      sObjectType, hParams[:student_name] ))
  end
end

# Declaring your data model and handlers.
# Rubocop: Disabling Style/ClassAndModuleChildren to avoid un-needed indentation
class Lorj::BaseDefinition # rubocop:disable Style/ClassAndModuleChildren
  # We need to define the student object and the handler to use while we need
  # to create it.
  define_obj(:student,
             # The function to call in the class Students
             :create_e => :create_student
            )

  obj_needs :data, :student_name, :for => [:create_e]
end
