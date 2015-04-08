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

# Definition of Lorj::Config
module Lorj
  # Lorj::Config is a generic class for configuration management.
  # It is used by lorj to get/set data
  #
  # lorj uses following function in different context:
  #
  # In your main:
  # * Config.set        : To set runtime depending on options given by the user
  #                       (cli parameters for example)
  # * Config.get        : To get any kind of data, for example to test values.
  # * Config.save_local_config : To save setting in local config. Use
  #                       Lorj::Config::local_set to set this kind of data to
  #                       save
  # * Config.local_set   : To set a local default data. If the main wanted to
  #                       manage local config.
  # * Config.meta_each  : For example to display all data per section name, with
  #                       values.
  #
  # In Process functions: The Config object is accessible as 'config'.
  # * config.set        : To set runtime data. Ex: adapt process runtime
  #                       behavior.
  #   The best approach is to declare an obj_needs optional. lorj will set it in
  #   hParams.
  # * config.get        : To get data and adapt process behavior.
  #   The best approach is to declare an obj_needs optional and get the value
  #   from hParams.
  #
  # In Controller functions.
  # Usually, the process has implemented everything.
  # You should not use the config object. Thus, config object is not accessible.
  class Config < PRC::CoreConfig
    # Internal Object variables:
    #
    # * @config_name= 'config.yaml'
    # * @runtime_data   = data in memory.
    # * @local_data     = config.yaml file data hash.
    # * @config_obj = Extra loaded data
    # * Lorj::Default  = Application defaults class

    # This function return the filename of the config layer asked:
    #
    # * *Args*    :
    # - +layer_name+ : Layer name to get the config file name
    def config_filename(name = 'local')
      index =  layer_index(name)

      index = 1 if index.nil?

      @config_layers[index][:config].filename
    end

    # Basic dump
    #
    # * *Args*    :
    #
    # * *Returns* :
    #   - hash of config hashes.
    # * *Raises* :
    #   nothing
    def config_dump(names = %w(local default))
      # Build a config hash.

      res = {}

      names = %w(local default) unless names.is_a?(Array)

      options = _common_options_get(:names => names)
      config_layers = options[0][0]
      if names.length == 1
        res = config_layers[0][:config].data
      else
        config_layers.each do |layer|
          res[layer[:name]] = layer[:config].data
        end
      end
      res
    end

    # Load yaml documents (defaults + config)
    # If config doesn't exist, it will be created, empty with 'defaults:' only
    #
    #
    # * *Args*    :
    #   - +config_name+ : Config file name to use. By default, file path is
    #                     built as #{PrcLib.data_path}/config.yaml
    # * *Returns* :
    #   -
    # * *Raises* :
    #   - ++ ->
    def initialize(config_name = nil)
      config_layers = []

      # Application layer
      config_layers << define_default_layer

      # runtime Config layer
      config_layers << define_controller_data_layer

      # Local Config layer
      local = define_local_layer
      config_layers << local

      # runtime Config layer
      config_layers << define_runtime_layer

      if PrcLib.data_path.nil?
        PrcLib.fatal(1, 'Internal PrcLib.data_path was not set.')
      end

      initialize_local(local[:config], config_name)

      initialize_layers(config_layers)
    end

    def define_default_layer
      PRC::CoreConfig.define_layer(:name => 'default',
                                   :config => Lorj.defaults,
                                   :set => false, :load => true)
    end

    def define_local_layer(latest_version = nil)
      PRC::CoreConfig.define_layer(:name => 'local',
                                   :config => \
                                    PRC::SectionConfig.new(nil, latest_version),
                                   :load => true, :save => true)
    end

    def define_controller_data_layer
      PRC::CoreConfig.define_layer :name => 'controller'
    end

    def define_runtime_layer
      PRC::CoreConfig.define_layer
    end

    def initialize_local(config, config_name = nil)
      config_name = initialize_local_filename(config_name)

      PrcLib.ensure_dir_exists(File.dirname(config_name))

      if File.exist?(config_name)
        config.load(config_name)

        if config.data.rh_key_to_symbol?(2)
          config.rh_key_to_symbol(2)
          config.save config_name
        end

      else
        config.data[:default] =  nil
        # Write the empty file
        PrcLib.info('Creating your default configuration file ...')
        config.save config_name
      end
    end

    def initialize_local_filename(config_name = nil)
      config_default_name = 'config.yaml'

      config_name = nil unless config_name.is_a?(String)
      if config_name
        if File.dirname(config_name) == '.'
          config_name = File.join(PrcLib.data_path, config_name)
        end
        config_name = File.expand_path(config_name)
        unless File.exist?(config_name)
          PrcLib.warning("Config file '%s' doesn't exists. Using default one.",
                         config_name)
          config_name = File.join(PrcLib.data_path, config_default_name)
        end
      else
        config_name = File.join(PrcLib.data_path, config_default_name)
      end
      config_name
    end

    # Function to set a runtime key/value, but remove it if value is nil.
    # To set in config.yaml, use Lorj::Config::local_set
    # To set on extra data, like account information, use
    # Lorj::Config::extra_set
    #
    # * *Args*    :
    #   - +key+   : key name. Can be an key tree (Array of keys).
    #   - +value+ : Value to set
    # * *Returns* :
    #   - value set
    # * *Raises* :
    #   Nothing
    def set(key, value)
      self[key] = value # Call PRC::CoreConfig [] function
    end

    # Get function
    # Will search over several places:
    # * runtime - Call internal runtime_get -
    # * local config (config>yaml) - Call internal local_get -
    # * application default (defaults.yaml) - Call Lorj.defaults.get -
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
      self[key, default]
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
    def [](key, default = nil) # Re-define PRC::CoreConfig []= function
      return p_get(:keys => [key]) if exist?(key)
      default
    end

    # get_section helps to identify in which section the data is defined by
    # data model of the application.
    #
    # * *Args*    :
    #   - +key+    : key name
    #
    # * *Returns* :
    #   - the section name found
    #   OR
    #   - nil
    #
    # * *Raises* :
    #   nothing
    def get_section(key)
      section = Lorj.defaults.get_meta_section(key)

      unless section
        return PrcLib.debug('%s: Unable to get account data '\
                            "'%s'. No section found. check defaults.yaml.",
                            __callee__, key)
      end
      section
    end
  end

  # Add Runtime/local functions
  class Config
    # Check if the key exist as a runtime data.
    #
    # * *Args*    :
    #   - +key+   : key name. It do not support it to be a key tree
    #               (Arrays of keys).
    # * *Returns* :
    #   - true/false
    # * *Raises* :
    #   Nothing
    def runtime_exist?(key)
      index = layer_index('runtime')
      @config_layers[index][:config].exist?(key)
    end

    # Get exclusively the Runtime data.
    # Internally used by get.
    #
    # * *Args*    :
    #   - +key+   : key name. It do not support it to be a key tree
    #               (Arrays of keys).
    # * *Returns* :
    #   - key value.
    # * *Raises* :
    #   Nothing
    def runtime_get(key)
      index = layer_index('runtime')
      @config_layers[index][:config][key]
    end

    # Save the config.yaml file.
    #
    # * *Args*    :
    #   nothing
    # * *Returns* :
    #   - true/false
    # * *Raises* :
    #   nothing
    def save_local_config
      index = layer_index('local')
      file = file(nil, :index => index)
      begin
        result = save(:index => index)
      rescue => e
        PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
        return false
      end

      if result
        PrcLib.info('Configuration file "%s" updated.', file)
        return true
      end
      PrcLib.debug('Configuration file "%s" was NOT updated.', file)
      false
    end

    #
    # Function to check default keys existence(in section :default) from local
    # config file only.
    #
    # * *Args*    :
    #   - +key+     : Symbol/String(converted to symbol) key name to test.
    # * *Returns* :
    #   -
    # * *Raises* :
    #   nothing
    def local_default_exist?(key)
      local_exist?(key)
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
    def local_exist?(key, section = :default)
      index = layer_index('local')

      config = @config_layers[index][:config]
      config.data_options(:section => section)

      config.exist?(key)
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
    def local_set(key, value, section = :default)
      key = key.to_sym if key.class == String
      return false if !key || !value

      index = layer_index('local')

      config = @config_layers[index][:config]
      config.data_options(:section => section)
      config[key] = value
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
    def local_get(key, section = :default, default = nil)
      key = key.to_sym if key.class == String

      return default unless local_exist?(key, section)

      index = layer_index('local')
      config = @config_layers[index][:config]
      config.data_options(:section => section)
      config[key]
    end

    # Function to Delete a key value in local config file only.
    #
    # * *Args*    :
    #   - +key+     : Symbol/String(converted to symbol) key name to test.
    #   - +section+ : Section name to test the key.
    #
    # * *Returns* :
    #   - value deleted
    #   OR
    #   - false
    # * *Raises* :
    #   nothing
    def local_del(key, section = :default)
      key = key.to_sym if key.class == String

      return false if key.nil?

      index = layer_index('local')
      config = @config_layers[index][:config]
      config.data_options(:section => section)
      config.del(key)
    end

    # Function to return in fatal error if a config data is nil. Help to control
    # function requirement.
    #
    #
    # * *Args*    :
    #   - +key+     : Symbol/String(converted to symbol) key name to test.
    # * *Returns* :
    #   nothing
    # * *Raises* :
    #   - +fatal+ : Call to PrcLib.fatal to exit the application with error 1.
    def fatal_if_inexistent(key)
      PrcLib.fatal(1, "Internal error - %s: '%s' is missing",
                   caller, key) unless get(key)
    end

    # each loop on Application Account section/key (meta data).
    # This loop will extract data from :section of the application definition
    # (defaults.yaml)
    # key identified as account exclusive (:account_exclusive = true) are not
    # selected.
    #
    # * *Args*    :
    #   - ++ ->
    # * *Returns* :
    #   -
    # * *Raises* :
    #   - ++ ->
    def meta_each
      Lorj.defaults.meta_each do |section, key, value|
        next if !value.nil? && value.rh_get(:account_exclusive).is_a?(TrueClass)
        yield section, key, value
      end
    end
  end
end
