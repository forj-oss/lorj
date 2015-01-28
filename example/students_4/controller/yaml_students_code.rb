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

# This file describe the controller code.
# The class name is determined by lorj.
# See controller/yaml_students.rb for details
class YamlStudentsController
  # controller wrapper
  def create(sObjectType, hParams)
    case sObjectType
    when :connection
      required?(hParams, :hdata, :file_name)
      YamlSchool.new(hParams[:hdata, :file_name])
    when :student
      required?(hParams, :connection)
      required?(hParams, :student_name)
      # We added test requiring :first_name and :last_name
      required?(hParams, :first_name)
      required?(hParams, :last_name)

      hParams[:connection].create_student(hParams[:student_name],
                                          hParams[:hdata])
    else
      controller_error "'%s' is not a valid object for 'create'", sObjectType
    end
  end

  # This function return one element identified by an ID.
  # But get is not a YamlStudent API functions. But query help to use :id
  #
  # so we will do a query
  def get(sObjectType, id, hParams)
    case sObjectType
    when :student
      result = query(sObjectType, { :id => id }, hParams)
      return nil if result.length == 0
      result[0]
    else
      controller_error "'%s' is not a valid object for 'create'", sObjectType
    end
  end

  # This function return a collection which have to provide:
  # functions: [], length, each
  def query(sObjectType, sQuery, hParams)
    case sObjectType
    when :student
      required?(hParams, :connection)

      hParams[:connection].query_student(sQuery)
    else
      controller_error "'%s' is not a valid object for 'create'", sObjectType
    end
  end

  # Example 4: Delete added to the controller.
  def delete(sObjectType, hParams)
    case sObjectType
    when :student
      required?(hParams, :connection)

      hParams[:connection].delete_student(hParams[sObjectType][:id])
    else
      Error format("'%s' is not a valid object for 'create'", sObjectType)
    end
  end

  # This controller function read the data and
  # extract the information requested by the framework.
  # Those data will be mapped to the process data model.
  # The key is an array, to get data from a level tree.
  # [data_l1, data_l2, data_l3] => should retrieve data from structure like
  # data[ data_l2[ data_l3 ] ]
  def get_attr(oControlerObject, key)
    attributes = oControlerObject

    controller_error("get_attr: attribute '%s' is unknown in '%s'. "\
                     "Valid one are : '%s'",
                     key[0], oControlerObject.class,
                     valid_attributes) unless valid_attributes.include?(key[0])
    attributes.rh_get(key)
  rescue => e
    controller_error "get_attr: Unable to map '%s'. %s\n See %s",
                     key, e.message, e.backtrace[0]
  end

  private

  # These are the valid controller fields.
  def valid_attributes
    [:name, :first_name, :last_name, :id, :status, :training]
  end
end
