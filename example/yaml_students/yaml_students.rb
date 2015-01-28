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

require 'yaml'

# Simple School class saving data in a yaml file.
class YamlSchool
  attr_accessor :file
  attr_accessor :data

  # Initiliaze the API with the yaml file loaded.
  #
  # *Args*:
  # - +file+ : File name to load.
  def initialize(file)
    @data = { :students => [] }
    @file = file
    load_data
  end

  # Load data from a yaml file. File name is set at class initialization
  # To change the file name, update the file attribute
  def load_data
    return false unless File.exist?(@file)

    @data = YAML.load_file(@file)
    @data = { :students => [] } unless @data
    @data[:students] = [] unless @data.key?(:students)
  end

  # Save the data updated in memory.
  # To change the file name, update the file attribute
  def save_data
    begin
      File.open(@file, 'w') do |out|
        YAML.dump(@data, out)
      end
   rescue => e
     Lorj.error(format("%s\n%s", e.message, e.backtrace.join("\n")))
     return false
    end
    true
  end

  # create_student is a very basic function to create a new record in
  # the student yaml file.
  # The student is created in memory.
  # To save it in the file, use save_data.
  #
  # *Args*:
  # - +name+   : This is a generic name. It can be a surname as well
  # - +fields+ : Fields is a Hash list of data to add in the student
  #              It can be any kind of field name. But at least 2 are required:
  #   - :first_name : First name of the student
  #   - :last_name  : Last name of the student
  #
  # Ex:
  # create_student('rob', :last_name => 'Redford', :first_name => 'Robert',
  #                :class_room => 'Art Drama', :comment => 'Is a good student')
  def create_student(name, fields)
    if fields[:first_name].nil? || fields[:last_name].nil?
      puts 'YAML API: Unable to create a student. '\
           ':first_name and :last_name required.'
      return nil
    end

    result = create_data(name, fields)

    save_data
    result
  end

  # delete_student is a very basic function to delete a record from
  # the student yaml file.
  # The student is deleted in memory.
  # The deletion is simply an update of the :status to :removed
  # To save it in the file, use save_data.
  #
  # *Args*:
  # - id: If the student ID.
  #
  # Ex:
  # delete_student(2)
  def delete_student(sId)
    return false unless File.exist?(file)

    @data[:students].each do |value|
      next unless value[:id] == sId

      @data[:students][sId][:status] = :removed
      save_data
      return 1
    end
    0
  end

  # delete_student is a very basic function to delete a record from
  # the student yaml file.
  # The student is deleted in memory.
  # The deletion is simply an update of the :status to :removed
  # To save it in the file, use save_data.
  #
  # *Args*:
  # - query: Hash of fields to use for the query
  #          You can query any fields.
  #          Standard one are:
  #   - :id         : Student ID
  #   - :name       : Student name or surname
  #   - :first_name : First name of the student.
  #   - :last_name  : Last name of the student.
  #
  # *returns*:
  # - Array: List of records matching all fields.
  #          The matching feature is basically limited to field equality.
  #          if not found, the Array length will equal to 0.
  #
  # Ex:
  # query_student(:id => 2)
  # query_student(:first_name => 'Robert')
  # query_student(:class => 'Art Drama')
  def query_student(hQuery)
    result = []

    hQuery[:status] = :active unless hQuery.key?(:status)

    @data[:students].each do |hValue|
      elem = hValue
      hQuery.each do |query_key, query_value|
        elem = nil if not_in_query?(hQuery, hValue, query_key, query_value)
      end
      result << elem if elem
    end
    result
  end

  # update_student is a very basic function to update a record of
  # the student yaml file.
  # The student is updated in memory.
  # To save it in the file, use save_data.
  #
  # *Args*:
  # - query: Hash of fields to use for the query
  #          You can query any fields.
  #          Standard one are:
  #   - :id         : Student ID
  #   - :name       : Student name or surname
  #   - :first_name : First name of the student.
  #   - :last_name  : Last name of the student.
  #   - :status     : :removed if the record is deleted.
  #
  # Ex:
  # query_student(2, :name => 'robby')
  def update_student(id, fields)
    list = query_student(:id => id)
    list[0].merge(fields) if list.length == 1
    save_data
  end

  private

  def create_data(name, fields)
    result = fields.clone
    result[:name] = name
    if name.nil?
      result[:name] = format('%s %s', result[:first_name], result[:first_name])
    end
    result[:status] = :active

    @data[:students] << result

    result[:id] = @data[:students].length - 1
    result
  end

  # check query field and data value.
  # Return true if the query do not match the current data
  def not_in_query?(hQuery, hValue, query_key, query_value)
    return true unless valid_status?(hQuery, hValue)
    return true unless hValue.key?(query_key)
    return true if hValue[query_key] != query_value
    false
  end

  # check if status field is queried. if not consider status != :active.
  # return true if status
  def valid_status?(hQuery, hValue)
    return false if hValue.key?(:status) && hValue[:status] != :active &&
                    !hQuery.key?(:status)
    true
  end
end
