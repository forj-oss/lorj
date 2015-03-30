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

# Module Lorj implements ERBConfig, and initialization functions for
# Lorj::BaseDefinition
#
module Lorj
  # Following class defines class levels function to
  # declare framework objects.
  # As each process needs to define new object to deal with
  # require that process to define it with definition functions
  # See definition.rb for functions to use.
  class BaseDefinition
    # Initialize Lorj BaseDefinition object
    def initialize(oForjConfig, process, controller = nil)
      # Object Data object. Contains all loaded object data.
      # This object is used to build hParams as well.
      @object_data = ObjectData.new(true)
      #
      @runtime_context = {
        :oCurrentObj => nil
      }

      @config = oForjConfig
      @erb_config = ERBConfig.new(oForjConfig)
      if !oForjConfig.is_a?(Lorj::Account) && !oForjConfig.is_a?(Lorj::Config)
        PrcLib.runtime_fail "'%s' is not a valid ForjAccount or ForjConfig"\
                           ' Object.', oForjConfig.class
      end
      @controller = controller
      unless controller.nil? || controller.is_a?(BaseController)
        PrcLib.runtime_fail "'%s' is not a valid BaseController Object type.",
                            controller.class
      end

      @process = process
      PrcLib.runtime_fail "'%s' is not a valid BaseProcess Object type.",
                          process.class unless process.is_a?(BaseProcess)

      @process.base_object = self
    end

    # ------------------------------------------------------
    # Functions used by processes functions
    # ------------------------------------------------------
    # Ex: object.set_data(...)
    #     config

    # Reference to the config object.
    #
    # See Lorj::Config or Lorj::Account for details
    def config
      PrcLib.runtime_fail 'No config object loaded.' unless @config
      @config
    end

    def format_query(sObjectType, oControlerObject, hQuery)
      {
        :object => oControlerObject,
        :object_type => :object_list,
        :list_type => sObjectType,
        :list => [],
        :query => hQuery
      }
    end

    def format_object(object_type, oMiscObject)
      return nil unless [String, Symbol].include?(object_type.class)

      object_type = object_type.to_sym if object_type.class == String

      { :object_type => object_type,
        :attrs => {},
        :object => oMiscObject
      }
    end

    def get_data_metadata(sKey)
      _get_meta_data(sKey)
    end

    # Before doing a query, mapping fields
    # Transform Object query field to Provider query Fields
    def _query_map(object_type, hParams)
      return {} unless hParams

      object_type = object_type.to_sym if object_type.class == String

      result = {}
      maps = PrcLib.model.meta_obj.rh_get(object_type, :query_mapping)
      hParams.each do |key, value|
        key_path_obj = KeyPath.new(key)

        bold_action = ANSI.bold('ACTION REQUIRED')
        PrcLib.runtime_fail "Forj query field '%s.%s' not defined by class"\
                            " '%s'.\n#{bold_action}"\
                            ":\nMissing data model 'def_attribute' or "\
                            "'def_query_attribute' for '%s'??? "\
                            "Check the object '%s' data model.",
                            object_type, key_path_obj.key,
                            self.class, key_path_obj.key,
                            object_type unless maps.key?(key_path_obj.fpath)

        next if maps[key_path_obj.fpath].nil?

        map_path = KeyPath.new(maps[key_path_obj.fpath])
        _query_value_mapping(object_type, result, key_path_obj, map_path, value)
      end
      result
    end

    def _query_value_mapping(object_type, result, key_path_obj, map_path, value)
      key_path = key_path_obj.fpath
      value_mapping = PrcLib.model.meta_obj.rh_get(object_type, :value_mapping,
                                                   key_path)
      if value_mapping
        PrcLib.runtime_fail "'%s.%s': No value mapping for '%s'",
                            object_type, key_path_obj.key,
                            value unless value_mapping.rh_exist?(value)

        result.rh_set(value_mapping[value], map_path.tree)
      else
        result.rh_set(value, map_path.tree)
      end
      nil
    end

    # Register the object to the internal @object_data instance
    def register(oObject, sObjectType = nil, sDataType = :object)
      if oObject.is_a?(Lorj::Data)
        data_objects = oObject
      else
        PrcLib.runtime_fail "Unable to register an object '%s' "\
                             'as Lorj::Data object if ObjectType is not given.',
                            oObject.class unless sObjectType
        data_objects = Lorj::Data.new(sDataType)
        data_objects.set(oObject, sObjectType) do |sObjType, oControlerObject|
          _return_map(sObjType, oControlerObject)
        end
      end
      @object_data.add data_objects
    end

    # Function to get attributes of objects stored in the Lorj core data cache.
    #
    # *Args*
    # - object_type : Object type to get
    # - *key        : tree of keys to get values.
    #                 The syntax is defined by Lorj::Data[]
    #
    # *Return*
    # - Value of the Lorj::Data cached key.
    #
    def data_objects(sObjectType, *key)
      @object_data[sObjectType, *key]
    end

    # Function to get Lorj core data cache keys.
    #
    # *Args*
    #
    # *Return*
    # - List of objects in cache.
    #
    def cache_objects_keys
      @object_data[].keys
    end

    # get an attribute/object/... from an object.
    def get_data(oObj, *key)
      if oObj.is_a?(Hash) && oObj.key?(:object_type)
        object_data = ObjectData.new
        object_data << oObj
      else
        object_data = @object_data
      end
      object_data[oObj, *key]
    end

    private

    # -------------------------------------------------------------------------
    # Functions available for Process to communicate with the controler Object
    # -------------------------------------------------------------------------

    def get_object(sCloudObj)
      # ~ return nil unless Lorj::rh_exist?(@CloudData, sCloudObj)
      return nil unless @object_data.exist?(sCloudObj)
      @object_data[sCloudObj, :ObjectData]
      # ~ Lorj::rh_get(@CloudData, sCloudObj)
    end
  end
end
