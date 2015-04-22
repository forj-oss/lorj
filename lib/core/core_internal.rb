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

# - Lorj::Core : Lorj exposed interface.
#   - Initialization functions
module Lorj
  # Define private initialize functions for processes
  class Core
    private

    # Create core objects
    # Create a BaseDefinition object => Core
    # Attach Config, Process and Controller object
    def initialize_core_object(model)
      ensure_class_exist(model[:process_class_name])

      # Ex: Hpcloud(ForjAccount, HpcloudProvider)
      def_class = model[:def_class]
      if model[:controller_class]
        @core_object = def_class.new(@config,
                                     model[:process_class].new,
                                     model[:controller_class].new)
      else
        @core_object = def_class.new(@config,
                                     model[:process_class].new)
      end
    end

    # Function to ensure a Class_name as already been loaded or not
    # It raises an error if not.
    def ensure_class_exist(class_name)
      # Ensure Process class exists ---------------
      Object.const_get(class_name)
    rescue => e
      raise Lorj::PrcError.new, format('Lorj::Core: Unable to find class'\
                                       " '%s'\n%s", class_name, e.message)
    end

    # Initialize the Application model structure for Initialization
    #
    # * *Returns* :
    #   - model : Basic model.
    def initialize_model
      { :def_class => BaseDefinition,
        :processes => [],
        :process_class => nil, :process_class_name => nil,
        :controller_class => nil, :controller_class_name => nil }
    end

    # Initialize a basic Config Object and use the one passed
    # as parameter.
    # It sets @config instance attribute
    def init_core_config(the_config)
      if the_config.nil?
        @config = Lorj::Config.new
        Lorj.debug(2, 'Using an internal Lorj::Config object.')
      else
        @config = the_config
      end
    end

    # Function to initialize itself with application controller.
    #
    # * *Args* :
    #   - +model+      : Application model loaded.
    #   - +controller+ : Processes to load.
    #     supports     :
    #                   - nil => return []
    #                   - String/Symbol => return [String/Symbol]
    #                   - Array => return Array
    #
    # * *Returns* :
    #   - model : Application model loaded.
    def init_controller(model, the_controller)
      Lorj.debug(1, "Loading Controller/definition '%s'", the_controller)

      ok = load_controller(model, the_controller)

      PrcLib.warning("Controller '%s' not properly loaded.",
                     the_controller) unless ok

      model
    end

    # Function to load a controller.
    # This function helps to load a Controller process
    # (See load_process_controller_file) if exists
    # and load the core controller file
    # (Seeload_controllerfile)
    #
    # * *Args* :
    #   - +the_controller+ : Controller to load. Can be a string or
    #                      a path to a file
    #
    # * *Returns* :
    #   - load_status : true if loaded, false otherwise
    def load_controller(model, the_controller)
      load_process_controller(model, the_controller)

      the_controller = the_controller.to_s unless the_controller.is_a?(String)
      if the_controller.include?('/')
        file = File.expand_path(the_controller)
      else
        file = controllerfile_from_default(model, the_controller)
      end

      return PrcLib.warning('Controller not loaded: Controller file '\
                            "definition '%s' is missing.",
                            file) unless File.exist?(file)
      load_controllerfile(model, file, classname_from_file(file))
    end

    # Load a Controller process file in ruby.
    # If controller is a file, the process file name will be suffixed by
    # _process, before the .rb file name.
    #
    # If controller is just a name (String/Symbol), it will load
    # a file suffixed by _process.rb from PrcLib.controller_path
    #
    # * *Args* :
    #   - +model+      : Application/controller model loaded.
    #   - +controller+ : Symbol/String. Controller name or file to load.
    #
    # * *Returns* :
    #   - loaded : load status
    def load_process_controller(model, the_controller)
      Lorj.debug(1, "Loading process for controller '%s'", the_controller)

      the_controller = the_controller.to_s unless the_controller.is_a?(String)
      if the_controller.include?('/')
        the_controller_process = the_controller.clone
        the_controller_process['.rb'] = '_process.rb'
        file = File.expand_path(the_controller_process)
      else
        file = controllerfile_from_default(model, the_controller, '_process')
      end

      return Lorj.debug(2, 'Process not loaded: Process controller file '\
                          "definition '%s' is missing.",
                        file) unless File.exist?(file)
      load_processfile(model, file, classname_from_file(file))
    end

    # Load a Controller file in ruby.
    #
    # * *Args* :
    #   - +model+      : Application/controller model loaded.
    #   - +file+       : Process file to load.
    #   - +controller+ : Controller name or file to load.
    #
    # * *Returns* :
    #   - loaded : load status
    def load_controllerfile(model, file, the_controller)
      # Initialize an empty class derived from BaseDefinition.
      # This to ensure provider Class will be derived from this Base Class
      # If this class is derived from a different Class, ruby will raise an
      # error.

      # Create Definition and Controler derived from respectively
      # BaseDefinition and BaseControler
      base_definition_class = Class.new(BaseDefinition)
      # Finally, name that class!
      Lorj.debug(2, "Declaring Definition '%s'", the_controller)
      Object.const_set the_controller, base_definition_class

      model[:controller_class_name] = the_controller + 'Controller'
      base_controller_class = Class.new(BaseController)
      Lorj.debug(2, "Declaring Controller '%s'", model[:controller_class_name])

      model[:controller_class] = Object.const_set model[:controller_class_name],
                                                  base_controller_class

      # Loading Provider base file. This file should load a class
      # which have the same name as the file.
      load file
    end

    # Determine the controller file path from the single name.
    # Uses PrcLib.controller_path as path to load this process.
    #
    # * *Args* :
    #   - +the_controller_class+ : Controller to load.
    #
    # * *Returns* :
    #   - file : absolute file path.
    def controllerfile_from_default(_model, the_controller, suffix = '')
      File.join(PrcLib.controller_path, the_controller,
                the_controller + suffix + '.rb')
    end
  end

  # Define private Initialize functions for controllers
  class Core
    private

    # Function to initialize itself with application processes.
    #
    # * *Args* :
    #   - +model+ : Application model loaded.
    #   - +processes+ : Array of processes and controller to load
    #     - each element contains a Hash with:
    #       If you are using a process module, set the following:
    #       - :process_module : Name of the process module to load
    #
    #       If you are not using a Process module, you need to set the following
    #       - :process_path   : Path to a local process code.
    #         This path must contains at least 'process' subdir. And if needed
    #         a 'controllers' path
    #       - :process_name   : Name of the local process
    #       - :defaults       : Define the defaults data setting for the process
    #       - :data           : Define process data definition.
    #
    #       Optionnally, you can set a controller name to use with the process.
    #       - :controller_name: Name of the controller to use.
    #       - :controller_path: Path to the controller file.
    #
    # * *Returns* :
    #   - model : Application model loaded.
    def init_processes(model, processes)
      processes.each_index do |index|
        my_process = {}
        a_process = processes[index]
        if a_process.key?(:process_module)
          my_process = _process_module_to_load(index, my_process, a_process)
        else
          my_process = _process_local_to_load(index, my_process, a_process)
        end

        next if my_process.nil?

        model[:processes] << my_process

        _process_load(model, my_process)
      end

      model
    end

    # high level function to load process
    def _process_load(model, my_process)
      if load_process(model, my_process[:process_path])
        controller_class = my_process[:controller_path]
        controller_class = my_process[:controller_name] if controller_class.nil?

        init_controller(model, controller_class) if controller_class
      else
        PrcLib.warning("Process '%s' not properly loaded.",
                       my_process[:process_path])
      end
    end

    # function prepare of loading a local process
    def _process_local_to_load(index, my_process, a_process)
      my_process[:process_path] = a_process[:process_path]

      if a_process[:process_name].nil?
        my_process[:process_name] = File.basename(a_process[:process_path])
      else
        my_process[:process_name] = a_process[:process_name]
      end

      if a_process[:controller_path]
        my_process[:controller_path] = a_process[:controller_path]
      else
        my_process[:controller_name] = a_process[:controller_name]
      end

      defaults_file = a_process[:defaults]
      if defaults_file.nil?
        path = a_process[:process_path]
        path['.rb'] = ''
        defaults_file = File.join(path, 'defaults.yaml')
      end

      _process_load_data(config, index,
                         a_process[:process_name], defaults_file,
                         PRC::SectionConfig)

      data_file = a_process[:data]
      if defaults_file.nil?
        path = a_process[:process_path]
        path['.rb'] = ''
        data_file = File.join(path, 'data.yaml')
      end

      _process_load_data(Lorj.data, index,
                         a_process[:process_name], data_file)

      # TODO: Implement Object definition as a config layer.
      # _process_load_definition(definition, index, a_process[:process_name],
      #                          a_process[:definition])

      my_process
    end

    # Function prepare of loading a module process.
    def _process_module_to_load(index, my_process, a_process)
      name = a_process[:process_module]

      if name.nil?
        PrcLib.warning(':process_module is empty. Process not properly loaded.')
        return
      end

      name = name.to_s if name.is_a?(Symbol)

      unless Lorj.processes.key?(name)
        PrcLib.warning("Unable to find Process module '%s'. Process not "\
                       'properly loaded.', name)
        return
      end

      module_process = Lorj.processes[name]
      my_process[:process_name] = name
      my_process[:process_path] = module_process.process

      if a_process[:controller_path]
        my_process[:controller_path] = a_process[:controller_path]
        return my_process
      end

      _process_module_set_ctr(my_process, module_process.controllers,
                              a_process[:controller_name])

      _process_load_data(config, index, name, module_process.defaults_file,
                         PRC::SectionConfig)

      _process_load_data(Lorj.data, index, name, module_process.data_file)

      # TODO: Implement Object definition as a config layer.
      # _process_load_definition(definition, index, name,
      #                          module_process.definition)

      my_process
    end

    # Load data definition in process data layers
    def _process_load_data(config, index, name, file,
                           config_class = PRC::BaseConfig)
      return unless config.layer_index(name).nil?

      return if file.nil?

      layer = PRC::CoreConfig.define_layer(:name => name,
                                           :config => config_class.new,
                                           :load => true,
                                           :set => false)
      unless layer[:config].load(file)
        PrcLib.warning("Process '%s', data file '%s' was not loaded.",
                       name, file)
      end

      config.layer_add(layer.merge(:index => (config.layers.length - index)))
    end

    # Load process definition in process layers
    # Function currently not developped.
    #
    # def _process_load_definition(a_process)
    # end

    def _process_module_set_ctr(my_process, controllers, controller_name)
      return if controller_name.nil?

      controller_path = controllers[controller_name]

      if controller_path.nil?
        PrcLib.warning("Controller '%s' was not found. Please check. The "\
                       'process may not work.', controller_name)
        return
      end

      my_process[:controller_path] = controller_path
    end

    # Function analyzing the process class parameter
    # and return the list of processes in an
    # array of processes.
    #
    # * *Args* :
    #   - +processes_parameter+ : Parameter to interpret.
    #     supports:
    #              - nil => return []
    #              - String/Symbol => return [String/Symbol]
    #              - Array => return Array
    #
    # * *Returns* :
    #   - array_processes : Array of processes.
    def processes_as_array(processes_parameter)
      return [] if processes_parameter.nil?

      return [processes_parameter] unless processes_parameter.is_a?(Array)

      processes_parameter
    end

    # Function to load a process.
    #
    # * *Args* :
    #   - +the_process_+ : Process to load. Can be a string or
    #                      a path to a file
    #
    # * *Returns* :
    #   - load_status : true if loaded, false otherwise
    def load_process(model, the_process)
      Lorj.debug(1, "Loading Process '%s'", the_process)

      if the_process.include?('/')
        file = File.expand_path(the_process)
      else
        file = processfile_from_default(model, the_process)
      end

      return PrcLib.warning("Process file definition '%s' is missing. ",
                            file) unless File.exist?(file)

      load_processfile(model, file, classname_from_file(file))
    end

    # Function which determine the class name from the file name.
    # rules:
    # - First character : Capitalized
    # - Any character prefixed by '_' : capitalized. '_' is removed.
    #
    # * *Args* :
    #   - +the_process_file+ : Process file to analyze.
    #
    # * *Returns* :
    #   - ProcessClassName : string representing the name of the class.
    def classname_from_file(file)
      the_process_class = File.basename(file)

      the_process_class['.rb'] = '' if the_process_class['.rb']

      if (/[A-Z]/ =~ the_process_class) != 0
        the_process_class = the_process_class.capitalize
      end

      match_found = the_process_class.scan(/_[a-z]/)
      if match_found
        match_found.each { |str| the_process_class[str] = str[1].capitalize }
      end

      the_process_class
    end

    # Determine the process file path from the single name.
    # Uses PrcLib.process_path as path to load this process.
    #
    # * *Args* :
    #   - +the_process_class+ : Process to load.
    #
    # * *Returns* :
    #   - file : absolute file path composed by:
    #            PrcLib.process_path/the_process_class + '.rb'
    def processfile_from_default(_model, the_process_class)
      File.join(PrcLib.process_path, the_process_class + '.rb')
    end

    # Load a process file in ruby.
    #
    # * *Args* :
    #   - +file+    : Process file to load.
    #
    # * *Returns* :
    #   - loaded : load status
    def load_processfile(model, file, the_process_class)
      model[:process_class] = BaseProcess if model[:process_class].nil?

      new_class = Class.new(model[:process_class])
      unless /Process$/ =~ the_process_class
        the_process_class = format('%sProcess',  the_process_class)
      end

      Lorj.debug(1, "Declaring Process '%s'", the_process_class)
      model[:process_class] = Object.const_set(the_process_class, new_class)
      model[:process_class_name] = the_process_class
      BaseDefinition.current_process(model[:process_class])
      load file
    end
  end
end
