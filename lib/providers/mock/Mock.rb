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

class Mock
   # mock do not need to use any mapping. It adapts itself to what the process has defined.
end

class MockController

   @@data = {}

   def create(sObjectType, hParams)
      PrcLib::debug("Mock: create object '%s' with parameters (hdata) '%s'" % [sObjectType, hParams[:hdata]])

      result = {}
      hParams[].keys.each { |key|
         next if key == :hdata
         result[key] = hParams[key]
      }
      result.merge!(hParams[:hdata])

      unless @@data.key?(sObjectType)
         @@data[sObjectType] = []
      end
      aArr = @@data[sObjectType]

      aArr.each { | value |
         raise if value.key?(result[:name])
      }
      aArr << result

      result[:id] = aArr.length()-1

      # Typical code:
      #~ case sObjectType
         #~ when :public_ip
            # Following function can be executed to ensure the object :connection exists.
            #~ required?(hParams, :connection)
            #~ required?(hParams, :server)
            #~ ... CODE to create
         #~ else
            #~ Error "'%s' is not a valid object for 'create'" % sObjectType
      #~ end
      # The code should return some data
      # This data will be encapsulated in Lorj::Data object.
      # data will be extracted by the framework with the controller get_attr function and mapped.
      PrcLib::debug("Mock: object '%s' = '%s' is created." % [sObjectType, result])
      result
   end

   # This function return a collection which have to provide:
   # functions: [], length, each
   # Used by network process.
   def query(sObjectType, sQuery, hParams)
      PrcLib::debug("Mock: query object '%s' with hdata '%s' using query '%s'" % [sObjectType, hParams[:hdata], sQuery])

      return [] unless @@data.key?(sObjectType)

      result = []

      @@data[sObjectType].each { | value |
         hElem = value
         sQuery.each { | query_key, query_value |
            hElem = nil if not value.key?(query_key) or value[query_key] != query_value
         }
         result << hElem if hElem
      }
      result
   end

   def delete(sObjectType, hParams)
      PrcLib::debug("Mock: delete object '%s' with hdata '%s'" % [sObjectType, hParams[:hdata]])
      return nil unless @@data.key?(sObjectType)

      return false if not hParams.exist?(sObjectType) or hParams[sObjectType].nil?
      @@data[sObjectType].delete(hParams[sObjectType])
      PrcLib::debug("Mock: object '%s' = '%s' is deleted." % [sObjectType, hParams[sObjectType]])
      true
   end

   def get(sObjectType, sUniqId, hParams)
      PrcLib::debug("Mock: Get object '%s' = '%s' with hdata '%s'" % [sObjectType, sUniqId, hParams[:hdata]])
      return nil unless @@data.key?(sObjectType)
      @@data[sObjectType][sUniqId]
   end

   def get_attr(oControlerObject, key)
      # This controller function read the data and
      # extract the information requested by the framework.
      # Those data will be mapped to the process data model.
      # The key is an array, to get data from a level tree.
      # [data_l1, data_l2, data_l3] => should retrieve data from structure like data[ data_l2[ data_l3 ] ]
      begin
         attributes = oControlerObject
#         raise "attribute '%s' is unknown in '%s'. Valid one are : '%s'" % [key[0], oControlerObject.class, oControlerObject.keys ] unless oControlerObject.include?(key[0])
         Lorj::rhGet(attributes, key)
      rescue => e
         Error "Unable to map '%s'. %s" % [key, e.message]
      end
   end

   def set_attr(oControlerObject, key, value)
      begin
         attributes = oControlerObject
#         raise "attribute '%s' is unknown in '%s'. Valid one are : '%s'" % [key[0], oControlerObject.class, oControlerObject.keys ] unless oControlerObject.include?(key[0])
         Lorj::rhSet(attributes, value, key)
      rescue => e
         Error "Unable to map '%s' on '%s'" % [key, sObjectType]
      end
   end


   def update(sObjectType, oObject, hParams)
      PrcLib::debug("Mock: Update object '%s' = '%s' with hdata '%s'" % [sObjectType, sUniqId, hParams[:hdata]])
      return false unless @@data.key?(sObjectType)

      return false unless @@data[sObjectType][oObject[:id]].nil?
      # Considered hash object is already updated.
      # This action emule the object save which doesn't make sense in this empty Mock controller.
      true
   end
end