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


require 'rubygems'
require 'yaml'

module Lorj

   # Recursive Hash existence
   # This function will returns the level of recursive hash was found.
   # * *Args* :
   #   - +yVal+ : Hash of hashes (or recursive hash).
   #   - +p+    : Array of string or symbols. keys tree to follow and check existence in yVal.
   #
   # * *Returns* :
   #   - +integer+ : Represents how many keys was found in the recursive hash
   #
   # * *Raises* :
   #   No exceptions
   #
   # Example:
   #
   #    yVal = { :test => {:test2 => 'value1', :test3 => 'value2'}, :test4 => 'value3'}
   #
   # yVal can be represented like:
   #
   #   yVal:
   #     test:
   #       test2 = 'value1'
   #       test3 = 'value2'
   #     test4 = 'value3'
   #
   # so:
   #   rhExist?(yVal, :test) => 1 # test is found
   #   rhExist?(yVal, :test5) => 0 # no test5
   #   rhExist?(yVal, :test, :test2) => 2 # :test/:test2 tree is found
   #   rhExist?(yVal, :test, :test2, :test5) => 2 # :test/:test2 is found (value = 2), but :test5 was not found in this tree
   #   rhExist?(yVal, :test, :test5 ) => 1 # :test was found. but :test/:test5 tree was not found. so level 1, ok.
   #   rhExist?(yVal) => 0 # it is like searching for nothing...

   def Lorj::rhExist?(yVal, *p)

      if p.length() == 0
         return 0
      end
      return 0 if yVal.class != Hash
      p=p.flatten
      if p.length() == 1
         return 1 if yVal.key?(p[0])
         return 0
      end
      return 0 if yVal.nil? or not yVal.key?(p[0])
      ret = 0
      ret = Lorj::rhExist?(yVal[p[0]], p.drop(1)) if yVal[p[0]].class == Hash
      return 1 + ret
   end

   # Recursive Hash Get
   # This function will returns the level of recursive hash was found.
   # * *Args* :
   #   - +yVal+ : Hash of hashes (or recursive hash).
   #   - +p+    : Array of string or symbols. keys tree to follow and check existence in yVal.
   #
   # * *Returns* :
   #   - +value+ : Represents the data found in the tree. Can be of any type.
   #
   # * *Raises* :
   #   No exceptions
   #
   # Example:
   #
   #    yVal = { :test => {:test2 => 'value1', :test3 => 'value2'}, :test4 => 'value3'}
   #
   # yVal can be represented like:
   #
   #   yVal:
   #     test:
   #       test2 = 'value1'
   #       test3 = 'value2'
   #     test4 = 'value3'
   #
   # so:
   #   rhGet(yVal, :test) => {:test2 => 'value1', :test3 => 'value2'}
   #   rhGet(yVal, :test5) => nil
   #   rhGet(yVal, :test, :test2) => 'value1'
   #   rhGet(yVal, :test, :test2, :test5) => nil
   #   rhGet(yVal, :test, :test5 ) => nil
   #   rhGet(yVal) => nil
   def Lorj::rhGet(yVal, *p)

      return nil if yVal.class != Hash
      p=p.flatten
      if p.length() == 0 or not yVal
         return yVal
      end
      if p.length() == 1
         return yVal[p[0]] if yVal.key?(p[0])
         return nil
      end
      return nil if not yVal
      return Lorj::rhGet(yVal[p[0]], p.drop(1)) if yVal.key?(p[0])
      nil
   end

   # Recursive Hash Set
   # This function will build a recursive hash according to the '*p' key tree.
   # if yVal is not nil, it will be updated.
   #
   # * *Args* :
   #   - +yVal+ : Hash of hashes (or recursive hash).
   #   - +p+    : Array of string or symbols. keys tree to follow and check existence in yVal.
   #
   # * *Returns* :
   #   - +value+ : the value set.
   #
   # * *Raises* :
   #   No exceptions
   #
   # Example:
   #
   #    yVal = {}
   #
   #   rhSet(yVal, :test) => nil
   #   # yVal = {}
   #
   #   rhSet(yVal, :test5) => nil
   #   # yVal = {}
   #
   #   rhSet(yVal, :test, :test2) => :test
   #   # yVal = {:test2 => :test}
   #
   #   rhSet(yVal, :test, :test2, :test5) => :test
   #   # yVal = {:test2 => {:test5 => :test} }
   #
   #   rhSet(yVal, :test, :test5 ) => :test
   #   # yVal = {:test2 => {:test5 => :test}, :test5 => :test }
   #
   #   rhSet(yVal, 'blabla', :test2, 'text') => :test
   #   # yVal  = {:test2 => {:test5 => :test, 'text' => 'blabla'}, :test5 => :test }
   def Lorj::rhSet(yVal, value, *p)
      if p.length() == 0
         return yVal
      end
      p=p.flatten
      if p.length() == 1
         if not yVal.nil?
            if not value.nil?
               yVal[p[0]] = value
            else
               yVal.delete(p[0])
            end
            return yVal
         end
         #~ if value
         ret = { p[0] => value }
         #~ else
            #~ ret = {}
         #~ end
         return ret
      end
      if not yVal.nil?
         yVal[p[0]] = {} if not yVal[p[0]] or yVal[p[0]].class != Hash
         ret=Lorj::rhSet(yVal[p[0]], value, p.drop(1))
         return yVal
      else
         ret = Lorj::rhSet(nil, value, p.drop(1))
         return { p[0] => ret }
      end
   end

   # Move levels (default level 1) of tree keys to become symbol.
   #
   # * *Args*    :
   #   - +yVal+  : Hash of hashes (or recursive hash).
   #   - +levels+: level of key tree to update.
   # * *Returns* :
   #   - hash of hashes updated.
   # * *Raises* :
   #   Nothing
   def Lorj.rhKeyToSymbol(yVal, levels = 1)
      return nil if yVal.nil? or yVal.class != Hash
      yRes = {}
      yVal.each { | key, value |
      if key.class == String
         if levels <= 1
            yRes[key.to_sym] = value
         else
            yRes[key.to_sym] = rhKeyToSymbol(value, levels - 1)
         end
      else
         if levels <= 1
            yRes[key] = value
         else
            yRes[key] = rhKeyToSymbol(value, levels - 1)
         end
      end
      }
      yRes
   end

   # Check if levels of tree keys are all symbols.
   #
   # * *Args*    :
   #   - +yVal+  : Hash of hashes (or recursive hash).
   #   - +levels+: level of key tree to update.
   # * *Returns* :
   #   - true  : one key path is not symbol.
   #   - false : all key path are symbols.
   # * *Raises* :
   #   Nothing
   def Lorj.rhKeyToSymbol?(yVal, levels = 1)
      return false if yVal.nil? or yVal.class != Hash
      yVal.each { | key, value |
      if key.class == String
         return true
      end
      if levels >1
         res = rhKeyToSymbol?(value, levels - 1)
         return true if res
      end
      }
      false
   end

   # This class is the Application configuration class used by Lorj::Config
   #
   # It load a defaults.yaml file (path defined by PrcLib::app_defaults)
   #
   # defaults.yaml is divided in 3 sections:
   #
   # * :default: Contains a list of key = value
   # * :setup:   Contains :ask_step array
   #   - :ask_step: Array of group of keys/values to setup. Each group will be internally identified by a index starting at 0. parameters are as follow:
   #     - :desc:        string to print out before group setup
   #     - :explanation: longer string to display after :desc:
   #     - :add:         array of keys to add manually in the group.
   #
   #       By default, thanks to data model dependency, the group is automatically populated.
   #
   # * :section: Contains a list of sections contains several key and attributes and eventually :default:
   #   This list of sections and keys will be used to build the account files with the lorj Lorj::Core::Setup function.
   #
   #   - :default: This section define updatable data available from config.yaml. But will never be added in an account file.
   #     It contains a list of key and options.
   #
   #     - :<aKey>: Possible options
   #       - :desc: default description for that <aKey>
   #
   #   - :<aSectionName>: Name of the section which should contains a lis
   #     - :<aKeyName>: Name of the key to setup.
   #       - :desc:              Description of that key, printed out at setup time.
   #       - :readonly:          true if this key is not modifiable by a simple Lorj::Account::set function. false otherwise.
   #       - :account_exclusive: true if the key cannot be set as default from config.yaml or defaults.yaml.
   #       - :account:           true to ask setup to ask this key to the user.
   #       - :validate:          Ruby Regex to validate the end user input. Ex: !ruby/regexp /^\w?\w*$/
   #       - :default_value:     default value proposed to the user.
   #       - :ask_step:          Define the group number to attach the key to be asked. ex: 2
   #       - :list_values:       Provide capabililities to get a list and choose from.
   #         - :query_type:      Can be:
   #
   #           ':query_call' to execute a query on flavor, query_params is empty for all.
   #
   #           ':process_call' to execute a process function to get the values.
   #
   #           ':controller_call' to execute a controller query.
   #
   #         - :object:
   #
   #           Used with :query_type=:query_call. object type symbol to query.
   #
   #         - :query
   #
   #           Used with :query_type=:process_call. process function name to call.
   #
   #         - :query_call:
   #
   #           Used with :query_type=:controller_call. Handler function to use. (query_e, create_e, ...)
   #
   #           Used with :query_type=:process_call. Function name to call
   #
   #         - :query_params:
   #
   #           Used with :query_type=:query_call. Query hash defining filtering capabilities.
   #
   #           Used with :query_type=:process_call. hParams data passed to the process function.
   #
   #         - :value:           fields to extract for the list of objects displayed.
   #         - :validate:        if :list_strict, the value is limited to the possible values from the list

   class Default

      # @sDefaultsName='defaults.yaml'
      # @yDefaults = defaults.yaml file data hash

      # Load yaml documents (defaults)
      # If config doesn't exist, it will be created, empty with 'defaults:' only

      # class.exist?
      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.exist?(key, section = :default)
         key = key.to_sym if key.class == String
         (Lorj::rhExist?(@@yDefaults, section, key) == 2)
      end

      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.get(key, section = :default)
         key = key.to_sym if key.class == String
         return(Lorj::rhGet(@@yDefaults, section, key)) if key
         Lorj::rhGet(@@yDefaults, section) if not key
      end

      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.dump()
         @@yDefaults
      end

      # Loop on Config metadata
      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.meta_each
         Lorj::rhGet(@@yDefaults, :sections).each { | section, hValue |
            hValue.each { | key, value |
               yield section, key, value
               }
            }
      end

      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.meta_exist?(key)
         return nil if not key

         key = key.to_sym if key.class == String

         section = Lorj::rhGet(@@account_section_mapping, key)
         Lorj::rhExist?(@@yDefaults, :sections, section, key) == 3
      end

      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.get_meta(key)
         return nil if not key

         key = key.to_sym if key.class == String
         section = Lorj::rhGet(@@account_section_mapping, key)
         Lorj::rhGet(@@yDefaults, :sections, section, key)
      end

      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.build_section_mapping

         Lorj::rhGet(@@yDefaults, :sections).each { | section, hValue |
            next if section == :default
            hValue.each_key { | map_key |
               PrcLib.fatal(1, "defaults.yaml: Duplicate entry between sections. '%s' defined in section '%s' already exists in section '%s'" % [map_key, section, Lorj::rhGet(@account_section_mapping, map_key) ])if Lorj::rhExist?(@account_section_mapping, map_key) != 0
               Lorj::rhSet(@@account_section_mapping, section, map_key)
               }
            }
      end

      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.get_meta_section(key)
         key = key.to_sym if key.class == String
         Lorj::rhGet(@@account_section_mapping, key)
      end

      #
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def self.load()

         @@account_section_mapping = {}
         @@yDefaults = {}
         @@sDefaultsName = nil

         if not PrcLib.app_defaults
            PrcLib.warning("PrcLib.app_defaults is not set. Application defaults won't be loaded.")
         else
            @@sDefaultsName = File.join(PrcLib.app_defaults,'defaults.yaml')

            PrcLib.info("Reading default configuration '%s'..." % @@sDefaultsName)

            @@yDefaults = YAML.load_file(@@sDefaultsName)

            self.build_section_mapping
         end
      end

   end


   # Lorj::Config is a generic class for configuration management.
   # It is used by lorj to get/set data
   #
   # lorj uses following function in different context:
   #
   # In your main:
   # * Config.set        : To set runtime depending on options given by the user (cli parameters for example)
   # * Config.get        : To get any kind of data, for example to test values.
   # * Config.saveConfig : To save setting in local config. Use Lorj::Config::LocalSet to set this kind of data to save
   # * Config.localSet   : To set a local default data. If the main wanted to manage local config.
   # * Config.meta_each  : For example to display all data per section name, with values.
   #
   # In Process functions: The Config object is accessible as 'config'.
   # * config.set        : To set runtime data. Ex: adapt process runtime behavior.
   #   The best approach is to declare an obj_needs optional. lorj will set it in hParams.
   # * config.get        : To get data and adapt process behavior.
   #   The best approach is to declare an obj_needs optional and get the value from hParams.
   #
   # In Controller functions.
   # Usually, the process has implemented everything.
   # You should not use the config object. Thus, config object is not accessible.

   class Config

      # Internal Object variables:
      #
      # * @sConfigName= 'config.yaml'
      # * @yRuntime   = data in memory.
      # * @yLocal     = config.yaml file data hash.
      # * @yObjConfig = Extra loaded data
      # * Lorj::Default  = Application defaults class

      attr_reader :sConfigName

      # Basic dump
      #
      # * *Args*    :
      #   - +interms+ : Will be obsoleted shortly.
      # * *Returns* :
      #   - hash of hashes.
      # * *Raises* :
      #   nothing
      def default_dump(interms = nil)
         # Build a config hash.

         res = {}
         Lorj::Default.dump[:default].each_key { |key|
            dump_key = exist?(key)
            Lorj::rhSet(res, get(key), dump_key, key)
            }
         if Lorj::rhExist?(@yLocal, :default) == 1
            @yLocal[:default].each_key { |key|
            dump_key = exist?(key)
            Lorj::rhSet(res, get(key), dump_key, key) if Lorj::rhExist?(res, dump_key, key) != 2
            }
         end
         if interms
            if interms.instance_of? Hash
               @interms.each_key { | key|
                  dump_key = exist?(key)
                  Lorj::rhSet(res, get(key), dump_key, key) if Lorj::rhExist?(res, dump_key, key) != 2
                  }
            elsif interms.instance_of? Array # Array of hash of hash
               interms.each { | elem |
                  elem.each_key { | key|
                  dump_key = exist?(key)
                     Lorj::rhSet(res, get(key), dump_key, key) if Lorj::rhExist?(res, dump_key, key) != 2
                     }
                  }
            end
         end
         @yRuntime.each_key { |key|
            dump_key = exist?(key)
            Lorj::rhSet(res, get(key), dump_key, key) if Lorj::rhExist?(res, dump_key, key) != 2
            }

         res
      end

      # Load yaml documents (defaults + config)
      # If config doesn't exist, it will be created, empty with 'defaults:' only
      #
      #
      # * *Args*    :
      #   - +sConfigName+ : Config file name to use. By default, file path is built as PrcLib.data_path+'config.yaml'
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def initialize(sConfigName=nil)

         Default.load() # Loading global application defaults

         if PrcLib.data_path.nil?
            PrcLib.fatal(1, 'Internal PrcLib.data_path was not set.')
         end

         sConfigDefaultName='config.yaml'

         if sConfigName
            if File.dirname(sConfigName) == '.'
               sConfigName = File.join(PrcLib.data_path,sConfigName)
            end
            sConfigName = File.expand_path(sConfigName)
            if not File.exists?(sConfigName)
               PrcLib.warning("Config file '%s' doesn't exists. Using default one." % [sConfigName] )
               @sConfigName = File.join(PrcLib.data_path,sConfigDefaultName)
            else
               @sConfigName = sConfigName
            end
         else
            @sConfigName = File.join(PrcLib.data_path,sConfigDefaultName)
         end

         if File.exists?(@sConfigName)
            @yLocal = YAML.load_file(@sConfigName)
            if Lorj::rhKeyToSymbol?(@yLocal, 2)
               @yLocal = Lorj::rhKeyToSymbol(@yLocal, 2)
               self.saveConfig()
            end

         else
            @yLocal = { :default => nil }
            # Write the empty file
            PrcLib.info('Creating your default configuration file ...')
            self.saveConfig()
         end

         @yRuntime = {}
         @yObjConfig = {}
      end

      # Save the config.yaml file.
      #
      # * *Args*    :
      #   nothing
      # * *Returns* :
      #   - true/false
      # * *Raises* :
      #   nothing
      def saveConfig()
        begin
          File.open(@sConfigName, 'w') do |out|
            YAML.dump(@yLocal, out)
          end
        rescue => e
          Lorj.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
          return false
        end
        PrcLib.info('Configuration file "%s" updated.' % @sConfigName)
        return true
      end

      # Save extra data to a file. Will be obsoleted.
      #
      # * *Args*    :
      #   - +sFile+   : File name to use for saving data.
      #   - +section+ : Section name where to find the key structure to save.
      #   - +name+    : key structure name found in section to save.
      # * *Returns* :
      #   - true/false
      # * *Raises* :
      #   nothing
      def extraSave(sFile, section, name)
         hVal = Lorj::rhGet(@yObjConfig, section, name)
         if hVal
            begin
               File.open(sFile, 'w') do |out|
                  YAML.dump(hVal, out)
               end
            rescue => e
               Lorj.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
               return false
            end
            PrcLib.info('Configuration file "%s" updated.' % sFile)
            return true
         end
      end

      # Load extra data from a file. Will be obsoleted.
      #
      # * *Args*    :
      #   - +sFile+   : File name to use for saving data.
      #   - +section+ : Section name where to find the key structure to save.
      #   - +name+    : key structure name found in section to save.
      # * *Returns* :
      #   - key tree loaded.
      # * *Raises* :
      #   nothing
      def extraLoad(sFile, section, name)
         if File.exists?(sFile)
            hVal = YAML.load_file(sFile)
            Lorj::rhSet(@yObjConfig, hVal, section, name)
            hVal
         end
      end

      # Check from Extra data existence of keys tree. Will be obsoleted.
      #
      # * *Args*    :
      #   - +section+ -> Section Name
      #   - +name+    -> Key Name
      #   - +key+     -> key tree
      # * *Returns* :
      #   - true or false
      # * *Raises* :
      #   Nothing

      def extraExist?(section, name, key = nil)
         return nil if not section or not name

         key = key.to_sym if key.class == String

         return(Lorj::rhExist?(@yObjConfig, section, name) == 2) if not key
         return(Lorj::rhExist?(@yObjConfig, section, name, key) == 3)
      end

      # Get from Extra data existence of keys tree. Will be obsoleted.
      #
      # * *Args*    :
      #   - +section+ -> Section Name
      #   - +name+    -> Key Name
      #   - +key+     -> key tree
      #   - +default+ -> default value
      # * *Returns* :
      #   - value found
      # * *Raises* :
      #   Nothing

      def extraGet(section, name, key = nil, default = nil)
         return nil if not section or not name

         key = key.to_sym if key.class == String
         return default unless ExtraExist?(section, name, key)
         return Lorj::rhGet(@yObjConfig, section, name, key) if key
         Lorj::rhGet(@yObjConfig, section, name)
      end

      # Set to Extra data existence of keys tree. Will be obsoleted.
      #
      # * *Args*    :
      #   - +section+ -> Section Name
      #   - +name+    -> Key Name
      #   - +key+     -> key tree
      #   - +value+   -> Value to set
      # * *Returns* :
      #   - value set
      # * *Raises* :
      #   Nothing
      def extraSet(section, name, key, value)
        key = key.to_sym if key.class == String
        if key
            Lorj::rhSet(@yObjConfig, value, section, name, key)
         else
            Lorj::rhSet(@yObjConfig, value, section, name)
         end
      end

      # Function to set a runtime key/value, but remove it if value is nil.
      # To set in config.yaml, use Lorj::Config::LocalSet
      # To set on extra data, like account information, use Lorj::Config::ExtraSet
      #
      # * *Args*    :
      #   - +key+   : key name. Can be an key tree (Array of keys).
      #   - +value+ : Value to set
      # * *Returns* :
      #   - value set
      # * *Raises* :
      #   Nothing
      def set(key, value)

         key = key.to_sym if key.class == String

         return false if not([Symbol, Array].include?(key.class))

         Lorj::rhSet(@yRuntime, value, key)
         true
      end

      # Call set function
      #
      # * *Args*    :
      #   - +key+   : key name. Can be an key tree (Array of keys).
      #   - +value+ : Value to set
      # * *Returns* :
      #   - value set
      # * *Raises* :
      #   Nothing
      def []=(key, value)
         set(key, value)
      end

      # Check if the key exist as a runtime data.
      #
      # * *Args*    :
      #   - +key+   : key name. It do not support it to be a key tree (Arrays of keys).
      # * *Returns* :
      #   - true/false
      # * *Raises* :
      #   Nothing

      def runtimeExist?(key)
         (Lorj::rhExist?(@yRuntime, key) == 1)
      end

      # Get exclusively the Runtime data.
      # Internally used by get.
      #
      # * *Args*    :
      #   - +key+   : key name. It do not support it to be a key tree (Arrays of keys).
      # * *Returns* :
      #   - key value.
      # * *Raises* :
      #   Nothing

      def runtimeGet(key)
         Lorj::rhGet(@yRuntime, key) if runtimeExist?(key)
      end

      # Get function
      # Will search over several places:
      # * runtime - Call internal runtimeGet -
      # * local config (config>yaml) - Call internal LocalGet -
      # * application default (defaults.yaml) - Call Lorj::Default.get -
      # * default
      #
      # key can be an array, a string (converted to a symbol) or a symbol.
      #
      # * *Args*    :
      #   - +key+    : key name
      #   - +default+: Default value to set if not found.
      # * *Returns* :
      #   value found or default
      # * *Raises* :
      #   nothing

      def get(key, default = nil)
         key = key.to_sym if key.class == String
         return nil if not([Symbol, Array].include?(key.class))
         # If key is in runtime
         return runtimeGet(key) if runtimeExist?(key)
         # else key in local default config of default section.
         return localGet(key) if localDefaultExist?(key)
         # else key in application defaults
         return Lorj::Default.get(key) if Lorj::Default.exist?(key)
         # else default
         default
      end

      # Call get function
      #
      # * *Args*    :
      #   - +key+    : key name
      #   - +default+: Default value to set if not found.
      # * *Returns* :
      #   value found or default
      # * *Raises* :
      #   nothing

      def [](key, default = nil)
         get(key, default)
      end

      # Get Application data
      # Used to get any kind of section available in the Application default.yaml.
      #
      # * *Args*    :
      #   - +section+: section name to get the key.
      #   - +key+    : key name
      # * *Returns* :
      #   value found
      # * *Raises* :
      #   nothing
      def getAppDefault(section, key = nil)

         key = key.to_sym if key.class == String

         Lorj::Default.get(key, section)
      end

      # Check where the get or [] is going to get the data
      #
      # * *Args*    :
      #   - +key+     : Symbol/String(converted to symbol) key name to test.
      #   - +interms+ : <b>Will be removed shortly!!!</b> Add intermediate hash to check
      # * *Returns* :
      #   - false             if no value found.
      #   - 'runtime'         if found in runtime.
      #   - '%s'              if found in intermediate. <b>Will be removed shortly!!!</b>
      #   - 'hash[%s]'        if found in intermediate. <b>Will be removed shortly!!!</b>
      #   - 'hash'            if found in intermediate. <b>Will be removed shortly!!!</b>
      #   - 'local'           if get from local config (config.yaml)
      #   - 'default'         if get from application default (defaults.yaml)
      #   -
      # * *Raises* :
      #   nothing
      def exist?(key, interms = nil)
         key = key.to_sym if key.class == String

         # Check data in intermediate hashes or array of hash. (like account data - key have to be identical)
         return "runtime" if Lorj::rhExist?(@yRuntime, key) == 1
         if interms
            if interms.instance_of? Hash
               return 'hash' if Lorj::rhExist?(interms, key) == 1
            elsif interms.instance_of? Array # Array of hash
               iCount = 0
               interms.each { | elem |
                  if elem.class == Hash
                     elem.each { | hashkey, value |
                        return ("%s" % hashkey)  if value.class == Hash and Lorj::rhExist?(elem, hashkey, key) == 2
                        return ("hash[%s]" % iCount)  if value.class != Hash and Lorj::rhExist?(elem, hashkey) == 1
                        }
                  end
                  iCount += 1
                  }
            end
         end
         return 'local' if localDefaultExist?(key)
         # else key in application defaults
         return 'default' if Lorj::Default.exist?(key)
         false
      end

      #
      # Function to check default keys existence(in section :default) from local config file only.
      #
      # * *Args*    :
      #   - +key+     : Symbol/String(converted to symbol) key name to test.
      # * *Returns* :
      #   -
      # * *Raises* :
      #   nothing
      def localDefaultExist?(key)
         localExist?(key)
      end

      # Function to check key existence from local config file only.
      #
      # * *Args*    :
      #   - +key+     : Symbol/String(converted to symbol) key name to test.
      #   - +section+ : Section name to test the key.
      # * *Returns* :
      #   -
      # * *Raises* :
      #   nothing
      def localExist?(key, section = :default)

         key = key.to_sym if key.class == String
         return true if Lorj::rhExist?(@yLocal, section, key) == 2
         false
      end

      # Function to set a key value in local config file only.
      #
      # * *Args*    :
      #   - +key+     : Symbol/String(converted to symbol) key name to test.
      #   - +value+   : Value to set
      #   - +section+ : Section name to test the key.
      #
      # * *Returns* :
      #   - Value set.
      # * *Raises* :
      #   nothing
      def localSet(key, value, section = :default)
        key = key.to_sym if key.class == String
        if not key or not value
           return false
        end
        if @yLocal[section] == nil
           @yLocal[section]={}
        end
        if @yLocal.has_key?(section)
           @yLocal[section].merge!({key => value})
        else
           @yLocal.merge!(section => {key => value})
        end
        return true
      end

      # Function to Get a key value from local config file only.
      #
      # * *Args*    :
      #   - +key+     : Symbol/String(converted to symbol) key name to test.
      #   - +section+ : Section name to test the key.
      #   - +default+ : default value if not found.
      #
      # * *Returns* :
      #   - Value get or default.
      # * *Raises* :
      #   nothing
      def localGet(key, section = :default, default = nil)
        key = key.to_sym if key.class == String

        return default if Lorj::rhExist?(@yLocal, section, key) != 2
        Lorj::rhGet(@yLocal, section, key)
      end

      # Function to Delete a key value in local config file only.
      #
      # * *Args*    :
      #   - +key+     : Symbol/String(converted to symbol) key name to test.
      #   - +section+ : Section name to test the key.
      #
      # * *Returns* :
      #   - true/false
      # * *Raises* :
      #   nothing
      def localDel(key, section = :default)
        key = key.to_sym if key.class == String
        if not key
           return false
        end
        if not @yLocal.has_key?(section)
           return false
        end
        @yLocal[section].delete(key)
        return true
      end

      # Function to return in fatal error if a config data is nil. Help to control function requirement.
      #
      #
      # * *Args*    :
      #   - +key+     : Symbol/String(converted to symbol) key name to test.
      # * *Returns* :
      #   nothing
      # * *Raises* :
      #   - +fatal+ : Call to PrcLib.fatal to exit the application with error 1.
      def fatal_if_inexistent(key)
         PrcLib.fatal(1, "Internal error - %s: '%s' is missing" % [caller(), key]) if not self.get(key)
      end

      # each loop on Application Account section/key (meta data).
      # This loop will extract data from :section of the application definition (defaults.yaml)
      # key identified as account exclusive (:account_exclusive = true) are not selected.
      #
      # * *Args*    :
      #   - ++ ->
      # * *Returns* :
      #   -
      # * *Raises* :
      #   - ++ ->
      def meta_each
         Lorj::Default.meta_each { |section, key, value|
            next if Lorj::rhGet(value, :account_exclusive)
            yield section, key, value
         }
      end

   end

end
