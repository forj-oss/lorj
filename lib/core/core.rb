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

# Module Lorj which contains several classes.
#
# Those classes describes :
# - processes (BaseProcess)   : How to create/delete/edit/query object.
# - controler (BaseControler) : If a provider is defined, define how will do object creation/etc...
# - definition(BaseDefinition): Functions to declare objects, query/data mapping and setup
# this task to make it to work.

module Lorj

   # Internal Lorj function to debug lorj.
   #
   # * *Args* :
   #   - +iLevel+ : value between 1 to 5. Setting 5 is the most verbose!
   #   - +sMsg+   : Array of string or symbols. keys tree to follow and check existence in yVal.
   #
   # * *Returns* :
   #   - nothing
   #
   # * *Raises* :
   #   No exceptions
   def Lorj::debug(iLevel, sMsg)
      if iLevel <= PrcLib.core_level
         PrcLib.debug("-%s- %s" % [iLevel, sMsg])
      end
   end

   # This class is the Data object used by lorj object!
   # This is a key component of lorj
   #
   # You find this object in different places.
   #
   # type:
   # - object/data : The Data object contains any kind of data.
   #   This data contains 2 elements:
   #   - controler object : This is a ruby object managed by the controller.
   #     Only the controller has the knowledge to manage this kind of data.
   #   - attributes       : This is the internal data mapping from the controller object.
   #     The controller helped to build this data thanks to the BaseController.get_attr / BaseController.set_attr
   #     Attributes are declared by the Data model in BaseDefinition. At least usually, each object has 2 attributes: :id and :name
   #
   # - list        : The Data object contains a list of Lorj::Data
   #
   # If the object is of type :list, following functions are usable:
   #
   # - length                : return numbers of Lorj::Data
   # - each / each_index     : loop on the list, key/value or key_index. yield can return 'remove' to remove the element from the list during loop.
   #
   # If the Data object is of type :data or :object or even :list, following functions are usable.
   #
   # - set/[]=/get/[]/exist? : Basic get/set/exist? feature.
   # - type?/object_type?    : Determine the type of this object. ie :data (stands for :object as well) or :list
   # - to_a                  : Array of Data attributes
   # - empty? nil?           : Identify if the object is empty. Avoid to use nil?.
   # - register/unregister   : Used by Lorj::BaseDefinition internal @ObjectData.
   #   registered?           : Determine if this object is stored in the global object cache.

   class Lorj::Data

      def initialize(oType = :object)
         # Support :data for single object data
         #         :list for a list of object data
         oType = :data if not [:list, :object, :data].include?(oType)
         @oType = oType
         case oType
            when :data, :object
               @data = new_object
            when :list
               @data = new_object_list
         end
      end

      def type?()
         @oType
      end

      def object_type?()
         @data[:object_type]
      end

      def set(oObj, sObjType = nil, hQuery = {})
         if oObj.is_a?(Lorj::Data)
            oType = oObj.type?
            case oType
               when :data, :object
                  @data[:object_type] = ((sObjType.nil?)? (oObj.object_type?) : sObjType)
                  @data[:object] = oObj.get(:object)
                  @data[:attrs] = oObj.get(:attrs)
               when :list
                  @data[:object_type] = ((sObjType.nil?)? (oObj.object_type?) : sObjType)
                  @data[:object] = oObj.get(:object)
                  @data[:list] = oObj.get(:list)
                  @data[:query] = oObj.get(:query)
            end
            return self
         end

         # while saving the object, a mapping work is done?
         case @oType
            when :data, :object
               @data[:object_type] = sObjType
               @data[:object] = oObj
               @data[:attrs] = yield(sObjType, oObj)
            when :list
               @data[:object] = oObj
               @data[:object_type] = sObjType
               @data[:query] = hQuery
               unless oObj.nil?
                  begin
                     oObj.each { | oObject |
                        next if oObject.nil?
                        begin
                           oDataObject = Lorj::Data.new(:object)

                           oDataObject.set(oObject, sObjType) { |sObjectType, oObject|
                              yield(sObjectType, oObject)
                           }
                           @data[:list] << oDataObject
                        rescue => e
                           raise Lorj::PrcError.new(), "'%s' Mapping attributes issue.\n%s" % [sObjType, e.message]
                        end
                     }
                  rescue => e
                     raise Lorj::PrcError.new(), "each function is not supported by '%s'.\n%s" % [oObj.class, e.message]
                  end
               end
         end
         self
      end

      def type=(sObjType)
         return self if self.empty?
         @data[:object_type] = sObjType
         self
      end

      def [](*key)
         get(*key)
      end

      def []=(*key, value)
         return false if @oType == :list
         Lorj::rhSet(@data, value, :attrs, key)
         true
      end

      def get(*key)
         return @data if key.length == 0
         case @oType
            when :data, :object # Return only attrs or the real object.
               return @data[key[0]] if key[0] == :object
               return Lorj::rhGet(@data, key) if key[0] == :attrs
               Lorj::rhGet(@data, :attrs, key)
            when :list
               return @data[key[0]] if [:object, :query].include?(key[0])
               return @data[:list][key[0]] if key.length == 1
               @data[:list][key[0]][key[1..-1]] # can Return only attrs or the real object.
         end
      end

      def to_a()
         result = []
         self.each { |elem|
            result<< elem[:attrs]
         }
         result
      end

      def exist?(*key)
         case @oType
            when :data, :object
               return true if key[0] == :object and @data.key?(key[0])
               return true  if key[0] == :attrs and Lorj::rhExist?(@data, key)
               (Lorj::rhExist?(@data, :attrs, key) == key.length+1)
            when :list
               return true if key[0] == :object and @data.key?(key[0])
               (Lorj::rhExist?(@data[:list][key[0]], :attrs, key[1..-1]) == key.length)
         end
      end

      def empty?()
         @data[:object].nil?
      end

      def nil?()
         # Obsolete Use empty? instead.
         @data[:object].nil?
      end

      def length()
         case @oType
            when :data
               return 0 if self.nil?
               1
            when :list
               @data[:list].length
         end
      end

      def each(sData = :list)
         to_remove = []
         return nil if @oType != :list or not [:object, :list].include?(sData)

         @data[:list].each { |elem|
            sAction = yield (elem)
            case sAction
               when :remove
                  to_remove << elem
            end
         }
         if to_remove.length > 0
            to_remove.each { | elem |
               @data[:list].delete(elem)
            }
         end
      end

      def each_index(sData = :list)
         to_remove = []
         return nil if @oType != :list or not [:object, :list].include?(sData)

         @data[:list].each_index { |iIndex|
            sAction = yield (iIndex)
            case sAction
               when :remove
                  to_remove << @data[:list][iIndex]
            end
         }
         if to_remove.length > 0
            to_remove.each { | elem |
               @data[:list].delete(elem)
            }
         end
      end

      def registered?()
         @bRegister
      end

      def register()
         @bRegister = true
         self
      end

      def unregister()
         @bRegister = false
         self
      end
      private

      def new_object_list
         {
            :object        => nil,
            :object_type   => nil,
            :list          => [],
            :query         => nil
         }
      end

      def new_object
         oCoreObject = {
            :object_type => nil,
            :attrs => {},
            :object => nil,
         }
      end

   end

   # Internal PrcError class object derived from RuntimeError.
   # Internally used with raise.
   # Used to identify the error origin, while an error is thrown.
   class PrcError < RuntimeError
      attr_reader :ForjMsg

      def initialize(message = nil)
         @ForjMsg = message
      end
   end

   # Class to handle key or keypath on needs
   # The application configuration can configure a key tree, instead of a key.
   # KeyPath is used to commonly handle key or key tree.
   # Thus, a Keypath can be converted in different format:
   #
   # Ex:
   # oKey = KeyPath(:test)
   # puts oKey.to_s      # => 'test'
   # puts oKey.sKey      # => :test
   # puts oKey.sKey[0]   # => :test
   # puts oKey.sKey[1]   # => nil
   # puts oKey.sFullPath # => ':test'
   #  puts oKey.aTree    # => [:test]
   #
   # oKey = KeyPath([:test,:test2,:test3])
   # puts oKey.to_s      # => 'test/test2/test3'
   # puts oKey.sKey      # => :test3
   # puts oKey.sKey[0]   # => :test
   # puts oKey.sKey[1]   # => :test2
   # puts oKey.sFullPath # => ':test/:test2/:ẗest3'
   # puts oKey.aTree     # => [:test,:test2,:test3]
   #
   class KeyPath

      def initialize(sKeyPath = nil)

         @keypath = []
         self.set sKeyPath
      end

      def key=(sKeyPath)
         self.set(sKeyPath)
      end

      def set(sKeyPath)

         if sKeyPath.is_a?(Symbol)
            @keypath = [ sKeyPath]
         elsif sKeyPath.is_a?(Array)
            @keypath = sKeyPath
         elsif sKeyPath.is_a?(String)
            if /[^\\\/]?\/[^\/]/ =~ sKeyPath or /:[^:\/]/ =~ sKeyPath
               # keypath to interpret
               aResult = sKeyPath.split('/')
               aResult.each_index { | iIndex |
                  next if not aResult[iIndex].is_a?(String)
                  aResult[iIndex] = aResult[iIndex][1..-1].to_sym if aResult[iIndex][0] == ":"
               }
               @keypath = aResult
            else
               @keypath = [sKeyPath]
            end
         end
      end

      def aTree()
         @keypath
      end

      def sFullPath()
         return nil if @keypath.length == 0
         aKeyAccess = @keypath.clone
         aKeyAccess.each_index { |iIndex|
            next if not aKeyAccess[iIndex].is_a?(Symbol)
            aKeyAccess[iIndex] = ":" + aKeyAccess[iIndex].to_s
         }
         aKeyAccess.join('/')
      end

      def to_s
         return nil if @keypath.length == 0
         aKeyAccess = @keypath.clone
         aKeyAccess.each_index { |iIndex|
            next if not aKeyAccess[iIndex].is_a?(Symbol)
            aKeyAccess[iIndex] = aKeyAccess[iIndex].to_s
         }
         aKeyAccess.join('/')
      end

      def sKey(iIndex = -1)
         return nil if @keypath.length == 0
         @keypath[iIndex] if self.length >= 1
      end

      def length()
         @keypath.length
      end
   end

   # This is the main lorj class.
   # It interfaces your main code with the full lorj system as shown in the concept document.
   # It give you access to the lorj model object designed by your process.
   #
   # When you start using it, your main must be as simple as you can, as you will need to move
   # most of your application logic to the process.
   # Your application can have several lorj objects running in your code, depending of your needs.
   #
   # The main things is that you can move most of your process management, usually in your code/modules
   # to be part of the lorj process, make it controller independant, and gains in
   # implementing several controllers to change the way to implement but not the process
   # you used to build your application!
   #
   # Then, your application contributors can build their own controller and extend your solution!
   #
   # Here an example of creating a CloudServer, using CloudCore (derived from Core).
   # CloudCore introduces lorj predefined CloudProcess used by forj cli.
   #
   #   oCloud = Lorj::CloudCore.new(oConfig, 'myhpcloud')
   #   oConfig.set(:server_name,'myservername')
   #   oCloud.Create(:server)
   #
   # Another basic example (See example directory)
   #
   #   oConfig = Lorj::Account.new()
   #   oPrc = Lorj::Core.new(oConfig, 'mySqlAccount')
   #   oCloud.Create(:student, { :student_name => "Robert Redford"})
   #
   # See BaseProcess to check how you can write a process and what kind of functions
   # are available for your process to be kept controller independant.
   #
   # See BaseController to see how you can write a controller and what kind of functions
   # are available to deal with the implementation API you need to use.
   class Core

      # Public access to a config object.
      # A config object can be any kind of class which should provide at least following functions:
      #
      # - get(*key, default=nil) and [*key]  : function to get a value from a key. default is a value to get if not found.
      # - set(*key, value) or [*key, value]= : function to set a value to a key.
      #   Ex: From processes, you can set a runtime data with:
      #
      #      config.set(key, value)
      #
      #   OR
      #
      #      config[key] = value
      #
      # - exist?(*key)                       : function which return false if not found, or any other value if found.
      #   Ex: From processes, you can get a data (runtime/account/config.yaml or defaults.yaml) with:
      #
      #      config.get(key)
      #
      #   OR
      #
      #      config[key]
      #
      # For each functions, *key is a list of value, which becomes an array in the function.
      # It should accept to manage the key tree (hash of hashes)
      #
      # Currently lorj comes with Lorj::Config or Lorj::Account.
      # Thoses classes defines at least those 5 functions. And more.
      attr_reader :config

      # Core parameters are:
      # oForjConfig : Optional. An instance of a configuration system which *HAVE* to provide get/set/exist?/[]/[]=
      #
      # processClass: Array of string or symbol, or string or symbol. Is the path or name of one or more ProcessClass to use.
      #   This class is dynamically loaded and derived from BaseProcess class.
      #   It loads the Process class content from a file '$CORE_PROCESS_PATH/<sProcessClass>.rb'
      #   If sProcessClass is a file path, this file will be loaded as a ruby include.
      #
      #   <sProcessClass>.rb file name is case sensible and respect RUBY Class name convention
      #
      # sControllerClass: Optional. string or symbol. Is the path or name of ControllerClass to use.
      #   This class is dynamically loaded and derived from BaseController class.
      #   It loads the Controler class content from a file '$PROVIDER_PATH/<sControllerClass>.rb'
      #
      #   The provider can redefine partially or totally some processes
      #   Lorj::Core will load those redefinition from file:
      #   $PROVIDER_PATH/<sControlerClass>Process.rb'
      #
      # <sControllerClass>.rb or <sControllerClass>Process.rb file name is case sensible and respect RUBY Class name convention

      def initialize(oForjConfig = nil, processesClass = nil, sControllerClass = nil)
         # Loading ProcessClass
         # Create Process derived from respectively BaseProcess

         # TODO: Replace Global variables by equivalent to PrcLib.<var>

         PrcLib.core_level = 0 if PrcLib.core_level.nil?

         if oForjConfig.nil?
            @config = Lorj::Config.new()
            oForjConfig = @config
            Lorj.debug(2, "Using an internal Lorj::Config object.")
         else
            @config = oForjConfig
         end


         if processesClass.nil?
            aProcessesClass = []
         elsif not processesClass.is_a?(Array)
            aProcessesClass = [processesClass]
         else
            aProcessesClass = processesClass
         end

         cBaseProcess = BaseProcess
         cProcessClass = nil

         aProcessesClass.each { | sProcessClass |
            Lorj.debug(1, "Loading Process '%s'" % sProcessClass)

            # And load the content from the <sProcessClass>.rb
            if sProcessClass.is_a?(Symbol)
               # Ensure file and processName is capitalized
               sProcessClass = sProcessClass.to_s.capitalize if (/[A-Z]/ =~ sProcessClass.to_s) != 0
               sFile = File.join($CORE_PROCESS_PATH, sProcessClass + '.rb')
            else
               if sProcessClass.include?('/')
                  # Consider a path to the process file. File name is the name of the class.
                  # We accept filename not capitalized.
                  sPath = File.dirname(File.expand_path(sProcessClass))
                  sFile = File.basename(sProcessClass)
                  file = File.basename(sProcessClass)
                  file['.rb'] = '' if file['.rb']
                  sProcessClass = file
                  sProcessClass = sProcessClass.capitalize if (/[A-Z]/ =~ sProcessClass) != 0
                  mFound = sProcessClass.scan(/_[a-z]/)
                  if mFound
                     mFound.each { | str |
                        sProcessClass[str] = str[1].capitalize
                     }
                  end
               else
                  sPath = $CORE_PROCESS_PATH
                  sProcessClass = sProcessClass.capitalize if (/[A-Z]/ =~ sProcessClass) != 0
                  sFile = sProcessClass + '.rb'
               end
               # Ensure process name is capitalized
               sFile = File.join(sPath, sFile)
            end
            if File.exists?(sFile)
               cNewClass = Class.new(cBaseProcess)
               sProcessClass = "%sProcess" %  sProcessClass if not /Process$/ =~ sProcessClass
               Lorj.debug(1, "Declaring Process '%s'" % sProcessClass)
               cBaseProcess = Object.const_set(sProcessClass, cNewClass)
               cProcessClass = sProcessClass
               BaseDefinition.current_process(cBaseProcess)
               load sFile
            else
               PrcLib.warning("Process file definition '%s' is missing. " % sFile)
            end
         }

         if sControllerClass
            Lorj.debug(1, "Loading Controller/definition '%s'" % sControllerClass)
            # Add Provider Object -------------
            if sControllerClass.is_a?(Symbol)
               sPath = File.join($PROVIDERS_PATH, sControllerClass.to_s)
               sControllerClass = sControllerClass.to_s.capitalize if (/[A-Z]/ =~ sControllerClass.to_s) != 0
               sFile = sControllerClass.to_s + '.rb'
            else
               if sControllerClass.include?('/')
                  # Consider a path to the process file. File name is the name of the class.
                  sPath = File.dirname(File.expand_path(sControllerClass))
                  sFile = File.basename(sControllerClass)
                  file = File.basename(sControllerClass)
                  file = file.capitalize if (/[A-Z]/ =~ file) != 0
                  file['.rb'] = '' if file['.rb']
                  sControllerClass = file
                  sControllerClass = sControllerClass.capitalize if (/[A-Z]/ =~ sControllerClass) != 0
                  mFound = sControllerClass.scan(/_[a-z]/)
                  if mFound
                     mFound.each { | str |
                        sControllerClass[str] = str[1].capitalize
                     }
                  end
               else
                  sPath = File.join($PROVIDERS_PATH, sControllerClass)
                  sControllerClass = sControllerClass.capitalize if (/[A-Z]/ =~ sControllerClass) != 0
                  sFile = sControllerClass + '.rb'
               end
            end
            sFile = File.join(sPath, sFile)

            # Initialize an empty class derived from BaseDefinition.
            # This to ensure provider Class will be derived from this Base Class
            # If this class is derived from a different Class, ruby will raise an error.

            # Create Definition and Controler derived from respectively BaseDefinition and BaseControler
            cBaseDefinition = Class.new(BaseDefinition)
            # Finally, name that class!
            Lorj.debug(2, "Declaring Definition '%s'" % sControllerClass)
            Object.const_set sControllerClass, cBaseDefinition

            cBaseControler = Class.new(BaseController)
            Lorj.debug(2, "Declaring Controller '%s'" % [sControllerClass + 'Controller'])
            Object.const_set sControllerClass + 'Controller', cBaseControler

            # Loading Provider base file. This file should load a class
            # which have the same name as the file.
            if File.exists?(sFile)
               load sFile
            else
               raise Lorj::PrcError.new(), "Provider file definition '%s' is missing. Cannot go on" % sFile
            end

            # Identify Provider Classes. Search for
            # - Definition Class (sControllerClass) - Contains ForjClass Object
            # - Controller Class (sControllerClass + 'Controller') - Provider Cloud controler object

            # Search for Definition Class
            begin
               # Get it from Objects
               oDefClass = Object.const_get(sControllerClass)
            rescue
               raise Lorj::PrcError.new(), 'Lorj::Core: Unable to find class "%s"' % sControllerClass
            end

            # Search for Controler Class
            # - Process Class (sControllerClass + 'Process') - Provider Process object if defined
            begin
               # Get the same one suffixed with 'Provider' from Objects
               oCoreObjectControllerClass = Object.const_get(sControllerClass + 'Controller')
            rescue
               raise Lorj::PrcError.new(), 'Lorj::Core: Unable to find class "%s"' % sControllerClass + 'Controller'
            end

            # Then, we create an BaseCloud Object with 2 objects joined:
            # ForjAccount and a BaseControler Object type


         else
            oCoreObjectControllerClass = nil
            oDefClass = BaseDefinition
         end

         # Add Process management object ---------------
         unless cProcessClass.nil?
            begin
               oBaseProcessDefClass = Object.const_get(cProcessClass)
            rescue
               raise Lorj::PrcError.new(), 'Lorj::Core: Unable to find class "%s"' % cProcessClass
            end
         else
            raise Lorj::PrcError.new(), 'Lorj::Core: No valid process loaded. Aborting.'
         end
         # Ex: Hpcloud(ForjAccount, HpcloudProvider)
         if oCoreObjectControllerClass
            @oCoreObject = oDefClass.new(oForjConfig, oBaseProcessDefClass.new(), oCoreObjectControllerClass.new())
         else
            @oCoreObject = oDefClass.new(oForjConfig, oBaseProcessDefClass.new())
         end

      end

      # a wrapper to Create call. Use this function for code readibility.
      #
      # * *Args* :
      #   - +oCloudObj+ : Name of the object to initialize.
      #   - +hConfig+   : Hash of hashes containing data required to initialize the object.
      #     If you use this variable, any other runtime config defined
      #     by the Data model will be cleaned before
      #
      # * *Returns* :
      #   - +Lorj::Data+ : Represents the Object initialized.
      #
      # * *Raises* :
      #   No exceptions

      def Connect(oCloudObj, hConfig = {})
         return nil if not oCloudObj or not @oCoreObject
         @oCoreObject.Create(oCloudObj, hConfig)
      end

      # Execute the creation process to create the object `oCloudObj`.
      # The creation process can add any kind of complexity to
      # get the a memory representation of the object manipulated during creation process.
      # This means that a creation process can be (non exhaustive list of possibilities)
      # - a connection initialization
      # - an internal memory data structure, like hash, array, ruby object...
      # - a get or create logic
      # - ...
      #
      # * *Args* :
      #   - +oCloudObj+ : Name of the object to initialize.
      #   - +hConfig+   : Hash of hashes containing data required to initialize the object.
      #     If you use this variable, any other runtime config defined
      #     by the Data model will be cleaned before
      #
      # * *Returns* :
      #   - +Lorj::Data+ : Represents the Object initialized.
      #
      # * *Raises* :
      #   No exceptions
      def Create(oCloudObj, hConfig = {})
         return nil if not oCloudObj or not @oCoreObject
         @oCoreObject.Create(oCloudObj, hConfig)
      end

      # a wrapper to Create call. Use this function for code readibility.
      #
      # * *Args* :
      #   - +oCloudObj+ : Name of the object to initialize.
      #   - +hConfig+   : Hash of hashes containing data required to initialize the object.
      #     If you use this variable, any other runtime config defined
      #     by the Data model will be cleaned before
      #
      # * *Returns* :
      #   - +Lorj::Data+ : Represents the Object initialized.
      #
      # * *Raises* :
      #   No exceptions

      def GetOrCreate(oCloudObj, hConfig = {})
         return nil if not oCloudObj or not @oCoreObject
         @oCoreObject.Create(oCloudObj, hConfig)
      end

      # Execution of the delete process for the `oCloudObj` object.
      # It requires the object to be loaded in lorj Lorj::Data objects cache.
      # You can use `Create` or `Get` functions to load this object.
      #
      # * *Args* :
      #   - +oCloudObj+ : Name of the object to initialize.
      #   - +hConfig+   : Hash of hashes containing data required to initialize the object.
      #     If you use this variable, any other runtime config defined
      #     by the Data model will be cleaned before
      #
      # * *Returns* :
      #   - +Lorj::Data+ : Represents the Object initialized.
      #
      # * *Raises* :
      #   No exceptions

      def Delete(oCloudObj, hConfig = {})
         return nil if not oCloudObj or not @oCoreObject

         @oCoreObject.Delete(oCloudObj, hConfig)
      end

      # Execution of the Query process for the `oCloudObj` object.
      #
      # * *Args* :
      #   - +oCloudObj+ : Name of the object to initialize.
      #   - +sQuery+    : Hash representing the query filter.
      #   - +hConfig+   : Hash of hashes containing data required to initialize the object.
      #     If you use this variable, any other runtime config defined
      #     by the Data model will be cleaned before
      #
      # * *Returns* :
      #   - +Lorj::Data+ : Represents the Object initialized.
      #
      # * *Raises* :
      #   No exceptions

      def Query(oCloudObj, sQuery, hConfig = {})
         return nil if not oCloudObj or not @oCoreObject

         @oCoreObject.Query(oCloudObj, sQuery, hConfig)
      end

      # Execution of the Get process for the `oCloudObj` object.
      #
      # * *Args* :
      #   - +oCloudObj+ : Name of the object to initialize.
      #   - +sId+       : data representing the ID (attribute :id) of a Lorj::Data object.
      #   - +hConfig+   : Hash of hashes containing data required to initialize the object.
      #     If you use this variable, any other runtime config defined
      #     by the Data model will be cleaned before
      #
      # * *Returns* :
      #   - +Lorj::Data+ : Represents the Object initialized.
      #
      # * *Raises* :
      #   No exceptions

      def Get(oCloudObj, sId, hConfig = {})
         return nil if not oCloudObj or not @oCoreObject or sId.nil?

         @oCoreObject.Get(oCloudObj, sId, hConfig)
      end

      # Execution of the Update process for the `oCloudObj` object.
      # Usually, the Controller object data is updated by the process (BaseController::set_attr)
      # then it should call a controller_update to really update the data in the controller.
      #
      # * *Args* :
      #   - +oCloudObj+ : Name of the object to initialize.
      #   - +sId+       : data representing the ID (attribute :id) of a Lorj::Data object.
      #   - +hConfig+   : Hash of hashes containing data required to initialize the object.
      #     If you use this variable, any other runtime config defined
      #     by the Data model will be cleaned before
      #
      # * *Returns* :
      #   - +Lorj::Data+ : Represents the Object initialized.
      #
      # * *Raises* :
      #   No exceptions

      def Update(oCloudObj, hConfig = {})
         return nil if not oCloudObj or not @oCoreObject

         @oCoreObject.Update(oCloudObj, hConfig)
      end

      # Function used to ask users about setting up his account.
      #
      # * *Args* :
      #   - +oCloudObj+    : Name of the object to initialize.
      #   - +sAccountName+ : Account file name. If not set, Config[:account_name] is used.
      #     If you use this variable, any other runtime config defined
      #     by the Data model will be cleaned before
      #
      # * *Returns* :
      #   - +Lorj::Data+ : Represents the Object initialized.
      #
      # * *Raises* :
      #   No exceptions

      def Setup(oCloudObj, sAccountName = nil)
         return nil if not oCloudObj or not @oCoreObject
         @oCoreObject.Setup(oCloudObj, sAccountName)
      end
   end

   # This class based on generic Core, defines a Cloud Process to use.
   class CloudCore < Core
      def initialize(oConfig, sAccount = nil, aProcesses = [])

         unless oConfig.is_a?(ForjAccount)
            oForjAccount = Lorj::Account.new(oConfig)
            unless sAccount.nil?
               oForjAccount.ac_load(sAccount)
            end
         else
            oForjAccount = oConfig
         end
         aProcessList = [:CloudProcess]

         sControllerMod = oForjAccount.get(:provider_name)
         raise Lorj::PrcError.new(), "Provider_name not set. Unable to create instance CloudCore." if sControllerMod.nil?

         sControllerProcessMod = File.join($PROVIDERS_PATH, sControllerMod, sControllerMod.capitalize + "Process.rb")
         if File.exist?(sControllerProcessMod)
            aProcessList << sControllerProcessMod
         else
            Lorj.debug(1, "No Provider process defined. File '%s' not found." % sControllerProcessMod)
         end

         super(oForjAccount, aProcessList.concat(aProcesses), sControllerMod)
      end
   end


   # class describing generic Object Process
   # Ex: How to get a Network Object (ie: get a network or create it if missing)
   class BaseProcess
      def initialize()
         @oDefinition = nil
      end

      def set_BaseObject(oDefinition)
         @oDefinition = oDefinition
      end

      def controller_create(sObjectType, hParams = {})
         raise Lorj::PrcError.new(), "No Controler object loaded." if not @oDefinition
         @oDefinition.create(sObjectType)
      end

      def controller_query(sObjectType, sQuery, hParams = {})
         raise Lorj::PrcError.new(), "No Controler object loaded." if not @oDefinition
         @oDefinition.query(sObjectType, sQuery)
      end

      def controller_update(sObjectType, hParams = {})
         raise Lorj::PrcError.new(), "No Controler object loaded." if not @oDefinition
         @oDefinition.update(sObjectType)
      end

      def controller_delete(sObjectType, hParams = {})
         raise Lorj::PrcError.new(), "No Controler object loaded." if not @oDefinition
         @oDefinition.delete(sObjectType)
      end

      def controller_get(sObjectType, sId, hParams = {})
         raise Lorj::PrcError.new(), "No Controler object loaded." if not @oDefinition
         @oDefinition.get(sObjectType, sId)
      end

      def Create(sObjectType)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.Create(sObjectType)
      end

      def Query(sObjectType, sQuery)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.Query(sObjectType, sQuery)
      end

      def Update(sObjectType)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.Update(sObjectType)
      end

      def Get(sObjectType, sId)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.Get(sObjectType, sId)
      end

      def Delete(sObjectType)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.Delete(sObjectType)
      end

      private

      def query_cache_cleanup(sObjectType)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.query_cleanup(sObjectType)
      end

      def object_cache_cleanup(sObjectType)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.object_cleanup(sObjectType)
      end



      def controler
         PrcLib::warning("controler object call is obsolete. Please update your code. Use controller_<action> instead.\n%s" % caller)
         raise Lorj::PrcError.new(), "No Controler object loaded." if not @oDefinition
         @oDefinition
      end

      def object
         PrcLib::warning("object call is obsolete. Please update your code. Use <Action> instead.\n%s" % caller)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition
      end

      def format_object(sObjectType, oMiscObj)

         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.format_object(sObjectType, oMiscObj)
      end

      def format_query(sObjectType, oMiscObj, hQuery)

         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.format_list(sObjectType, oMiscObj, hQuery)
      end

      def DataObjects(sObjectType, *key)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.DataObjects(sObjectType, *key)
      end

      def get_data(oObj, *key)
         PrcLib::warning("get_data call is obsolete. Please update your code. Use [] instead.\n%s" % caller)
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.get_data(oObj, :attrs, key)
      end

      def register(oObject, sObjectType = nil)

         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.register(oObject, sObjectType)
      end

      def config
         raise Lorj::PrcError.new(), "No Base object loaded." if not @oDefinition
         @oDefinition.config
      end

      def query_single(sCloudObj, oList, sQuery, name, sInfoMsg = {})
         oList = controler.query(sCloudObj, sQuery)
         sInfo = {
            :notfound   => "No %s '%s' found",
            :checkmatch => "Found 1 %s. checking exact match for '%s'.",
            :nomatch    => "No %s '%s' match",
            :found      => "Found %s '%s'.",
            :more       => "Found several %s. Searching for '%s'.",
            :items_form => "%s",
            :items      => [:name]
         }
         sInfo[:notfound]     = sInfoMsg[:notfound]   if sInfoMsg.key?(:notfound)
         sInfo[:checkmatch]   = sInfoMsg[:checkmatch] if sInfoMsg.key?(:checkmatch)
         sInfo[:nomatch]      = sInfoMsg[:nomatch]    if sInfoMsg.key?(:nomatch)
         sInfo[:found]        = sInfoMsg[:found]      if sInfoMsg.key?(:found)
         sInfo[:more]         = sInfoMsg[:more]       if sInfoMsg.key?(:more)
         sInfo[:items]        = sInfoMsg[:items]      if sInfoMsg.key?(:items)
         sInfo[:items_form]   = sInfoMsg[:items_form] if sInfoMsg.key?(:items_form)
         case oList.length()
            when 0
               PrcLib.info( sInfo[:notfound] % [sCloudObj, name] )
               oList
            when 1
               Lorj.debug(2, sInfo[:checkmatch] % [sCloudObj, name])
               element = nil
               oList.each { | oElem |
                  bFound = true
                  sQuery.each { | key, value |
                     if oElem[key] != value
                        bFound = false
                        break
                     end
                  }
                  :remove if not bFound
               }
               if oList.length == 0
                  PrcLib.info(sInfo[:nomatch] % [sCloudObj, name])
               else
                  sItems = []
                  if sInfo[:items].is_a?(Array)
                     sInfo[:items].each { | key |
                        sItems << oList[0, key]
                     }
                  else
                     sItems << oList[0, sInfo[:items]]
                  end
                  sItem = sInfo[:items_form] % sItems
                  PrcLib.info(sInfo[:found] % [sCloudObj, sItem])
               end
               oList
            else
               Lorj.debug(2, sInfo[:more] % [sCloudObj, name])
               # Looping to find the one corresponding
               element = nil
               oList.each { | oElem |
                  bFound = true
                  sQuery.each { | key, value |
                     if oElem[key] != value
                        bFound = false
                        break
                     end
                  }
                  :remove if not bFound
               }
               if oList.length == 0
                  PrcLib.info(sInfo[:notfound] % [sCloudObj, name])
               else
                  sItems = []
                  if sInfo[:items].is_a?(Array)
                     sInfo[:items].each { | key |
                        sItems << oList[0, key]
                     }
                  else
                     sItems << oList[0, sInfo[:items]]
                  end
                  sItem = sInfo[:items_form] % sItems
                  PrcLib.info(sInfo[:found] % [sCloudObj, sItem])
               end
               oList
         end
      end

   end


   class BaseController
      # Default handlers which needs to be defined by the cloud controller,
      # called by BaseDefinition Create, Delete, Get, Query and Update functions.
      def connect(sObjectType, hParams)
         raise Lorj::PrcError.new(), "connect has not been redefined by the controller '%s'" % self.class
      end

      def create(sObjectType, hParams)
         raise Lorj::PrcError.new(), "create_object has not been redefined by the controller '%s'" % self.class
      end

      def delete(sObjectType, hParams)
         raise Lorj::PrcError.new(), "delete_object has not been redefined by the controller '%s'" % self.class
      end

      def get(sObjectType, sUniqId, hParams)
         raise Lorj::PrcError.new(), "get_object has not been redefined by the controller '%s'" % self.class
      end

      def query(sObjectType, sQuery, hParams)
         raise Lorj::PrcError.new(), "query_object has not been redefined by the controller '%s'" % self.class
      end

      def update(sObjectType, oObject, hParams)
         raise Lorj::PrcError.new(), "update_object has not been redefined by the controller '%s'" % self.class
      end

      def Error(msg)
         raise Lorj::PrcError.new(), "%s: %s" % [self.class, msg]
      end

      def required?(oParams, *key)
         raise Lorj::PrcError.new(), "%s: %s is not set." % [self.class, key] if not oParams.exist?(key)
      end
   end

   # Represents a list of key/value pairs
   # if the value is a Lorj::Data(data or list), the key will be the Lorj::Data type.
   #
   #
   #
   # Used by
   # - BaseDefinition to get a Lorj::Data cache.
   # - Process create/query/update/delete/get to build the hParams
   #   The object behavior is adapted to the process usage
   #   By default for Lorj::Data(:object), hParams[aKey] will get or set object attributes
   #
   # - Controller create/query/update/delete/get to build the hParams
   #   The object behavior is adapted to the controller usage
   #   By default for Lorj::Data(:object), hParams[aKey] will get or set controller object
   #
   class ObjectData
      # Intialize the object. By default, usage is for controller context.
      #
      # * *Args* :
      #   - +bInternal+    : Context
      #     - true if process context
      #     - false if controller context. This is the default value.
      #
      # * *Returns* :
      #   - nothing
      #
      # * *Raises* :
      #   No exceptions
      def initialize(bInternal = false)

         @hParams = {}
         @hParams[:hdata] = {} unless bInternal
         @bInternal = bInternal
      end

      # Get function
      #
      # key can be an array, a string (converted to a symbol) or a symbol.
      #
      # * *Args*    :
      #   - +key+   : key tree (list of keys)
      #     If key[1] == :attrs, get will forcelly use the Lorj::Data object attributes
      #     If key[1] == :ObjectData, get will forcelly return the controller object
      #     otherwise, get will depends on the context:
      #     - controller context: will return the controller object
      #     - Process context: will return the Lorj::Data object attributes
      # * *Returns* :
      #   value found or nil.
      # * *Raises* :
      #   nothing
      def [] (*key)

         key = key.flatten
         # Return ObjectData Element if asked. Ignore additional keys.
         return @hParams[key[0]] if key[1] == :ObjectData

         return @hParams if key.length == 0

         oObject = Lorj::rhGet(@hParams, key[0])
         return nil if oObject.nil?

         # Return attributes if asked
         return oObject[:attrs,  key[2..-1]] if key[1] == :attrs

         if oObject.is_a?(Lorj::Data)
            if @bInternal
               # params are retrieved in process context
               # By default, if key is detected as a framework object, return its data.
               return oObject[:attrs,  key[1..-1]]
            else
               # params are retrieved in controller context
               # By default, if key is detected as a controller object, return its data.
               return oObject[:object,  key[1..-1]]
            end
         end

         # otherwise, simply return what is found in keys hierarchy.
         Lorj::rhGet(@hParams, key)
      end

      # Functions used to set simple data/Object for controller/process function call.
      # TODO: to revisit this function, as we may consider simple data, as Lorj::Data object
      def []= (*key, value)
         return nil if [:object, :query].include?(key[0])
         Lorj::rhSet(@hParams, value, key)
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
         raise Lorj::PrcError.new, "Invalid Framework object type '%s'." % oDataObject.class unless oDataObject.is_a?(Lorj::Data)

         sObjectType = oDataObject.object_type?

         if oDataObject.type? == :list
            oOldDataObject = Lorj::rhGet(@hParams, :query, sObjectType)
            oOldDataObject.unregister if oOldDataObject
            Lorj::rhSet(@hParams, oDataObject, :query, sObjectType)
         else
            oOldDataObject = Lorj::rhGet(@hParams, sObjectType)
            oOldDataObject.unregister if oOldDataObject
            @hParams[sObjectType] = oDataObject
         end
         oDataObject.register
      end

      # delete function. delete a Lorj::Data (data or list) from the ObjectData list.
      #
      # key can be an array, a string (converted to a symbol) or a symbol.
      #
      # * *Args*    :
      #   - +oDataObject+ : Lorj::Data object
      # * *Returns* :
      #   Nothing
      # * *Raises* :
      #   nothing
      def delete(oObj)
         if oObj.is_a?(Symbol)
            sObjectType = oObj
            oObj = @hParams[sObjectType]
            @hParams[sObjectType] = nil
         else
            raise Lorj::PrcError.new(), "ObjectData: delete error. oObj is not a framework data Object. Is a '%s'" % oObj.class unless oObj.is_a?(Lorj::Data)
            if oObj.type? == :list
               Lorj::rhSet(@hParams, nil, :query, oObj.object_type?)
            else
               sObjectType = oObj.object_type?
               @hParams[sObjectType] = nil
            end
         end
         oObj.unregister unless oObj.nil?
      end

      # Merge 2 ObjectData.
      #
      # * *Args*    :
      #   - +hHash+ : Hash of Lorj::Data. But it is possible to have different object type (not Lorj::Data)
      # * *Returns* :
      #   hash merged
      # * *Raises* :
      #   nothing
      def << (hHash)
         @hParams.merge!(hHash)
      end

      # check Lorj::Data attributes or object exists. Or check key/value pair existence.
      #
      # * *Args*    :
      #   - +hHash+ : Hash of Lorj::Data. But it is possible to have different object type (not Lorj::Data)
      # * *Returns* :
      #   true/false
      # * *Raises* :
      #   PrcError
      def exist?(*key)
         raise Lorj::PrcError.new, "ObjectData: key is not list of values (string/symbol or array)" if not [Array, String, Symbol].include?(key.class)

         key = [key] if key.is_a?(Symbol) or key.is_a?(String)

         key = key.flatten

         oObject = Lorj::rhGet(@hParams, key[0])
         return false if oObject.nil?

         if oObject.is_a?(Lorj::Data)
            # Return true if ObjectData Element is found when asked.
            return true if key[1] == :ObjectData and oObject.type?(key[0]) == :object

            # Return true if attritutes or controller object attributes found when asked.
            return oObject.exist?(key[2..-1]) if key[1] == :attrs
            return oObject.exist?(key[1..-1]) if key.length > 1
            true
         else
            # By default true if found key hierarchy
            (Lorj::rhExist?(@hParams, key) == key.length)
         end
      end

      # Determine the type of object identified by a key. Lorj::Data attributes or object exists. Or check key/value pair existence.
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
         return nil if Lorj::rhExist?(@hParams, key) != 1
         :data
         :DataObject if @hParams[key].type?() == :object
      end

      def cObj(*key)
         Lorj::rhGet(@hParams, key, :object) if Lorj::rhExist?(@hParams, key, :object) == 2
      end

   end

   # Following class defines class levels function to
   # declare framework objects.
   # As each process needs to define new object to deal with
   # require that process to define it with definition functions
   # See definition.rb for functions to use.

   class BaseDefinition
      # Capitalized function are called to start a process. It is done by Core.

      # BaseCloud Object available functions.
      def Create(sObjectType, hConfig = {})

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sObjectType, :create_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               PrcLib::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sObjectType, sObjectType])
            end
         end

         return nil if not sObjectType
         raise Lorj::PrcError.new(), "%s.Create: '%s' is not a known object type." % [self.class, sObjectType] if Lorj::rhExist?(@@meta_obj, sObjectType) != 1

         pProc = Lorj::rhGet(@@meta_obj, sObjectType, :lambdas, :create_e)

         # Check required parameters
         oObjMissing = _check_required(sObjectType, :create_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop

            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sObjectType, :create_e, pProc).reverse

            raise Lorj::PrcError.new(), "loop detection: '%s' is required but Create(%s) did not loaded it." % [sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sObjectType # Context: Default object used.

         if pProc.nil?
            # This object is a meta object, without any data.
            # Used to build other kind of objects.
            oObject = Lorj::Data.new
            oObject.set({}, sObjectType) {}
         else
            # build Function params to pass to the event handler.
            aParams = _get_object_params(sObjectType, :create_e, pProc,)
            Lorj.debug(2, "Create Object '%s' - Running '%s'" % [sObjectType, pProc])

            # Call the process function.
            # At some point, the process will call the controller, via the framework.
            # This controller call via the framework has the role to
            # create an ObjectData well formatted, with _return_map function
            # See Definition.connect/create/update/query/get functions (lowercase)
            oObject = @oForjProcess.method(pProc).call(sObjectType, aParams)
            # return usually is the main object that the process called should provide.
            # Save Object if the object has been created by the process, without controller
         end

         unless oObject.nil?
            query_cleanup(sObjectType)
            @ObjectData.add(oObject)
         else
            PrcLib::warning("'%s' has returned no data for object Lorj::Data '%s'!" % [pProc, sObjectType])
         end
      end

      def Delete(sCloudObj, hConfig = {})
         return nil if not sCloudObj

         raise Lorj::PrcError.new(), "%s.Delete: '%s' is not a known object type." % [self.class, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sCloudObj, :delete_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               PrcLib::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sCloudObj, sCloudObj])
            end
         end

         pProc = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas, :delete_e)

         return nil if pProc.nil?

         # Check required parameters
         oObjMissing = _check_required(sCloudObj, :delete_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop
            if sElem == sCloudObj
               debug(2, "'%s' object is not previously loaded or created." % sCloudObj) if sElem == sCloudObj
               next
            end
            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sCloudObj, :delete_e, pProc).reverse
            raise Lorj::PrcError.new(), "Unable to delete '%s' object. required '%s' data was not loaded after 'Create(%s)'. Check create handler for object type '%s'." % [sCloudObj, sElem, sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sCloudObj # Context: Default object used.

         # build Function params to pass to the event handler.
         aParams = _get_object_params(sCloudObj, :delete_e, pProc)

         bState = @oForjProcess.method(pProc).call(sCloudObj, aParams)
         # return usually is the main object that the process called should provide.
         if bState
            @ObjectData.delete(sCloudObj)
         end

      end

      def query_cleanup(sCloudObj)
         oList = @ObjectData[:query, sCloudObj]
         unless oList.nil?
            @ObjectData.delete(oList)
            Lorj.debug(2, "Query cache for object '%s' cleaned." % sCloudObj)
         end
      end

      def object_cleanup(sCloudObj)
         oObject = @ObjectData[sCloudObj, :ObjectData]
         unless oObject.nil?
            @ObjectData.delete(oObject)
         end
      end

      # This function returns a list of objects
      def Query(sCloudObj, hQuery, hConfig = {})

         return nil if not sCloudObj

         raise Lorj::PrcError.new(), "$s.Get: '%s' is not a known object type." % [self.class, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sCloudObj, :query_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               PrcLib::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sCloudObj, sCloudObj])
            end
         end

         # Check if we can re-use a previous query
         oList = @ObjectData[:query, sCloudObj]
         unless oList.nil?
            if oList[:query] == hQuery
               Lorj.debug(3, "Using Object '%s' query cache : %s" % [sCloudObj, hQuery])
               return oList
            end
         end

         pProc = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas, :query_e)

         return nil if pProc.nil?

         # Check required parameters
         oObjMissing = _check_required(sCloudObj, :query_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop
            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sCloudObj, :query_e, pProc).reverse
            raise Lorj::PrcError.new(), "loop detection: '%s' is required but Query(%s) did not loaded it." % [sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sCloudObj # Context: Default object used.

         # build Function params to pass to the Process Event handler.
         aParams = _get_object_params(sCloudObj, :query_e, pProc)

         # Call the process function.
         # At some point, the process will call the controller, via the framework.
         # This controller call via the framework has the role to
         # create an ObjectData well formatted, with _return_map function
         # See Definition.connect/create/update/query/get functions (lowercase)
         oObject = @oForjProcess.method(pProc).call(sCloudObj, hQuery, aParams)
         # return usually is the main object that the process called should provide.
         unless oObject.nil?
            # Save Object if the object has been created by the process, without controller
            @ObjectData.add(oObject)
         else
            PrcLib::warning("'%s' returned no collection of objects Lorj::Data for '%s'" % [pProc, sCloudObj])
         end
      end

      def Get(sCloudObj, sUniqId, hConfig = {})

         return nil if not sCloudObj

         raise Lorj::PrcError.new(), "$s.Get: '%s' is not a known object type." % [self.class, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sCloudObj, :get_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               Lorj::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sCloudObj, sCloudObj])
            end
         end

         pProc = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas, :get_e)

         return nil if pProc.nil?

         # Check required parameters
         oObjMissing = _check_required(sCloudObj, :get_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop
            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sCloudObj, :get_e, pProc).reverse
            raise Lorj::PrcError.new(), "loop detection: '%s' is required but Get(%s) did not loaded it." % [sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sCloudObj # Context: Default object used.

         # build Function params to pass to the Process Event handler.
         aParams = _get_object_params(sCloudObj, :get_e, pProc)

         # Call the process function.
         # At some point, the process will call the controller, via the framework.
         # This controller call via the framework has the role to
         # create an ObjectData well formatted, with _return_map function
         # See Definition.connect/create/update/query/get functions (lowercase)
         oObject = @oForjProcess.method(pProc).call(sCloudObj, sUniqId, aParams)
         # return usually is the main object that the process called should provide.
         unless oObject.nil?
            # Save Object if the object has been created by the process, without controller
            @ObjectData.add(oObject)
         end
      end

      def Update(sCloudObj, hConfig = {})

         return nil if not sCloudObj

         raise Lorj::PrcError.new(), "$s.Update: '%s' is not a known object type." % [self.class, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sCloudObj, :update_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               PrcLib::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sCloudObj, sCloudObj])
            end
         end

         pProc = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas, :update_e)

         return nil if pProc.nil?

         # Check required parameters
         oObjMissing = _check_required(sCloudObj, :update_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop
            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sCloudObj, :update_e, pProc).reverse
            raise Lorj::PrcError.new(), "loop detection: '%s' is required but Update(%s) did not loaded it." % [sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sCloudObj # Context: Default object used.

         # build Function params to pass to the event handler.
         aParams = _get_object_params(sCloudObj, :update_e, pProc)

         oObject = @oForjProcess.method(pProc).call(sCloudObj, aParams)
         # return usually is the main object that the process called should provide.
         unless oObject.nil?
            # Save Object if the object has been created by the process, without controller
            @ObjectData.add(oObject)
         end
      end

      def Setup(sObjectType, sAccountName)
         # Loop in dependencies to get list of data object to setup
         raise Lorj::PrcError,new(), "Setup: '%s' not a valid object type." if Lorj::rhExist?(@@meta_obj, sObjectType) != 1

         hAskStep = Lorj::Default.get(:ask_step, :setup)
         aSetup = []
         hAskStep.each{ | value |
            aSetup << {
               :desc => value[:desc],
               :explanation => value[:explanation],
               :pre_step_handler => value[:pre_step_function],
               :order => [[]],
               :post_step_handler => value[:post_step_function]
            }

         }
         oInspectedObjects = []
         oInspectObj = [sObjectType]

         @oForjConfig.ac_load(sAccountName) if sAccountName

         Lorj.debug(2, "Setup is identifying account data to ask for '%s'" % sObjectType)
         while oInspectObj.length() >0
            # Identify data to ask
            # A data to ask is a data needs from an object type
            # which is declared in section of defaults.yaml
            # and is declared :account to true (in defaults.yaml or in process declaration - define_data)

            sObjectType = oInspectObj.pop
            sAsk_step = 0
            Lorj.debug(1, "Checking '%s'" % sObjectType)
            hTopParams = Lorj::rhGet(@@meta_obj,sObjectType, :params)
            if hTopParams[:keys].nil?
               Lorj.debug(1, "Warning! Object '%s' has no data/object needs. Check the process" % sObjectType)
               next
            end
            hTopParams[:keys].each { |sKeypath, hParams|
               oKeyPath = KeyPath.new(sKeypath)
               sKey = oKeyPath.sKey
               case hParams[:type]
                  when :data
                     hMeta = _get_meta_data(sKey)
                     next if hMeta.nil?
                     sAsk_step = hMeta[:ask_step] if Lorj::rhExist?(hMeta, :ask_step) == 1 and hMeta[:ask_step].is_a?(Fixnum)
                     Lorj.debug(3, "#{sKey} is part of setup step #{sAsk_step}")
                     aOrder = aSetup[sAsk_step][:order]

                     if oInspectedObjects.include?(sKey)
                        Lorj.debug(2, "#{sKey} is already asked. Ignored.")
                        next
                     end
                     if hMeta[:account].is_a?(TrueClass)
                        if not hMeta[:depends_on].is_a?(Array)
                           PrcLib.warning("'%s' depends_on definition have to be an array." % oKeyPath.sFullPath) unless hMeta[:depends_on].nil?
                           iLevel = 0
                           bFound = true
                        else
                           # Searching highest level from dependencies.
                           bFound = false
                           iLevel = 0
                           hMeta[:depends_on].each { |depend_key|
                              aOrder.each_index { |iCurLevel|
                                 if aOrder[iCurLevel].include?(depend_key)
                                    bFound = true
                                    iLevel = [iLevel, iCurLevel + 1].max
                                 end
                              }
                                 aOrder[iLevel] = [] if aOrder[iLevel].nil?
                           }
                        end
                        if bFound
                           if not aOrder[iLevel].include?(sKey)
                              if hMeta[:ask_sort].is_a?(Fixnum)
                                 iOrder = hMeta[:ask_sort]
                                 if aOrder[iLevel][iOrder].nil?
                                    aOrder[iLevel][iOrder] = sKey
                                 else
                                    aOrder[iLevel].insert(iOrder, sKey)
                                 end
                                 Lorj.debug(3, "S%s/L%s/O%s: '%s' added in setup list. " % [sAsk_step, iLevel, iOrder, sKey])
                              else
                                 aOrder[iLevel] << sKey
                                 Lorj.debug(3, "S%s/L%s/Last: '%s' added in setup list." % [sAsk_step, iLevel, sKey])
                              end
                           end
                        end
                        oInspectedObjects << sKey
                     else
                        Lorj.debug(2, "#{sKey} used by #{sObjectType} won't be asked during setup. :account = true not set.")
                     end
                  when :CloudObject
                     oInspectObj << sKey if not oInspectObj.include?(sKey) and not oInspectedObjects.include?(sKey)
               end
            }
            oInspectedObjects << sObjectType
         end
         Lorj.debug(2, "Setup check if needs to add unrelated data in the process")
         hAskStep.each_index{ | iStep |
            value = hAskStep[iStep]
            if Lorj::rhExist?(value, :add) == 1
               sKeysToAdd = Lorj::rhGet(value, :add)
               sKeysToAdd.each { | sKeyToAdd |
                  bFound = false
                  aSetup[iStep][:order].each_index { | iOrder |
                     sKeysToAsk = aSetup[iStep][:order][iOrder]
                     unless sKeysToAsk.index(sKeyToAdd).nil?
                        bFound = true
                        break
                     end
                  }
                  next if bFound
                  iLevel = 0
                  iOrder = aSetup[iStep][:order].length
                  iAtStep = iStep
                  hMeta = _get_meta_data(sKeyToAdd)
                  if Lorj::rhExist?(hMeta, :after) == 1
                     sAfterKeys = hMeta[:after]
                     sAfterKeys = [ sAfterKeys ] if not sAfterKeys.is_a?(Array)
                     sAfterKeys.each{ |sAfterKey |
                        bFound = false
                        aSetup.each_index { |iStepToCheck|
                           aSetup[iStepToCheck][:order].each_index { | iLevelToCheck |
                              sKeysToAsk = aSetup[iStepToCheck][:order][iLevelToCheck]
                              iOrderToCheck = sKeysToAsk.index(sAfterKey)
                              unless iOrderToCheck.nil?
                                 iAtStep = iStepToCheck if iStepToCheck > iAtStep
                                 iLevel = iLevelToCheck if iLevelToCheck > iLevel
                                 iOrder = iOrderToCheck + 1 if iOrderToCheck + 1 > iOrder
                                 bFound = true
                                 break
                              end
                           }
                        }
                     }
                  end
                  aSetup[iAtStep][:order][iLevel].insert(iOrder, sKeyToAdd)
                  Lorj.debug(3, "S%s/L%s/O%s: '%s' added in setup list at  position." % [iAtStep, iLevel, iOrder, sKeyToAdd])
               }
            end
         }

         Lorj.debug(2, "Setup will ask for :\n %s" % aSetup.to_yaml)

         PrcLib.info("Configuring account : '#{config[:account_name]}', provider '#{config[:provider_name]}'")

         # Ask for user input
         aSetup.each_index { | iStep |
            Lorj.debug(2, "Ask step %s:" % iStep)
            puts "%s%s%s" % [ANSI.bold, aSetup[iStep][:desc], ANSI.clear] unless aSetup[iStep][:desc].nil?
            puts "%s\n\n" % ANSI.yellow(aSetup[iStep][:explanation]) unless aSetup[iStep][:explanation].nil?
            aOrder = aSetup[iStep][:order]
            aOrder.each_index { | iIndex |
            Lorj.debug(2, "Ask order %s:" % iIndex)
               aOrder[iIndex].each { | sKey |
                  hParam = _get_meta_data(sKey)
                  hParam = {} if hParam.nil?

                  bOk = false

                  if hParam[:pre_step_function]
                     pProc = hParam[:pre_step_function]
                     bOk = not(@oForjProcess.method(pProc).call(sKey))
                  end


                  sDesc = "'%s' value" % sKey
                  puts "#{sKey}: %s" % [hParam[:explanation]] unless Lorj::rhGet(hParam, :explanation).nil?
                  sDesc = hParam[:desc] unless hParam[:desc].nil?
                  sDefault = @oForjConfig.get(sKey, hParam[:default_value])
                  rValidate = nil

                  rValidate = hParam[:validate] unless hParam[:validate].nil?
                  bRequired = (hParam[:required] == true)
                  while not bOk
                     bOk = true
                     if not hParam[:list_values].nil?
                        hValues = hParam[:list_values]
                        sObjectToLoad = hValues[:object]

                        bListStrict = (hValues[:validate] == :list_strict)

                        case hValues[:query_type]
                           when :controller_call
                              oObject = @ObjectData[sObjectToLoad, :ObjectData]
                              PrcLib.message("Loading #{sObjectToLoad}.")
                              oObject = Create(sObjectToLoad) if oObject.nil?
                              return nil if oObject.nil?
                              oParams = ObjectData.new
                              oParams.add(oObject)
                              oParams << hValues[:query_params]
                              raise Lorj::PrcError.new(), "#{sKey}: query_type => :controller_call requires missing :query_call declaration (Controller function)" if hValues[:query_call].nil?
                              pProc = hValues[:query_call]
                              begin
                                 aList = @oProvider.method(pProc).call(sObjectToLoad, oParams)
                              rescue => e
                                 raise Lorj::PrcError.new(), "Error during call of '%s':\n%s" % [pProc, e.message]
                              end
                           when :query_call
                              sQuery = {}
                              sQuery = hValues[:query_params] unless hValues[:query_params].nil?
                              PrcLib.message("Querying #{sObjectToLoad}.")
                              oObjectList = Query(sObjectToLoad, sQuery)
                              aList = []
                              oObjectList.each { | oElem |
                                 aList << oElem[hValues[:value]]
                              }
                              aList.sort!
                           when :process_call
                              raise Lorj::PrcError.new(), "#{sKey}: query_type => :process_call requires missing :query_call declaration (Provider function)" if hValues[:query_call].nil?
                              pProc = hValues[:query_call]
                              sObjectToLoad = hValues[:object]
                              oParams = ObjectData.new
                              oParams.add(oObject)
                              oParams << hValues[:query_params]
                              begin
                                 aList = @oForjProcess.method(pProc).call(sObjectToLoad, oParams)
                              rescue => e
                                 raise Lorj::PrcError.new(), "Error during call of '%s':\n%s" % [pProc, e.message]
                              end
                           else
                              raise Lorj::PrcError.new, "'%s' invalid. %s/list_values/values_type supports %s. " % [hValues[:values_type], sKey, [:provider_function]]
                        end
                        PrcLib.fatal(1, "%s requires a value from the '%s' query which is empty." % [sKey, sObjectToLoad])if aList.nil? and bListStrict
                        aList = [] if aList.nil?
                        if not bListStrict
                           aList << "other"
                        end
                        say("Enter %s" % ((sDefault.nil?)? sDesc : sDesc + " |%s|" % sDefault))
                        value = choose { | q |
                           q.choices(*aList)
                           q.default = sDefault if sDefault
                        }
                        if not bListStrict and value == "other"
                           value = _ask(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                        end
                     else
                        pValidateProc = hParam[:validate_function]
                        pAskProc = hParam[:ask_function]

                        if pAskProc.nil?
                           unless pValidateProc.nil?
                              value = _ask(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                              while not @oForjProcess.method(pValidateProc).call(value)
                                 value = _ask(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                              end
                           else
                              value = _ask(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                           end
                        else
                           unless pValidateProc.nil?
                              value = @oForjProcess.method(pAskProc).call(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                              while not @oForjProcess.method(pValidateProc).call(value)
                                 value = @oForjProcess.method(pAskProc).call(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                              end
                           else
                              value = @oForjProcess.method(pAskProc).call(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                           end
                        end
                     end

                     @oForjConfig.set(sKey, value)
                     if hParam[:post_step_function]
                        pProc = hParam[:post_step_function]
                        bOk = @oForjProcess.method(pProc).call()
                     end
                  end
               }
            }
         }
      end

      # Initialize Cloud object Data

      def initialize(oForjConfig, oForjProcess, oForjProvider = nil)
         # Object Data object. Contains all loaded object data.
         # This object is used to build hParams as well.
         @ObjectData = ObjectData.new(true)
         #
         @RuntimeContext = {
            :oCurrentObj => nil
         }

         @oForjConfig = oForjConfig
         raise Lorj::PrcError.new(), "'%s' is not a valid ForjAccount or ForjConfig Object." % [oForjConfig.class] if not oForjConfig.is_a?(Lorj::Account) and not oForjConfig.is_a?(Lorj::Config)

         @oProvider = oForjProvider
         if oForjProvider
            raise Lorj::PrcError.new(), "'%s' is not a valid ForjProvider Object type." % [oForjProvider.class] if not oForjProvider.is_a?(BaseController)
         end

         @oForjProcess = oForjProcess
         raise Lorj::PrcError.new(), "'%s' is not a valid BaseProcess Object type." % [oForjProcess.class] if not oForjProcess.is_a?(BaseProcess)

         @oForjProcess.set_BaseObject(self)
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
      #   From processes, you can get a data (runtime/account/config.yaml or defaults.yaml) with:
      #     config.get(key)
      #   OR
      #     config[key]

      def config
         raise Lorj::PrcError.new(), "No config object loaded." if not @oForjConfig
         @oForjConfig
      end

      def format_query(sObjectType, oControlerObject, hQuery)
         {
            :object        => oControlerObject,
            :object_type   => :object_list,
            :list_type     => sObjectType,
            :list          => [],
            :query         => hQuery
         }
      end

      def format_object(sCloudObj, oMiscObject)
         return nil if not sCloudObj or not [String, Symbol].include?(sCloudObj.class)

         sCloudObj = sCloudObj.to_sym if sCloudObj.class == String

         oCoreObject = {
            :object_type => sCloudObj,
            :attrs => {},
            :object => oMiscObject,
         }
      end

      def get_data_metadata(sKey)
         _get_meta_data(sKey)
      end

      # Before doing a query, mapping fields
      # Transform Object query field to Provider query Fields
      def query_map(sCloudObj, hParams)
         return nil if not sCloudObj or not [String, Symbol].include?(sCloudObj.class)
         return {} if not hParams

         sCloudObj = sCloudObj.to_sym if sCloudObj.class == String

         hReturn = {}
         hMap = Lorj::rhGet(@@meta_obj, sCloudObj, :query_mapping)
         hParams.each { |key, value|
            oKeyPath = KeyPath.new(key)
            sKeyPath = oKeyPath.sFullPath
            raise Lorj::PrcError.new(), "Forj query field '%s.%s' not defined by class '%s'.\n"  % [sCloudObj, oKeyPath.sKey, self.class ] +
               "#{ANSI.bold}ACTION REQUIRED#{ANSI.clear}:\n" +
               "Missing data model 'def_attribute' or 'def_query_attribute' for '%s'??? Check the object '%s' data model." % [oKeyPath.sKey, sCloudObj] if not hMap.key?(oKeyPath.sFullPath)
            oMapPath = KeyPath.new(hMap[oKeyPath.sFullPath])
            hValueMapping = Lorj::rhGet(@@meta_obj, sCloudObj, :value_mapping, sKeyPath)
            if hValueMapping
               raise Lorj::PrcError.new(), "'%s.%s': No value mapping for '%s'" % [sCloudObj, oKeyPath.sKey, value] if Lorj::rhExist?(hValueMapping, value) != 1

               Lorj::rhSet(hReturn, hValueMapping[value], oMapPath.aTree)
            else
               Lorj::rhSet(hReturn, value, oMapPath.aTree)
            end
         }
         hReturn
      end

      # Used by the Process.
      # Ask controller get_attr to get a data
      # The result is the data of a defined data attribute.
      # If the value is normally mapped (value mapped), the value is
      # returned as a recognized data attribute value.
      def get_attr(oObject, key)

         raise Lorj::PrcError.new(), "'%s' is not a valid Object type. " % [oObject.class] if not oObject.is_a?(Hash) and Lorj::rhExist?(oObject, :object_type) != 1
         sCloudObj = oObject[:object_type]
         oKeyPath = KeyPath.new(key)
         raise Lorj::PrcError.new(), "'%s' key is not declared as data of '%s' CloudObject. You may need to add obj_needs..." % [oKeyPath.sKey, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj, :returns, oKeyPath.sFullPath) != 3
         begin
            oMapPath = KeyPath.new Lorj::rhGet(@@meta_obj, sCloudObj, :returns, oKeyPath.sFullPath)
            hMap = oMapPath.sFullPath
            value = @oProvider.get_attr(get_cObject(oObject), hMap)

            hValueMapping = Lorj::rhGet(@@meta_obj, sCloudObj, :value_mapping, oKeyPath.sFullPath)

            if hValueMapping
               hValueMapping.each { | found_key, found_value |
                  if found_value == value
                     value = found_key
                     break
                  end
               }
            end
         rescue => e
            raise Lorj::PrcError.new(), "'%s.get_attr' fails to provide value of '%s'" % [oProvider.class, key]
         end
      end

      # Register the object to the internal @ObjectData instance
      def register(oObject, sObjectType = nil, sDataType = :object)
         if oObject.is_a?(Lorj::Data)
            oDataObject = oObject
         else
            raise Lorj::PrcError.new(), "Unable to register an object '%s' as Lorj::Data object if ObjectType is not given." % [ oObject.class ] if not sObjectType
            oDataObject = Lorj::Data.new(sDataType)
            oDataObject.set(oObject, sObjectType) { | sObjType, oControlerObject |
               _return_map(sObjType, oControlerObject)
            }
         end
         @ObjectData.add oDataObject
      end

      def DataObjects(sObjectType, *key)
         @ObjectData[sObjectType, key]
      end

      # get an attribute/object/... from an object.
      def get_data(oObj, *key)
         if oObj.is_a?(Hash) and oObj.key?(:object_type)
            oObjData = ObjectData.new
            oObjData << oObj
         else
            oObjData = @ObjectData
         end
         oObjData[oObj, *key]
      end

      #~ def hParams(sCloudObj, hParams)
         #~ aParams = _get_object_params(sCloudObj, ":ObjectData.hParams")
      #~ end

      def get_cObject(oObject)
         return nil if Lorj::rhExist?(oObject, :object) != 1
         Lorj::rhGet(oObject, :object)
      end

      # a Process can execute any kind of predefined controler task.
      # Those function build hParams with Provider compliant data (mapped)
      # Results are formatted as usual framework Data object and stored.
      def connect(sObjectType)

         hParams = _get_object_params(sObjectType, :create_e, :connect, true)
         oControlerObject = @oProvider.connect(sObjectType, hParams)
         oDataObject = Lorj::Data.new
         oDataObject.set(oControlerObject, sObjectType) { | sObjType, oObject |
            begin
               _return_map(sObjType, oObject)
            rescue => e
               raise Lorj::PrcError.new(), "connect %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }
         @ObjectData.add oDataObject
         oDataObject
      end

      def create(sObjectType)
         # The process ask the controller to create the object.
         # hParams have to be fully readable by the controller.
         hParams = _get_object_params(sObjectType, :create_e, :create, true)
         oControlerObject = @oProvider.create(sObjectType, hParams)
         oDataObject = Lorj::Data.new
         oDataObject.set(oControlerObject, sObjectType) { | sObjType, oObject |
            begin
               _return_map(sObjType, oObject)
            rescue => e
               raise Lorj::PrcError.new(), "create %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }
         @ObjectData.add oDataObject

         oDataObject
      end

      # The controller must return true to inform about the real deletion
      def delete(sObjectType)
         hParams = _get_object_params(sObjectType, :delete_e, :delete, true)
         raise Lorj::PrcError.new(), "delete Controller - %s: Object '%s' is not loaded." % [@oProvider.class, key] if not hParams.exist?(sObjectType)
         bState = @oProvider.delete(sObjectType, hParams)
         @ObjectData.delete(sObjectType) if bState
         bState
      end

      def get(sObjectType, sUniqId)

         hParams = _get_object_params(sObjectType, :get_e, :get, true)

         oControlerObject = @oProvider.get(sObjectType, sUniqId, hParams)
         oDataObject = Lorj::Data.new
         oDataObject.set(oControlerObject, sObjectType) { | sObjType, oObject |
            begin
               _return_map(sObjType, oObject)
            rescue => e
               raise Lorj::PrcError.new(), "get %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }
         @ObjectData.add oDataObject

         oDataObject
      end

      def query(sObjectType, hQuery)

         # Check if we can re-use a previous query
         oList = @ObjectData[:query, sObjectType]
         unless oList.nil?
            if oList[:query] == hQuery
               Lorj.debug(3, "Using Object '%s' query cache : %s" % [sObjectType, hQuery])
               return oList
            end
         end


         hParams = _get_object_params(sObjectType, :query_e, :query, true)
         sProviderQuery = query_map(sObjectType, hQuery)

         oControlerObject = @oProvider.query(sObjectType, sProviderQuery, hParams)

         oDataObjects = Lorj::Data.new :list
         oDataObjects.set(oControlerObject, sObjectType, hQuery) { | sObjType, key |
            begin
               _return_map(sObjType, key)
            rescue => e
               raise Lorj::PrcError.new(), "query %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }

         Lorj.debug(2, "Object %s - queried. Found %s object(s)." % [sObjectType, oDataObjects.length()])

         @ObjectData.add oDataObjects
         oDataObjects
      end

      def update(sObjectType)
         # Need to detect data updated and update the Controler object with the controler

         hParams = _get_object_params(sObjectType, :update_e, :update, true)

         oObject = @ObjectData[sObjectType, :ObjectData]
         oControlerObject = oObject[:object]

         bUpdated = false
         oObject[:attrs].each { |key, value |
            oKeyPath = KeyPath.new(key)
            oMapPath = KeyPath.new Lorj::rhGet(@@meta_obj, sObjectType, :returns, oKeyPath.sFullPath)
            old_value = @oProvider.get_attr(oControlerObject, oMapPath.aTree)
            if value != old_value
               bUpdated = true
               @oProvider.set_attr(oControlerObject, oMapPath.aTree, value)
               Lorj.debug(2, "%s.%s - Updating: %s = %s (old : %s)" % [@oForjProcess.class, sObjectType, key, value, old_value])
            end
         }

         bDone = @oProvider.update(sObjectType, oObject, hParams) if bUpdated

         raise Lorj::PrcError.new, "Controller function 'update' must return True or False. Class returned: '%s'" % bDone.class if not [TrueClass, FalseClass].include?(bDone.class)

         Lorj.debug(1, "%s.%s - updated." % [@oForjProcess.class, sObjectType]) if bDone
         oObject.set(oControlerObject, sObjectType) { | sObjType, oObject |
            begin
               _return_map(sObjType, oObject)
            rescue => e
               raise Lorj::PrcError.new(), "update %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }
         bDone
      end


      private

      # -------------------------------------------------------------------------
      # Functions available for Process to communicate with the controler Object
      # -------------------------------------------------------------------------
      def cloud_obj_requires(sCloudObj, res = {})
         aCaller = caller
         aCaller.pop

         return res if @ObjectData.exist?(sCloudObj)
         #~ return res if Lorj::rhExist?(@CloudData, sCloudObj) == 1

         Lorj::rhGet(@@meta_obj,sCloudObj, :params).each { |key, hParams|
            case hParams[:type]
               when :data
                  if  hParams.key?(:array)
                     hParams[:array].each{ | aElem |
                        aElem = aElem.clone
                        aElem.pop # Do not go until last level, as used to loop next.
                        Lorj::rhGet(hParams, aElem).each { | subkey, hSubParam |
                           next if aElem.length == 0 and [:array, :type].include?(subkey)
                           if hSubParams[:required] and @oForjConfig.get(subkey).nil?
                              res[subkey] = hSubParams
                           end
                        }
                     }
                  else
                     if hParams[:required] and @oForjConfig.get(key).nil?
                        res[key] = hParams
                     end
                  end
               when :CloudObject
                  #~ if hParams[:required] and Lorj::rhExist?(@CloudData, sCloudObj) != 1
                  if hParams[:required] and not @ObjectData.exist?(sCloudObj)
                     res[key] = hParams
                     cloud_obj_requires(key, res)
                  end
            end
         }
         res
      end

      def get_object(sCloudObj)
         #~ return nil if Lorj::rhExist?(@CloudData, sCloudObj) != 1
         return nil if not @ObjectData.exist?(sCloudObj)
         @ObjectData[sCloudObj, :ObjectData]
         #~ Lorj::rhGet(@CloudData, sCloudObj)
      end

      def objectExist?(sCloudObj)
         @ObjectData.exist?(sCloudObj)
         #~ (Lorj::rhExist?(@CloudData, sCloudObj) != 1)
      end

      def get_forjKey(oCloudData, key)
         return nil if not @ObjectData.exist?(sCloudObj)
         @ObjectData[sCloudObj, :attrs, key]
         #~ return nil if Lorj::rhExist?(oCloudData, sCloudObj) != 1
         #~ Lorj::rhGet(oCloudData, sCloudObj, :attrs, key)
      end
   end
end
