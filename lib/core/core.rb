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
  # This is the main lorj class.
  # It interfaces your main code with the full lorj system as shown in the
  # concept document.
  # It give you access to the lorj model object designed by your process.
  #
  # When you start using it, your main must be as simple as you can, as you will
  # need to move most of your application logic to the process.
  # Your application can have several lorj objects running in your code,
  # depending of your needs.
  #
  # The main things is that you can move most of your process management,
  # usually in your code/modules to be part of the lorj process, make it
  # controller independant, and gains in implementing several controllers to
  # change the way to implement but not the process, you used to build your
  # application!
  #
  # Then, your application contributors can build their own controller and
  # extend your solution!
  #
  # Here an example of creating a CloudServer, using CloudCore
  # (derived from Core).
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
  # See BaseProcess to check how you can write a process and what kind of
  # functions are available for your process to be kept controller independant.
  #
  # See BaseController to see how you can write a controller and what kind of
  # functions are available to deal with the implementation API you need to use.
  class Core
    # Public access to a config object.
    # A config object can be any kind of class which should provide at least
    # following functions:
    #
    # - get(*key, default=nil) and [*key]  : function to get a value from a key.
    #                                        default is a value to get if not
    #                                        found.
    # - set(*key, value) or [*key, value]= : function to set a value to a key.
    #   Ex: From processes, you can set a runtime data with:
    #
    #      config.set(key, value)
    #
    #   OR
    #
    #      config[key] = value
    #
    # - exist?(*key)                       : function which return false if not
    #                                        found, or any other value if found.
    #   Ex: From processes, you can get a data (runtime/account/config.yaml or
    #       defaults.yaml) with:
    #
    #      config.get(key)
    #
    #   OR
    #
    #      config[key]
    #
    # For each functions, *key is a list of value, which becomes an array in the
    # function.
    # It should accept to manage the key tree (hash of hashes)
    #
    # Currently lorj comes with Lorj::Config or Lorj::Account.
    # Thoses classes defines at least those 5 functions. And more.
    attr_reader :config

    # a wrapper to Create call. Use this function for code readibility.
    #
    # * *Args* :
    #   - +oCloudObj+ : Name of the object to initialize.
    #   - +hConfig+   : Hash of hashes containing data required to initialize
    #                   the object.
    #     If you use this variable, any other runtime config defined
    #     by the Data model will be cleaned before
    #
    # * *Returns* :
    #   - +Lorj::Data+ : Represents the Object initialized.
    #
    # * *Raises* :
    #   No exceptions

    def connect(oCloudObj, hConfig = {})
      return nil if !oCloudObj || !@core_object
      @core_object.process_create(oCloudObj, hConfig)
    end

    # Execute the creation process to create the object `oCloudObj`.
    # The creation process can add any kind of complexity to
    # get the a memory representation of the object manipulated during creation
    # process.
    # This means that a creation process can be (non exhaustive list of
    # possibilities)
    # - a connection initialization
    # - an internal memory data structure, like hash, array, ruby object...
    # - a get or create logic
    # - ...
    #
    # * *Args* :
    #   - +oCloudObj+ : Name of the object to initialize.
    #   - +hConfig+   : Hash of hashes containing data required to initialize
    #                   the object.
    #     If you use this variable, any other runtime config defined
    #     by the Data model will be cleaned before
    #
    # * *Returns* :
    #   - +Lorj::Data+ : Represents the Object initialized.
    #
    # * *Raises* :
    #   No exceptions
    def create(oCloudObj, hConfig = {})
      return nil if !oCloudObj || !@core_object
      @core_object.process_create(oCloudObj, hConfig)
    end

    # a wrapper to Create call. Use this function for code readibility.
    #
    # * *Args* :
    #   - +oCloudObj+ : Name of the object to initialize.
    #   - +hConfig+   : Hash of hashes containing data required to initialize
    #                   the object.
    #     If you use this variable, any other runtime config defined
    #     by the Data model will be cleaned before
    #
    # * *Returns* :
    #   - +Lorj::Data+ : Represents the Object initialized.
    #
    # * *Raises* :
    #   No exceptions

    def get_or_create(oCloudObj, hConfig = {})
      return nil if !oCloudObj || !@core_object
      @core_object.process_create(oCloudObj, hConfig)
    end

    # Execution of the delete process for the `oCloudObj` object.
    # It requires the object to be loaded in lorj Lorj::Data objects cache.
    # You can use `Create` or `Get` functions to load this object.
    #
    # * *Args* :
    #   - +oCloudObj+ : Name of the object to initialize.
    #   - +hConfig+   : Hash of hashes containing data required to initialize
    #                   the object.
    #     If you use this variable, any other runtime config defined
    #     by the Data model will be cleaned before
    #
    # * *Returns* :
    #   - +Lorj::Data+ : Represents the Object initialized.
    #
    # * *Raises* :
    #   No exceptions

    def delete(oCloudObj, hConfig = {})
      return nil if !oCloudObj || !@core_object

      @core_object.process_delete(oCloudObj, hConfig)
    end

    # Execution of the Query process for the `oCloudObj` object.
    #
    # * *Args* :
    #   - +oCloudObj+ : Name of the object to initialize.
    #   - +sQuery+    : Hash representing the query filter.
    #   - +hConfig+   : Hash of hashes containing data required to initialize
    #                   the object.
    #     If you use this variable, any other runtime config defined
    #     by the Data model will be cleaned before
    #
    # * *Returns* :
    #   - +Lorj::Data+ : Represents the Object initialized.
    #
    # * *Raises* :
    #   No exceptions

    def query(oCloudObj, sQuery, hConfig = {})
      return nil if !oCloudObj || !@core_object

      @core_object.process_query(oCloudObj, sQuery, hConfig)
    end

    # Execution of the Get process for the `oCloudObj` object.
    #
    # * *Args* :
    #   - +oCloudObj+ : Name of the object to initialize.
    #   - +sId+       : data representing the ID (attribute :id) of a Lorj::Data
    #                   object.
    #   - +hConfig+   : Hash of hashes containing data required to initialize
    #                   the object.
    #     If you use this variable, any other runtime config defined
    #     by the Data model will be cleaned before
    #
    # * *Returns* :
    #   - +Lorj::Data+ : Represents the Object initialized.
    #
    # * *Raises* :
    #   No exceptions

    def get(oCloudObj, sId, hConfig = {})
      return nil if !oCloudObj || !@core_object || sId.nil?

      @core_object.process_get(oCloudObj, sId, hConfig)
    end

    # Execution of the Update process for the `oCloudObj` object.
    # Usually, the Controller object data is updated by the process
    # (BaseController::set_attr)
    # then it should call a controller_update to really update the data in the
    # controller.
    #
    # * *Args* :
    #   - +oCloudObj+ : Name of the object to initialize.
    #   - +sId+       : data representing the ID (attribute :id) of a Lorj::Data
    #                   object.
    #   - +hConfig+   : Hash of hashes containing data required to initialize
    #                   the object.
    #     If you use this variable, any other runtime config defined
    #     by the Data model will be cleaned before
    #
    # * *Returns* :
    #   - +Lorj::Data+ : Represents the Object initialized.
    #
    # * *Raises* :
    #   No exceptions

    def update(oCloudObj, hConfig = {})
      return nil if !oCloudObj || !@core_object

      @core_object.process_update(oCloudObj, hConfig)
    end

    # Function used to ask users about setting up his account.
    #
    # * *Args* :
    #   - +oCloudObj+    : Name of the object to initialize.
    #   - +sAccountName+ : Account file name. If not set, Config[:account_name]
    #                      is used.
    #     If you use this variable, any other runtime config defined
    #     by the Data model will be cleaned before
    #
    # * *Returns* :
    #   - +Lorj::Data+ : Represents the Object initialized.
    #
    # * *Raises* :
    #   No exceptions

    def setup(oCloudObj, sAccountName = nil)
      return nil if !oCloudObj || !@core_object
      @core_object.process_setup(oCloudObj, sAccountName)
    end

    # Core parameters are:
    # the_config : Optional. An instance of a configuration system which *HAVE*
    # to provide get/set/exist?/[]/[]=
    #
    # processClass: Array of string or symbol, or string or symbol. Is the path
    # or name of one or more ProcessClass to use.
    #   This class is dynamically loaded and derived from BaseProcess class.
    #   It loads the Process class content from a file
    #   '$CORE_PROCESS_PATH/<process_class>.rb'
    #   If process_class is a file path, this file will be loaded as a ruby
    #   include.
    #
    #   <process_class>.rb file name is case sensible and respect RUBY Class
    #   name convention
    #
    # controller_class: Optional. string or symbol. Is the path or name of
    #                   ControllerClass to use.
    #   This class is dynamically loaded and derived from BaseController class.
    #   It loads the Controler class content from a file
    #   '$PROVIDER_PATH/<controller_class>.rb'
    #
    #   The provider can redefine partially or totally some processes
    #   Lorj::Core will load those redefinition from file:
    #   $PROVIDER_PATH/<controller_class>Process.rb'
    #
    # <controller_class>.rb or <controller_class>Process.rb file name is case
    # sensible and respect RUBY Class name convention
    def initialize(the_config = nil, the_process_class = nil,
                   controller_class = nil)
      # Loading ProcessClass
      # Create Process derived from respectively BaseProcess
      PrcLib.core_level = 0 if PrcLib.core_level.nil?

      init_core_config(the_config)

      model = initialize_model

      # Load Application processes
      init_processes(model, the_process_class)

      fail Lorj::PrcError.new, 'Lorj::Core: No valid process loaded. '\
                               'Aborting.' if model[:process_class].nil?

      # Load Controller and Controller processes.
      init_controller(model, controller_class) if controller_class

      # Create Core object with the application model loaded
      # (processes & controller)
      initialize_core_object(model)
      PrcLib.model.clear_heap
    end
  end

  # This class based on generic Core, defines a Cloud Process to use.
  class CloudCore < Core
    def initialize(oConfig, sAccount = nil, aProcesses = [])
      config_account = init_config(oConfig, sAccount)

      process_list = [:CloudProcess]

      controller_mod = config_account.get(:provider_name)
      fail Lorj::PrcError.new, 'Provider_name not set. Unable to create'\
                               ' instance CloudCore.' if controller_mod.nil?

      init_controller_mod(process_list, controller_mod)

      super(config_account, process_list.concat(aProcesses), controller_mod)
    end

    private

    def init_config(oConfig, sAccount)
      if !oConfig.is_a?(Lorj::Account)
        config_account = oConfig
      else
        config_account = Lorj::Account.new(oConfig)

        config_account.ac_load(sAccount) unless sAccount.nil?
      end
      config_account
    end

    def init_controller_mod(process_list, controller_mod)
      # TODO: Support for process full path, instead of predefined one.
      controller_process_mod = File.join(PrcLib.controller_path, controller_mod,
                                         controller_mod.capitalize +
                                         'Process.rb')
      if File.exist?(controller_process_mod)
        process_list << controller_process_mod
      else
        Lorj.debug(1, format("No Provider process defined. File '%s' not "\
                             'found.', controller_process_mod))
      end
    end
  end
end
