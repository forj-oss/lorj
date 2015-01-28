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

# rubocop: disable Metrics/AbcSize

# Module Lorj which contains several classes.
#
# Those classes describes :
# - processes (BaseProcess)   : How to create/delete/edit/query object.
# - controler (BaseControler) : If a provider is defined, define how will do
#                               object creation/etc...
# - definition(BaseDefinition): Functions to declare objects, query/data mapping
#                               and setup
# this task to make it to work.
module Lorj
  # Represents a list of key/value pairs
  # if the value is a Lorj::Data(data or list), the key will be the Lorj::Data
  # type.
  #
  # This class is used in 3 different contexts:
  # - Process context:
  #   create/query/update/delete/get handler uses it to build the handler
  #   parameters and is passed to each process handler as 2nd parameter.
  #   ex: If a connection object is created as follow:
  #     define_obj(:connection,
  #                :create_e => :connection_create)
  #     obj_needs(:data, :uri)
  #
  #       then at runtime:
  #     lorj_object.create(:connection, :uri => 'http://example.org')
  #       will call 'connection_create' (params)
  #     def connection_creat(object_type, params)
  #       where object_type is ':connection' and
  #       params is a 'Lorj::ObjectData' containing :uri value.
  #
  #   The object behavior is adapted to the process usage.
  #   By default for Lorj::Data(:object), params[aKey] will get or set object
  #   attributes.
  #   ex: params[:uri]  # => 'http://example.org'
  #       params[:test] # => nil
  #
  # - Controller context:
  #   create/query/update/delete/get handler uses it to build controller
  #   parameters like hdata.
  #   The object behavior is adapted to the controller usage
  #   By default for Lorj::Data(:object), hParams[aKey] will get or set
  #   controller object
  #
  # - Internally by BaseDefinition.  to get a Lorj::Data cache.
  #
  class ObjectData
    # Initialize the object. By default, usage is for controller context.
    #
    # * *Args* :
    #   - +internal+    : Context
    #     - true if process context
    #     - false if controller context. This is the default value.
    #
    # * *Returns* :
    #   - nothing
    #
    # * *Raises* :
    #   No exceptions
    def initialize(internal = false)
      @params = {}
      @params[:hdata] = {} unless internal
      @internal = internal
    end

    # Get function
    #
    # key can be an array, a string (converted to a symbol) or a symbol.
    #
    # * *Args*    :
    #   - +key+   : key tree (list of keys)
    #     If key[1] == :attrs, get will forcelly use the Lorj::Data object
    #     attributes
    #     If key[1] == :ObjectData, get will forcelly return the controller
    #     object
    #     otherwise, get will depends on the context:
    #     - controller context: will return the controller object
    #     - Process context: will return the Lorj::Data object attributes
    # * *Returns* :
    #   value found or nil.
    # * *Raises* :
    #   nothing
    def [](*key)
      key = key.flatten

      return @params if key.length == 0

      object = @params.rh_get(key[0])

      # Return ObjectData, attributes if asked. or depends on context.
      value = object_data_get(object, key)
      # otherwise, simply return what is found in keys hierarchy.
      value = @params.rh_get(key) if value.nil?

      value
    end

    # Functions used to set simple data/Object for controller/process function
    # call.
    # TODO: to revisit this function, as we may consider simple data, as
    # Lorj::Data object
    def []=(*key, value)
      return nil if [:object, :query].include?(key[0])
      @params.rh_set(value, key)
    end

    # Add function. Add a Lorj::Data (data or list) to the ObjectData list.
    #
    # key can be an array, a string (converted to a symbol) or a symbol.
    #
    # * *Args*    :
    #   - +oDataObject+ : Lorj::Data object
    # * *Returns* :
    #   Nothing
    # * *Raises* :
    #   nothing
    def add(oDataObject)
      # Requires to be a valid framework object.
      unless oDataObject.is_a?(Lorj::Data)
        PrcLib.runtime_fail "Invalid Framework object type '%s'.",
                            oDataObject.class
      end
      object_data_add(oDataObject)
      oDataObject.register
    end

    # delete function. delete a Lorj::Data (data or list) from the ObjectData
    # cache.
    #
    # * *Args*    :
    #   - +object+ : Lorj::Data or Symbol representing a Lorj::Data cached.
    # * *Returns* :
    #   Nothing
    # * *Raises* :
    #   nothing
    def delete(obj)
      if obj.is_a?(Symbol)
        object_type = obj
        obj = @params[object_type]
        @params[object_type] = nil
      else
        object_data_delete(obj)
      end
      obj.unregister unless obj.nil?
    end

    # Merge 2 ObjectData.
    #
    # * *Args*    :
    #   - +hHash+ : Hash of Lorj::Data. But it is possible to have different
    #               object type (not Lorj::Data)
    # * *Returns* :
    #   hash merged
    # * *Raises* :
    #   nothing
    def <<(hHash)
      @params.merge!(hHash) unless hHash.nil?
    end

    # check Lorj::Data attributes or object exists. Or check key/value pair
    # existence.
    #
    # * *Args*    :
    #   - +hHash+ : Hash of Lorj::Data. But it is possible to have different
    #               object type (not Lorj::Data)
    # * *Returns* :
    #   true/false
    # * *Raises* :
    #   PrcError
    def exist?(*key) # rubocop: disable Metrics/MethodLength
      unless [Array, String, Symbol].include?(key.class)
        PrcLib.runtime_fail 'ObjectData: key is not list of values '\
                            '(string/symbol or array)'
      end
      key = [key] if key.is_a?(Symbol) || key.is_a?(String)

      key = key.flatten

      object = @params.rh_get(key[0])
      return false if object.nil?

      if object.is_a?(Lorj::Data)
        object_data_exist?(object, key)
      else
        # By default true if found key hierarchy
        @params.rh_exist?(*key)
      end
    end

    # Determine the type of object identified by a key. Lorj::Data attributes or
    # object exists. Or check key/value pair existence.
    #
    # * *Args*    :
    #   - +key+ : Key to check in ObjectData list.
    # * *Returns* :
    #   - nil if not found
    #   - :data if the key value is simply a data
    #   - :DataObject if the key value is a Lorj::Data
    # * *Raises* :
    #   PrcError

    def type?(key)
      return nil unless @params.rh_exist?(key)
      :data
      :DataObject if @params[key].type == :object
    end

    def to_s
      str = "-- Lorj::ObjectData --\n"
      str += "Usage internal\n" if @internal
      @params.each { |key, data| str += format("%s:\n%s\n", key, data.to_s) }
      str
    end

    private

    # Get function
    #
    # key can be an array of symbol or string (converted to a symbol).
    #
    # * *Args*    :
    #   - +object+: Lorj::Data object to get data. Must exist.
    #   - +key+   : key tree (list of keys)
    #     If key[1] == :attrs, get will forcelly use the Lorj::Data object
    #     attributes
    #     If key[1] == :ObjectData, get will forcelly return the controller
    #     object
    #     otherwise, get will depends on the context:
    #     - controller context: will return the controller object
    #     - Process context: will return the Lorj::Data object attributes
    # * *Returns* :
    #   value found or nil.
    # * *Raises* :
    #   nothing
    def object_data_get(object, *key)
      key = key.flatten

      return nil unless object.is_a?(Lorj::Data)

      # Return ObjectData Element if asked. Ignore additional keys.
      return @params[key[0]] if key[1] == :ObjectData

      # Return attributes if asked
      return object[:attrs,  key[2..-1]] if key[1] == :attrs

      # params are retrieved in process context
      # By default, if key is detected as a framework object, return its
      # data.
      return object[:attrs,  key[1..-1]] if @internal

      # params are retrieved in controller context
      # By default, if key is detected as a controller object, return its
      # data.
      return object[:object,  key[1..-1]] unless @internal
    end

    # Add function. Add a Lorj::Data (data or list) to the ObjectData list.
    #
    # key can be an array, a string (converted to a symbol) or a symbol.
    #
    # * *Args*    :
    #   - +oDataObject+ : Lorj::Data object
    # * *Returns* :
    #   Nothing
    # * *Raises* :
    #   nothing
    def object_data_add(oDataObject)
      object_type = oDataObject.object_type?

      if oDataObject.type == :list
        old_data_object = @params.rh_get(:query, object_type)
        old_data_object.unregister if old_data_object
        @params.rh_set(oDataObject, :query, object_type)
      else
        old_data_object = @params.rh_get(object_type)
        old_data_object.unregister if old_data_object
        @params[object_type] = oDataObject
      end
    end

    # delete function. delete a Lorj::Data (data or list) from the ObjectData
    # list.
    #
    # * *Args*    :
    #   - +oDataObject+ : Lorj::Data object
    # * *Returns* :
    #   Nothing
    # * *Raises* :
    #   nothing
    def object_data_delete(obj)
      PrcLib.runtime_fail 'ObjectData: delete error. obj is not a'\
                           " framework data Object. Is a '%s'",
                          obj.class unless obj.is_a?(Lorj::Data)
      if obj.type == :list
        @params.rh_set(nil, :query, obj.object_type?)
      else
        object_type = obj.object_type?
        @params[object_type] = nil
      end
    end

    def object_data_exist?(object, key)
      # Return true if ObjectData Element is found when asked.
      return true if key[1] == :ObjectData && object.type?(key[0]) == :object

      # Return true if attritutes or controller object attributes found when
      # asked.
      return object.exist?(key[2..-1]) if key[1] == :attrs
      return object.exist?(key[1..-1]) if key.length > 1
      true
    end
  end
end
