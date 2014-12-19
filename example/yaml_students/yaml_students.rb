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

class YamlSchool
  attr_accessor :sFile
  attr_accessor :hData

  def initialize(sFile)
    @hData = { students: [] }
    @sFile = sFile
    load_data
  end

  def load_data
    if File.exist?(@sFile)
      @hData = YAML.load_file(@sFile)
      @hData = { students: [] } unless @hData
      @hData[:students] = [] unless @hData.key?(:students)
    end
  end

  def save_data
    begin
      File.open(@sFile, 'w') do |out|
        YAML.dump(@hData, out)
      end
   rescue => e
     Lorj.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
     return false
    end
    true
  end

  def create_student(name, fields)
    if fields[:first_name].nil? || fields[:last_name].nil?
      puts 'YAML API: Unable to create a student. :first_name and :last_name required.'
      return nil
    end

    result = fields.clone
    result[:name] = name
    result[:name] = '%s %s' % [result[:first_name], result[:first_name]] if name.nil?
    result[:status] = :active

    @hData[:students] << result

    result[:id] = @hData[:students].length - 1

    save_data
    result
  end

  def delete_student(sId)
    return false unless File.exist?(sFile)

    @hData[:students].each do | value |
      hElem = value
      if value[:id] == sId
        @hData[:students][sId][:status] = :removed
        save_data
        return 1
      end
    end
    0
  end

  def query_student(sQuery)
    result = []

    @hData[:students].each do | value |
      hElem = value
      sQuery.each do | query_key, query_value |
        hElem = nil if (
           value.key?(:status) &&
           value[:status] != :active &&
           !sQuery.key?(:status)) ||
                       !value.key?(query_key) ||
                       value[query_key] != query_value
      end
      result << hElem if hElem
    end
    result
  end

  def update_student(_sId, fields)
    aList = query_student(id: Id)
    if aList.length == 1
      aList[0].merge(fields)
    end
    save_data
  end
end
