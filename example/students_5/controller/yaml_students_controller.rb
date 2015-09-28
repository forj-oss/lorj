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
yaml_students_file = File.expand_path(
  File.join(
    File.dirname(__FILE__),
    '..', '..', 'yaml_students', 'yaml_students.rb'))
require yaml_students_file

# The controller is a combination of 2 elements:
# - Controller class
#   Code which will interfere with the external API.
#
#   The file name must respect the name of the class. 1st letter already
#   capitalized and letter after _ is capitalized.
#   file: my_code.rb => needs to create MyCodeController class
#
# - Definition class
#   This class declare any kind of mapping or additional fields to consider.
#   Additionnal fields are unknow by the process. So, those fields will needs
#   to be setup before.
#
#   file name convention is identical than controller class.
#   file: my_code.rb => needs to create MyCode class
class YamlStudentsController
  # controller wrapper
  def create(sObjectType, hParams)
    case sObjectType
    when :connection
      byebug if ENV['BYEBUG'] # rubocop: disable Debugger

      required?(hParams, :hdata, :file_name)
      YamlSchool.new(hParams[:hdata, :file_name])
    when :student
      required?(hParams, :connection)
      required?(hParams, :student_name)

      hParams[:connection].create_student(hParams[:student_name],
                                          hParams[:hdata])
    else
      Error format("'%s' is not a valid object for 'create'", sObjectType)
    end
  end
  # rubocop: enable Metrics/MethodLength

  # This function return a collection which have to provide:
  # functions: [], length, each
  # Used by network process.
  def query(sObjectType, sQuery, hParams)
    case sObjectType
    when :student
      required?(hParams, :connection)

      hParams[:connection].query_student(sQuery)
    else
      Error format("'%s' is not a valid object for 'create'", sObjectType)
    end
  end

  def delete(sObjectType, hParams)
    case sObjectType
    when :student
      required?(hParams, :connection)

      hParams[:connection].delete_student(hParams[sObjectType][:id])
    else
      Error format("'%s' is not a valid object for 'create'", sObjectType)
    end
  end

  def get_attr(oControlerObject, key)
    # This controller function read the data and
    # extract the information requested by the framework.
    # Those data will be mapped to the process data model.
    # The key is an array, to get data from a level tree.
    # [data_l1, data_l2, data_l3] => should retrieve data from structure like
    # data[ data_l2[ data_l3 ] ]
    attributes = oControlerObject

    fail format("get_attr: attribute '%s' is unknown in '%s'. "\
                "Valid one are : '%s'",
                key[0],
                oControlerObject.class,
                valid_attributes) unless valid_attributes.include?(key[0])
    attributes.rh_get(key)
  rescue => e
    Error format("get_attr: Unable to map '%s'. %s", key, e.message)
  end

  def set_attr(oControlerObject, key, value)
    attributes = oControlerObject
    fail format("set_attr: attribute '%s' is unknown in '%s'. "\
                "Valid one are : '%s'",
                key[0],
                oControlerObject.class,
                valid_attributes) unless valid_attributes.include?(key[0])
    attributes.rh_set(value, key)
  rescue
    Error format("set_attr: Unable to map '%s' on '%s'", key, sObjectType)
  end

  def update(sObjectType, oObject, hParams)
    case sObjectType
    when :student
      required?(hParams, :connection)

      hParams[:connection].update_student(oObject)
    else
      Error format("'%s' is not a valid object for 'create'", sObjectType)
    end
  end

  private

  def valid_attributes
    [:name, :first_name, :last_name, :id, :status, :training]
  end
end
