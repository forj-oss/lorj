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

   # Internal PrcError class object derived from RuntimeError.
   # Internally used with raise.
   # Used to identify the error origin, while an error is thrown.
   class PrcError < RuntimeError
      attr_reader :ForjMsg

      def initialize(message = nil)
         @ForjMsg = message
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

end
