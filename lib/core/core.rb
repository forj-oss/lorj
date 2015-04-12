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
  #   oCloud.create(:server)
  #
  # Another basic example (See example directory)
  #
  #   oConfig = Lorj::Account.new()
  #   oPrc = Lorj::Core.new(oConfig, 'mySqlAccount')
  #   oCloud.create(:student, { :student_name => "Robert Redford"})
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

    def connect(oCloudObj, hConfig = nil)
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
    def create(oCloudObj, hConfig = nil)
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

    def get_or_create(oCloudObj, hConfig = nil)
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

    def delete(oCloudObj, hConfig = nil)
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

    def query(oCloudObj, sQuery, hConfig = nil)
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

    def get(oCloudObj, sId, hConfig = nil)
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

    def update(oCloudObj, hConfig = nil)
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
    # * *Args*:
    # - +Processes+: Array of processes with controller
    #   This array, contains a list of process to load and optionnaly a
    #   controller.
    #
    #   You can define your own process or a process module.
    #   The array is structured as follow:
    #   - each element contains a Hash with:
    #     If you are using a process module, set the following:
    #     - :process_module : Name of the process module to load
    #
    #     If you are not using a Process module, you need to set the following:
    #     - :process_path   : Path to a local process code.
    #       This path must contains at least 'process' subdir. And if needed
    #       a 'controllers' path
    #     - :process_name   : Name of the local process
    #
    #     Optionnally, you can set a controller name to use with the process.
    #     - :controller_name: Name of the controller to use.
    #     - :controller_path: Path to the controller file.
    #
    def initialize(the_config = nil, processes = nil, controller_class = nil)
      # Loading ProcessClass
      # Create Process derived from respectively BaseProcess
      PrcLib.core_level = 0 if PrcLib.core_level.nil?

      init_core_config(the_config)

      PrcLib.model.config = @config

      model = initialize_model

      # Compatibility with old 'new syntax'
      # `processes` will get an Array of string/symbol or simply a string/symbol
      # `controller_class` is used to define the controller to load.
      # string/symbol
      processes = adapt_core_parameters(processes, controller_class)

      # Load Application processes
      init_processes(model, processes)

      PrcLib.runtime_fail 'Lorj::Core: No valid process loaded. '\
                           'Aborting.' if model[:process_class].nil?

      # Create Core object with the application model loaded
      # (processes & controller)
      initialize_core_object(model)
      PrcLib.model.clear_heap
    end

    private

    # This function is used to keep compatibility with old way to load
    # processes and controllers
    # If processes is a Array of Hash => new way
    # otherwise we need to create it.
    def adapt_core_parameters(processes, controller)
      return [] unless processes.is_a?(Array)

      return [] if processes.length == 0
      return processes if processes[0].is_a?(Hash)

      PrcLib.warning('lorj initialization with Process & controller parameters'\
                     ' is obsolete. Read Lorj::Core.new to update it and '\
                     'eliminate this warning')

      # Declare processes
      processes = processes_as_array(processes)

      processes_built = []

      processes.each do |process|
        process = process.to_s if process.is_a?(Symbol)
        a_process = {}

        if process.include?('/')
          a_process[:process_path] = process
          a_process[:process_name] = File.basename(process)
        else
          a_process[:process_module] = process
        end
        processes_built << a_process
      end

      _adapt_with_controller(processes_built, controller)

      processes_built
    end

    def _adapt_with_controller(processes_built, controller)
      return if controller.nil?

      if controller.include?('/')
        processes_built[-1][:controller_path] = controller
        processes_built[-1][:controller_name] = File.basename(controller)
      else
        processes_built[-1][:controller_name] = controller
      end
    end
  end

  module_function

  # Any Lorj process module will need to declare itself to Lorj
  # with this function.
  #
  # * *args* :
  #   - +process_name+: name of the process declared to Lorj. This name must be
  #     unique. Otherwise the declaration won't happen.
  #
  #   - +path+        : Path where process dir structure are located.
  #     at least, it expects to find the process/<name>.rb
  #     Each controllers found will be added as well.
  #     It must be controllers/<controller_name>/<controller_name>.rb
  #     You can change 'controllers' by any name, with :controllers_dir
  #
  #   - +properties   : Optional.
  #     - :controllers_dir : Name of the controllers directory.
  #       By default 'controllers'
  #
  #  The process will be added in Lorj.processes Hash
  #
  def declare_process(process_name, path, properties = {})
    process_data = Lorj::ProcessResource.new(process_name, path, properties)

    return nil if process_data.nil?

    @processes = {} if @processes.nil?

    return nil if process_data.process.nil?

    process_name = process_data.name

    @processes[process_name] = process_data unless @processes.key?(process_name)

    process_data
  end

  # Define module data for lorj library configuration
  class << self
    attr_reader :processes
  end
end
