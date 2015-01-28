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

# Students process
class StudentsProcess
  # create_student process handler to get a student.
  #
  # * If not found, create it.
  # * If multiple found, remove duplicates
  # * otherwise return the one found.
  def create_student(sObjectType, hParams)
    PrcLib.state(format("Running creation process for object '%s' = '%s'",
                        sObjectType, hParams[:student_name]))

    list = process_query(sObjectType, :student_name => hParams[:student_name])
    case list.length
    when 0
      create_new_student(hParams)
    when 1
      found_one_student(list[0], hParams[:student_name])
    else
      found_multiple_students(list, hParams[:student_name])
    end
  end

  private

  # Create a single new student
  def create_new_student(hParams)
    user = hParams[:student_name].split(' ')

    controller_data = {}
    unless hParams.exist?(:first_name)
      if user.length == 1
        controller_data[:first_name] = 'unknown first name'
      else
        controller_data[:first_name] = user[0..-2].join(' ')
      end
    end
    controller_data[:last_name] = user[-1] unless hParams.exist?(:last_name)

    student = controller_create(:student, controller_data)

    process_fail format("Student '%s' not created.",
                        hParams[:student_name]) if student.nil?

    PrcLib.info(format("'student': '%s' created with id %s",
                       hParams[:student_name],
                       student[:id]))
    student
  end

  # Identified 1 student
  def found_one_student(student, student_name)
    PrcLib.info(format("'student': '%s' loaded with id %s",
                       student_name, student[:id]))

    student
  end

  # Identified multiple identical students
  # It will remove duplicated.
  def found_multiple_students(list, student_name)
    PrcLib.warning(format("More than one student named '%s' is found: %s "\
                          'records. Selecting the first one and removing '\
                          'duplicates.',
                          student_name, list.length))
    remove_multiple_students(list[1..-1], student_name)
    PrcLib.info("'student': First loaded with id %s", list[0, :id])
    list[0]
  end

  # Remove list of identical students
  def remove_multiple_students(list, student_name)
    return false unless list.is_a?(Array)
    return false if list.length == 0

    count = 0
    list.each { |elem| count += remove_student_object(elem) }
    PrcLib.info("'student': %s duplicated '%s' removed. ", count, student_name)
  end

  def remove_student_object(object)
    register(object)
    controller_delete(:student)
  end
end
