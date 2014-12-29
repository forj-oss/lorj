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
  # This class limits ERC template to access only to config object data.
  class ERBConfig
    attr_reader :config

    def initialize(config)
      @config = config
    end

    # Bind this limited class with ERB templates
    def get_binding # rubocop: disable AccessorMethodName
      binding
    end
  end

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
      fail Lorj::PrcError.new, "'%s' is not a valid ForjAccount or ForjConfig"\
           ' Object.',
           [oForjConfig.class] if
           !oForjConfig.is_a?(Lorj::Account) &&

           !oForjConfig.is_a?(Lorj::Config)

      @controller = controller
      if controller
        runtime_fail "'%s' is not a valid ForjProvider Object type.",
                     controller.class unless controller.is_a?(BaseController)
      end

      @process = process
      fail Lorj::PrcError.new, "'%s' is not a valid BaseProcess Object type.",
           [process.class] unless process.is_a?(BaseProcess)

      @process.base_object(self)
    end

    # ------------------------------------------------------
    # Functions used by processes functions
    # ------------------------------------------------------
    # Ex: object.set_data(...)
    #     config

    # Function to manipulate the config object.
    # 2 kind of functions:
    # - set (key, value) and []=(key, value)
    #   From processes, you can set a runtime data with:
    #     config.set(key, value)
    #   OR
    #     config[key] = value
    #
    # - get (key, default) and [](key, default)
    #   default is an optional value.
    #   From processes, you can get a data (runtime/account/config.yaml or
    #   defaults.yaml) with:
    #     config.get(key)
    #   OR
    #     config[key]

    def config
      fail Lorj::PrcError.new, 'No config object loaded.' unless @config
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
        key_path = key_path_obj.fpath
        PrcLib.runtime_fail "Forj query field '%s.%s' not defined by class"\
                            " '%s'.\n#{ANSI.bold}ACTION REQUIRED#{ANSI.clear}"\
                            ":\nMissing data model 'def_attribute' or "\
                            "'def_query_attribute' for '%s'??? "\
                            "Check the object '%s' data model.",
                            object_type, key_path_obj.key,
                            self.class, key_path_obj.key,
                            object_type unless maps.key?(key_path_obj.fpath)
        map_path = KeyPath.new(maps[key_path_obj.fpath])
        value_mapping = PrcLib.model.meta_obj.rh_get(object_type,
                                                     :value_mapping, key_path)
        if value_mapping
          PrcLib.runtime_fail "'%s.%s': No value mapping for '%s'",
                              object_type, key_path_obj.key,
                              value unless value_mapping.rh_exist?(value)

          result.rh_set(value_mapping[value], map_path.tree)
        else
          result.rh_set(value, map_path.tree)
        end
      end
      result
    end

    # Obsolete. Used by the Process.
    # Ask controller get_attr to get a data
    # The result is the data of a defined data attribute.
    # If the value is normally mapped (value mapped), the value is
    # returned as a recognized data attribute value.
    # def get_attr(oObject, key)
    #   fail Lorj::PrcError.new, "'%s' is not a valid Object type. " % [oObject.
    # class] if !oObject.is_a?(Hash) &&
    #           ! oObject.rh_exist?(:object_type)
    #   sCloudObj = oObject[:object_type]
    #   oKeyPath = KeyPath.new(key)
    #   fail Lorj::PrcError.new, "'%s' key is not declared as data of '%s' "\
    #                            'CloudObject. You may need to add obj_needs...'
    # % [oKeyPath.key, sCloudObj] if PrcLib.model.meta_obj.rh_exist?(sClou
    # dObj, :returns, oKeyPath.fpath) != 3
    #   begin
    #     oMapPath = KeyPath.new PrcLib.model.meta_obj.rh_get(sCloudObj, :
    # returns, oKeyPath.fpath)
    #     hMap = oMapPath.fpath
    #     value = @controller.get_attr(get_cObject(oObject), hMap)

    #     hValueMapping = PrcLib.model.meta_obj.rh_get(sCloudObj, :value_m
    # apping, oKeyPath.fpath)

    #     if hValueMapping
    #       hValueMapping.each do | found_key, found_value |
    #         if found_value == value
    #           value = found_key
    #           break
    #         end
    #       end
    #     end
    #  rescue => e
    #    raise Lorj::PrcError.new, "'%s.get_attr' fails to provide value of '%s'
    # " % [oProvider.class, key]
    #   end
    # end

    # Register the object to the internal @object_data instance
    def register(oObject, sObjectType = nil, sDataType = :object)
      if oObject.is_a?(Lorj::Data)
        data_objects = oObject
      else
        runtime_fail "Unable to register an object '%s' "\
                     'as Lorj::Data object if ObjectType is not given.',
                     oObject.class unless sObjectType
        data_objects = Lorj::Data.new(sDataType)
        data_objects.set(oObject, sObjectType) do | sObjType, oControlerObject |
          _return_map(sObjType, oControlerObject)
        end
      end
      @object_data.add data_objects
    end

    def data_objects(sObjectType, *key)
      @object_data[sObjectType, key]
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

    # ~ def hParams(sCloudObj, hParams)
    # ~ aParams = _get_object_params(sCloudObj, ":ObjectData.hParams")
    # ~ end

    # def get_cObject(oObject)
    #   return nil unless oObject.rh_exist?(:object)
    #   oObject.rh_get(:object)
    # end

    private

    # -------------------------------------------------------------------------
    # Functions available for Process to communicate with the controler Object
    # -------------------------------------------------------------------------
    # def cloud_obj_requires(sCloudObj, res = {})
    #   aCaller = caller
    #   aCaller.pop

    #   return res if @object_data.exist?(sCloudObj)
    #   # ~ return res if Lorj::rh_exist?(@CloudData, sCloudObj)

    #   PrcLib.model.meta_obj.rh_get(sCloudObj, :params).each do |
    #                                         key, hParams|
    #     case hParams[:type]
    #     when :data
    #       if  hParams.key?(:array)
    #         hParams[:array].each do | aElem |
    #           aElem = aElem.clone
    #           aElem.pop # Do not go until last level, as used to loop next.
    #           hParams.rh_get(aElem).each do | subkey, _hSubParam |
    #             next if aElem.length == 0 && [:array, :type].include?(subkey)
    #             if hSubParams[:required] && @config.get(subkey).nil?
    #               res[subkey] = hSubParams
    #             end
    #           end
    #         end
    #       else
    #         if hParams[:required] && @config.get(key).nil?
    #           res[key] = hParams
    #         end
    #       end
    #     when :CloudObject
    #       if hParams[:required] && !@object_data.exist?(sCloudObj)
    #         res[key] = hParams
    #         cloud_obj_requires(key, res)
    #       end
    #     end
    #   end
    #   res
    # end

    def get_object(sCloudObj)
      # ~ return nil unless Lorj::rh_exist?(@CloudData, sCloudObj)
      return nil unless @object_data.exist?(sCloudObj)
      @object_data[sCloudObj, :ObjectData]
      # ~ Lorj::rh_get(@CloudData, sCloudObj)
    end

    # def objectExist?(sCloudObj)
    #   @object_data.exist?(sCloudObj)
    #   # ~ !(Lorj::rh_exist?(@CloudData, sCloudObj))
    # end

    # def get_forjKey(sCloudObj, key)
    #   return nil unless @object_data.exist?(sCloudObj)
    #   @object_data[sCloudObj, :attrs, key]
    #   # ~ return nil unless Lorj::rh_exist?(oCloudData, sCloudObj)
    #   # ~ Lorj::rh_get(oCloudData, sCloudObj, :attrs, key)
    # end
  end
end
