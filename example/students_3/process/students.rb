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

# Students process - Define specific handlers
class StudentsProcess
  def create_student(sObjectType, hParams)
    PrcLib.state ("Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name]])

    # config object is a reference to runtime/config data.
    oList = Query(sObjectType, student_name: hParams[:student_name])
    case oList.length
       when 0
         oObject = controller_create(sObjectType)
         fail "Student '%s' not created." % hParams[:student_name] if oObject.nil?
         PrcLib.info ("'%s': '%s' created with id %s" % [sObjectType, hParams[:student_name],  oObject[:id]])
       when 1
         oObject = oList[0]
         PrcLib.info ("'%s': '%s' loaded with id %s" % [sObjectType, hParams[:student_name],  oObject[:id]])
       else
         oObject = oList[0]
         PrcLib.warning("More than one student named '%s' is found: %s records. Selecting the first one and removing duplicates." % [hParams[:student_name], oList.length])
         iCount = 0
         oList[1..-1].each do | elem |
           register(elem)
           iCount += controller_delete(sObjectType)
         end
         PrcLib.info ("'%s': %s duplicated '%s' removed. First loaded with id %s" % [sObjectType, iCount, hParams[:student_name],  oObject[:id]])
    end
    oObject
  end

  # The following handler is inactive.
  # It provides a simple print-out code.
  # If you want to activate it:
  # * uncomment query_student function
  # * update the :student data model
  #   on query_e, replace controller_query by query_student

  # def query_student(sObjectType, sQuery, hParams)
  #    PrcLib::state ("Running query process for object '%s' with query '%s'" % [sObjectType, sQuery])
  #
  #   oObjects = controller_query(sObjectType, sQuery)
  #   raise "Query error." if oObjects.nil?
  #
  #   PrcLib::info ("'%s': Queried. %s records found." % [sObjectType, oObjects.length])
  #   oObjects
  # end

  # This handler is inactive.
  # It provides a simple print-out code.
  # If you want to activate it:
  # * uncomment get_student function
  # * update the :student data model
  #   on get_e, replace controller_get by get_student

  # def delete_student(sObjectType, hParams)
  #    controller_delete(:student)
  #    PrcLib::info ("'%s:%s' student removed" % [hParams[:student, :id], hParams[:student, :name]])
  # end
end

# Declaring your data model and handlers.
# Process Handlers functions have to be declared before, as lorj check their existence during data model definition.

class Lorj::BaseDefinition
  # We need to define the student object data model and process handlers to use.
  # Process handlers must manipulate data defined here.
  #
  # The controller can redefine object for it needs, but should NEVER impact the main process.
  # The controller can add specific process to deal with internal controller objects.
  # But this should never influence the original process model.

  # Use define_obj, to declare the new object managed by lorj with process handlers.
  define_obj(:student,

             create_e: :create_student,   # The function to call in the class Students
             query_e: :controller_query, # We use predefined call to the controller query
             delete_e: :controller_delete # We use predefined call to the controller delete
             )

  # obj_needs is used to declare parameters to pass to handlers.
  # :for indicates those parameters to be passed to create_e handler only.
  # Those data (or objects) will be collected and passed to the process handler as hParams.

  obj_needs :data,   :student_name,           for: [:create_e]

  # By default, all data are required.
  # You can set it as optional. Your process will need to deal with this optional data.
  obj_needs_optional
  obj_needs :data,   :first_name,             for: [:create_e]
  obj_needs :data,   :last_name,              for: [:create_e]
  obj_needs :data,   :course  # Note that in this model, the training is renamed as course.
  # the controller will need to map it to 'training'.

  # def_attribute defines the data model.
  # The process will be able to access those data
  def_attribute :course
  def_attribute :student_name
  def_attribute :first_name
  def_attribute :last_name
  def_attribute :status

  undefine_attribute :name
end
