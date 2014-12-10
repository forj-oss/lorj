#!/usr/bin/env ruby
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

module Lorj
   class BaseDefinition

      private

      ###################################################
      # Class management Section
      ###################################################

      # Meta Object declaration structure
      # <Object>
      #   :query_mapping        List of keypath mapped.
      #     <keypath> = <keypath mapped>
      #   :lambdas:
      #     :create_e:          function to call at 'Create' task
      #     :delete_e:          function to call at 'Delete' task
      #     :update_e:          function to call at 'Update' task
      #     :get_e:             function to call at 'Get'    task
      #     :query_e:           function to call at 'Query'  task
      #   :value_mapping:       Define list of Object's key values mapping.
      #     <keypath>           key value mapping lists
      #       <value> = <map>   Define the value mapping.
      #   :returns
      #     <keypath>           key value to extract from controller object.
      #   :params:              Defines CloudData (:data) or CloudObj (:CloudObj) needs by the <Object>
      #     :keys:              Contains keys in a tree of hash.
      #       <keypath>:        String. One element (string with : and /) of :list defining the key
      #         :type:          :data or :CloudObj
      #         :for:           Array of events which requires the data or CloudObj to work.
      #         :mapping:       To automatically create a provider hash data mapped (hdata).
      #         :required:      True if this parameter is required.
      #         :extract_from:  Array. Build the keypath value from another hParams value.
      #                         Ex: This example will extract :id from :security_groups object
      #                             :extract_from => [:security_groups, :id]
      #
      @@meta_obj =  {}

      # meta data are defined in defaults.yaml and loaded in Lorj::Default class definition
      # Cloud provider can redefine ForjData defaults and add some extra parameters.
      # To get Application defaults, read defaults.yaml, under :sections:
      @@meta_data = {}
      # <Section>:
      #   <Data>:               Required. Symbol/String. default: nil
      #                         => Data name. This symbol must be unique, across sections.
      #     :desc:              Required. String. default: nil
      #                         => Description
      #     :readonly:          Optional. true/false. Default: false
      #                         => oForjConfig.set() will fail if readonly is true.
      #                            Can be set, only thanks to oForjConfig.setup()
      #                            or using private oForjConfig._set()
      #     :account_exclusive: Optional. true/false. Default: false
      #                         => Only oConfig.account_get/set() can handle the value
      #                            oConfig.set/get cannot.
      #     :account:           Optional. default: False
      #                         => setup will configure the account with this <Data>
      #     :depends_on:
      #                         => Identify :data type required to be set before the current one.
      #     :validate:          Regular expression to validate end user input during setup.
      #     :value_mapping:     list of values to map as defined by the controller
      #       :controller:      mapping for get controller value from process values
      #         <value> : <map> value map equivalence. See data_value_mapping function
      #       :process:         mapping for get process value from controller values
      #         <value> : <map> value map equivalence. See data_value_mapping function
      #     :defaut:            Default value
      #     :list_values:       Defines a list of valid values for the current data.
      #       :query_type       :controller_call to execute a function defined in the controller object.
      #                         :process_call to execute a function defined in the process object.
      #                         :values to get list of values from :values.
      #       :object           Object to load before calling the function.  Only :query_type = :*_call
      #       :query_call       Symbol. function name to call.               Only :query_type = :*_call
      #                         function must return an Array.
      #       :query_params     Hash. Controler function parameters.         Only :query_type = :*_call
      #       :validate         :list_strict. valid only if value is one of those listed.
      #       :values:
      #                         to retrieve from.
      #                         otherwise define simply a list of possible values.

      # The Generic Process can pre-define some data and value (function predefine_data)
      # The Generic Process (and external framework call) only knows about Generic data.
      # information used
      #
      @@meta_predefined_values = {}

      # <Data>:                  Data name
      #   :values:               List of possible values
      #      <Value>:            Value Name attached to the data
      #        options:          Options
      #          :desc:          Description of that predefine value.

      @@Context = {
         :oCurrentObj      => nil, # Defines the Current Object to manipulate
         :needs_optional   => nil, # set optional to true for any next needs declaration
         :ClassProcess     => nil  # Current Process Class declaration
      }

      # Available functions for:
      # - BaseDefinition class declaration
      # - Controler (derived from BaseDefinition) class declaration

      @@query_auto_map = false

      def self.current_process (cProcessClass)
         @@Context[:ClassProcess] = cProcessClass
      end

      def self.obj_needs_optional
         @@Context[:needs_optional] = true
      end

      def self.obj_needs_requires
         @@Context[:needs_optional] = false
      end

      def self.process_default(hOptions)
         aSupportedOptions = [:use_controller]
         unless hOptions.nil?
            hOptions.each_key { | key |
               case key
                  when :use_controller
                     value = Lorj::rhGet(hOptions, :use_controller)
                     next unless value.is_a?(TrueClass) or value.is_a?(FalseClass)
                     Lorj::rhSet(@@Context, hOptions[key], :options, key)
                  else
                     raise Lorj::PrcError.new, "Unknown default process options '%s'. Supported are '%s'" % [key, aSupportedOptions.join(',')]
               end
            }
         end

      end

      # Defines Object and connect to functions events
      def self.define_obj(sCloudObj, hParam = nil)
         return nil if not sCloudObj
         return nil if not [String, Symbol].include?(sCloudObj.class)

         aCaller = caller
         aCaller.pop

         sCloudObj = sCloudObj.to_sym if sCloudObj.class == String
         @@Context[:oCurrentObj] = sCloudObj
         @@Context[:needs_optional] = false
         @@Context[:needs_setup] = false
         bController = Lorj::rhGet(@@Context, :options, :use_controller)
         bController = true if bController.nil?

         if not [Hash].include?(hParam.class)
            if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1
               raise Lorj::PrcError.new(), "New undefined object '%s' requires at least one handler. Ex: define_obj :%s, :create_e => myhandler " % [sCloudObj, sCloudObj]
            end
            hParam = {}
         end

         oCloudObj = Lorj::rhGet(@@meta_obj, sCloudObj)
         if not oCloudObj
            oCloudObj = {
               :lambdas => {:create_e => nil, :delete_e => nil, :update_e => nil, :get_e => nil, :query_e => nil, :get_attr_e => nil},
               :params => {},
               :options => {:controller => bController },
               :query_mapping => { ":id" => ":id", ":name" => ":name"},
               :returns => {":id" => ":id", ":name" => ":name"}
            }
            msg = nil
         else
            msg = ""
         end

         sObjectName = "'%s.%s'" %  [self.class, sCloudObj]

         # Checking hParam data
         if not Lorj::rhGet(hParam, :nohandler)
            hParam.each_key do | key |
               raise Lorj::PrcError.new(), "'%s' parameter is invalid. Use '%s'" % [key, oCloudObj[:lambdas].keys.join(', ')], aCaller if Lorj::rhExist?(oCloudObj, :lambdas, key)!= 2
            end
            msg = "%-28s object declared." %  [sObjectName] if not msg
         else
            msg = "%-28s meta object declared." %  [sObjectName] if not msg
         end
         Lorj.debug(2, msg) if msg != ""

         # Setting procs
         Lorj::rhGet(oCloudObj, :lambdas).each_key { |key|
            next if not hParam.key?(key)

            if not @@Context[:ClassProcess].instance_methods.include?(hParam[key])
               raise Lorj::PrcError.new(), "'%s' parameter requires a valid instance method '%s' in the process '%s'." % [key, hParam[key], @@Context[:ClassProcess]], aCaller
            end
            if hParam[key] == :default
               # By default, we use the event name as default function to call.
               # Those function are predefined in ForjController
               # The Provider needs to derive from ForjController and redefine those functions.
               oCloudObj[:lambdas][key] = key
            else
               # If needed, ForjProviver redefined can contains some additionnal functions
               # to call.
               oCloudObj[:lambdas][key] = hParam[key]
            end
            }
         Lorj::rhSet(@@meta_obj, oCloudObj, sCloudObj)
      end

      def self.def_query_attribute(key)
         self.query_mapping(key, key)
      end

      def self.query_mapping(key, map)
         return nil if not [String, Symbol].include?(key.class)
         return nil if not [NilClass, Symbol, String].include?(map.class)

         aCaller = caller
         aCaller.pop

         raise Lorj::PrcError.new(), "%s: No Object defined. Missing define_obj?" % [ self.class], aCaller if @@Context[:oCurrentObj].nil?

         sCloudObj = @@Context[:oCurrentObj]
         oKeyPath = KeyPath.new(key)
         oMapPath = KeyPath.new(map)

         @@Context[:oCurrentKey] = oKeyPath

         Lorj::rhSet(@@meta_obj, oMapPath.sFullPath, sCloudObj, :query_mapping, oKeyPath.sFullPath)
      end

      # Available functions exclusively for Controler (derived from BaseDefinition) class declaration

      # Following functions are related to Object Attributes
      # ----------------------------------------------------

      # Defines Object CloudData/CloudObj dependency
      def self.obj_needs(sType, sParam, hParams = {})
         return nil if not [String, Symbol].include?(sType.class)
         return nil if not [String, Symbol, Array].include?(sParam.class)

         hParams = {} if not hParams

         hParams[:required] = not(@@Context[:needs_optional]) if Lorj::rhExist?(hParams, :required) != 1

         aCaller = caller
         aCaller.pop

         raise Lorj::PrcError.new(), "%s: No Object defined. Missing define_obj?" % [ self.class], aCaller if @@Context[:oCurrentObj].nil?

         sCloudObj = @@Context[:oCurrentObj]

         aForEvents = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas).keys
         hParams = hParams.merge({ :for => aForEvents}) if not hParams.key?(:for)
         sType = sType.to_sym if sType.class == String


         raise Lorj::PrcError.new(), "%s: '%s' not declared. Missing define_obj(%s)?" % [ self.class, sCloudObj, sCloudObj], aCaller if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         oObjTopParam = Lorj::rhGet(@@meta_obj, sCloudObj, :params)
         if not oObjTopParam.key?(:keys)
            # Initialize top structure

            oObjTopParam.merge!({ :keys => {} })
         end

         oKeyPath = KeyPath.new(sParam)
         sKeyAccess = oKeyPath.sFullPath

         @@Context[:oCurrentKey] = oKeyPath

         oCloudObjParam = Lorj::rhGet(oObjTopParam, :keys, sKeyAccess)
         if oCloudObjParam.nil?
            sMsgAction = "New"
            oObjTopParam[:keys][sKeyAccess] = {}
            oCloudObjParam = oObjTopParam[:keys][sKeyAccess]
         else
            sMsgAction = "Upd"
         end
         sObjectName = "'%s.%s'" %  [self.class, sCloudObj]
         case sType
            when :data
               if Lorj::Default.meta_exist?(sParam)
                  Lorj.debug(2, "%-28s: %s predefined config '%s'." % [sObjectName, sMsgAction, sParam])
               else
                  Lorj.debug(2, "%-28s: %s runtime    config '%s'." % [sObjectName, sMsgAction, sParam])
               end
               oCloudObjParam.merge!( hParams.merge({:type => sType}) ) # Merge from predefined params, but ensure type is never updated.
            when :CloudObject
               raise Lorj::PrcError.new(), "%s: '%s' not declared. Missing define_obj(%s)?" % [self.class, sParam, sParam], aCaller if not @@meta_obj.key?(sParam)
               oCloudObjParam.merge!( hParams.merge({:type => sType}) ) # Merge from predefined params, but ensure type is never updated.
            else
               raise Lorj::PrcError.new(), "%s: Object parameter type '%s' unknown." % [ self.class, sType ], aCaller
         end
      end

      # Define the hdata values to build for the controller automatically
      # Input:
      # - sParam: Data name to add in hdata controller.
      # - hParams: supports following hash values:
      #   - :mapping (merged in @@meta_obj://<Object>/:params/:keys/<keypath>/:mapping)
      #

      def self.set_hdata(sParam, hParams = {})
         return nil if not [String, Symbol, Array].include?(sParam.class)

         hParams = {} if not hParams

         aCaller = caller
         aCaller.pop

         raise Lorj::PrcError.new(), "%s: No Object defined. Missing define_obj?" % [ self.class], aCaller if @@Context[:oCurrentObj].nil?
         sCloudObj = @@Context[:oCurrentObj]

         raise Lorj::PrcError.new(), "%s: '%s' not declared. Missing define_obj(%s)?" % [ self.class, sCloudObj, sCloudObj], aCaller if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         oKeyPath = KeyPath.new(sParam)
         sKeyAccess = oKeyPath.sFullPath

         # @@meta_obj://<Object>/:params/:keys/<keypath> must exist.
         oCloudObjParam = Lorj::rhGet(@@meta_obj, sCloudObj, :params, :keys, sKeyAccess)

         sMapping = sParam
         sMapping = hParams[:mapping] unless hParams[:mapping].nil?
         oCloudObjParam[:mapping] = sMapping

         sObjectName = "'%s.%s'" %  [self.class, sCloudObj]
         Lorj.debug(2, "%-28s: hdata set '%s' => '%s'" % [sObjectName, sParam, sMapping])
      end


      def self.attr_value_mapping(value, map)
         return nil if not [String, Symbol].include?(value.class)
         return nil if not [NilClass, Symbol, String].include?(map.class)

         aCaller = caller
         aCaller.pop

         sCloudObj = @@Context[:oCurrentObj]
         raise Lorj::PrcError.new, "attr_value_mapping: mapping '%s' needs object context definition. You need to call define_obj to get the context." % value if sCloudObj.nil?

         oKeypath = @@Context[:oCurrentKey]
         raise Lorj::PrcError.new, "attr_value_mapping: mapping '%s' needs object data context definition. You need to call define_obj, then obj_needs to get the context." % value if oKeypath.nil?

         keypath = oKeypath.sFullPath
         Lorj.debug(2, "%s-%s: Value mapping definition '%s' => '%s'" % [sCloudObj, oKeypath.to_s, value, map])
         Lorj::rhSet(@@meta_obj, map, sCloudObj, :value_mapping, keypath, value)
      end

      def self.def_attribute(key, options = nil)
         self.get_attr_mapping(key, options)
         #~ self.def_query_attribute(key) unless options and options.key?(:not_queriable) and  options[:not_queriable]== true
      end

      # Function used by the controler to define mapping.
      # By default, any attributes are queriable as well. No need to call
      # query_mapping
      def self.get_attr_mapping(key, map = nil, options = nil)
         return nil if not [String, Symbol].include?(key.class)
         return nil if not [NilClass, Symbol, String, Array].include?(map.class)

         aCaller = caller
         aCaller.pop

         raise Lorj::PrcError.new(), "%s: No Object defined. Missing define_obj?" % [ self.class], aCaller if @@Context[:oCurrentObj].nil?

         sCloudObj = @@Context[:oCurrentObj]
         oKeyPath = KeyPath.new(key)

         if map.nil?
            oMapPath = oKeyPath
            map = oMapPath.sKey
         else
            oMapPath = KeyPath.new(map)
         end

         Lorj::rhSet(@@meta_obj, oMapPath.sFullPath, sCloudObj, :returns, oKeyPath.sFullPath)
         @@Context[:oCurrentKey] = oKeyPath
         if oMapPath == oKeyPath
            Lorj::debug(4, "%s: Defining object attribute '%s'" % [sCloudObj, oKeyPath.sFullPath])
         else
            Lorj::debug(4, "%s: Defining object attribute mapping '%s' => '%s'" % [sCloudObj, oKeyPath.sFullPath, oMapPath.sFullPath])
         end

         self.query_mapping(key, map) unless options and options.key?(:not_queriable) and  options[:not_queriable]== true
      end

      def self.undefine_attribute(key)
         return nil if not [String, Symbol].include?(key.class)

         aCaller = caller
         aCaller.pop

         raise Lorj::PrcError.new(), "%s: No Object defined. Missing define_obj?" % [ self.class], aCaller if @@Context[:oCurrentObj].nil?

         sCloudObj = @@Context[:oCurrentObj]
         oKeyPath = KeyPath.new(key)

         Lorj::rhSet(@@meta_obj, nil, sCloudObj, :returns, oKeyPath.sFullPath)
         @@Context[:oCurrentKey] = oKeyPath
         Lorj::debug(4, "%s: Undefining attribute mapping '%s'" % [sCloudObj, oKeyPath.sFullPath])

         self.query_mapping(key, nil)
      end

      # Defines/update CloudData parameters
      def self.define_data(sData, hMeta)
         return nil if not sData or not hMeta
         return nil if not [String, Symbol].include?(sData.class)
         return nil if hMeta.class != Hash

         aCaller = caller
         aCaller.pop

         sData = sData.to_sym if sData.class == String
         raise Lorj::PrcError.new(), "%s: Config data '%s' unknown" % [self.class, sData], aCaller if not Lorj::Default.meta_exist?(sData)

         @@Context[:oCurrentData] = sData

         section = Lorj::Default.get_meta_section(sData)
         section = :runtime if section.nil?

         if Lorj::rhExist?(@@meta_data, section, sData) == 2
            Lorj::rhGet(@@meta_data, section, sData).merge!(hMeta)
         else
            Lorj::rhSet(@@meta_data, hMeta, section, sData)
         end

      end

      def self.data_value_mapping(value, map)
         return nil if not [String, Symbol].include?(value.class)
         return nil if not [NilClass, Symbol, String].include?(map.class)

         aCaller = caller
         aCaller.pop
         sData = @@Context[:oCurrentData]
         raise Lorj::PrcError.new, "Config data context not set. at least, you need to call define_data before." if sData.nil?

         section = Lorj::Default.get_meta_section(sData)
         section = :runtime if section.nil?

         Lorj.debug(2, "%s/%s: Define config data value mapping: '%s' => '%s'" % [section, sData, value, map])
         Lorj::rhSet(@@meta_data, map, section, sData, :value_mapping,  :controller, value)
         Lorj::rhSet(@@meta_data, value, section, sData, :value_mapping,  :process, map)
      end

      def self.provides(aObjType)
         @aObjType = aObjType
      end

      def self.defined?(objType)
         @aObjType.include?(objType)
      end

      # Internal BaseDefinition function

      def self.predefine_data_value(data, hOptions)
         return nil if self.class != BaseDefinition # Refuse to run if not a BaseDefinition call
         return nil if not [String, Symbol].include?(value.class)
         return nil if not [NilClass, Symbol, String].include?(map.class)

         aCaller = caller
         aCaller.pop

         oKeyPath = @@Context[:oCurrentKey]

         value = {data => {:options => hOptions} }

         Lorj::rhSet(@@predefine_data_value, value, oKeyPath.sFullPath, :values)
      end


   end
end
