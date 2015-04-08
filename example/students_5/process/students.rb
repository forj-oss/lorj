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
  # create_student process handler to get a student.
  #
  # * If not found, create it.
  # * If multiple found, remove duplicates
  # * otherwise return the one found.
  # rubocop:disable Metrics/MethodLength
  def create_student(sObjectType, hParams)
    PrcLib.state(format("Running creation process for object '%s' = '%s'",
                        sObjectType, hParams[:student_name]))

    list = process_query(sObjectType, :student_name => hParams[:student_name])
    case list.length
    when 0
      create_new_student(hParams[:student_name])
    when 1
      found_one_student(list[0], hParams[:student_name])
    else
      found_multiple_students(list, hParams[:student_name])
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  # Create a single new student
  def create_new_student(student_name)
    object = controller_create(:student)
    fail format("Student '%s' not created.", student_name) if object.nil?

    PrcLib.info(format("'student': '%s' created with id %s",
                       student_name,
                       object[:id]))
    object
  end

  # Identified 1 student
  def found_one_student(object, student_name)
    PrcLib.info(format("'student': '%s' loaded with id %s",
                       student_name, object[:id]))
    object
  end

  # Identified multiple identical students
  # It will remove duplicated.
  def found_multiple_students(list, student_name)
    object = list[0]
    PrcLib.warning(format("More than one student named '%s' is found: %s "\
                          'records. Selecting the first one and removing '\
                          'duplicates.',
                          student_name, list.length))
    remove_multiple_students(list[1..-1], student_name)
    object
  end

  # Remove list of identical students
  def remove_multiple_students(list, student_name)
    return false unless list.is_a?(Array)
    return false if list.length == 0

    count = 0
    list.each { |elem| count += remove_student_object(elem) }
    PrcLib.info(format("'student': %s duplicated '%s' removed. "\
                       'First loaded with id %s',
                       count, student_name, object[:id]))
  end

  def remove_student_object(object)
    register(object)
    controller_delete(:student)
  end

  # The following handler is inactive.
  # It provides a simple print-out code.
  # If you want to activate it:
  # * uncomment query_student function
  # * update the :student data model
  #   on query_e, replace controller_query by query_student

  # def query_student(sObjectType, sQuery, hParams)
  #    PrcLib::state (format("Running query process for object '%s' "\
  #                          "with query '%s'",
  #                           sObjectType,
  #                           sQuery))
  #
  #   objects = controller_query(sObjectType, sQuery)
  #   raise "Query error." if objects.nil?
  #
  #   PrcLib::info (format("'%s': Queried. %s records found.",
  #                        sObjectType,
  #                        objects.length))
  #   objects
  # end

  # This handler is inactive.
  # It provides a simple print-out code.
  # If you want to activate it:
  # * uncomment get_student function
  # * update the :student data model
  #   on get_e, replace controller_get by get_student

  # def delete_student(sObjectType, hParams)
  #    controller_delete(:student)
  #    PrcLib::info (format("'%s:%s' student removed",
  #                         hParams[:student, :id],
  #                         hParams[:student, :name]))
  # end
end

module Lorj
  # Declaring your data model and handlers.
  # Process Handlers functions have to be declared before, as lorj check their
  # existence during data model definition.
  class BaseDefinition
    # We need to define the student object data model and process handlers to
    # use.
    # Process handlers must manipulate data defined here.
    #
    # The controller can redefine object for it needs, but should NEVER impact
    # the main process.
    # The controller can add specific process to deal with internal controller
    # objects.
    # But this should never influence the original process model.

    # Use define_obj, to declare the new object managed by lorj with process
    # handlers.

    define_obj(:student,
               # The function to call in the class Students
               :create_e => :create_student,
               # We use predefined call to the controller query
               :query_e => :controller_query,
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

    undefine_attribute :name
  end
end
