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

# Lorj module implements Lorj::Config
# Lorj exposes defaults, as attribute to access the Lorj::Defaults instance.
module Lorj
  # Private functions for MetaAppConfig
  class MetaAppConfig < PRC::CoreConfig
    private

    # Used anytime config is updated (config data load or initialization)
    #
    # This function rebuild the section/key mapping
    # Usually, executed while initializing or while loading a config.
    def build_section_mapping
      return unless p_exist?(:keys => [:sections])

      # The primary data key should change from key to section & key.
      data = p_get(:keys => [:sections], :merge => true)

      return if data.nil?
      section_map = {}

      data.each do |section, values|
        next if values.nil?
        values.keys.each do |key|
          section_map[key] = [] unless section_map.key?(key)
          next if section_map[key].include?(section)

          section_map[key] << section
        end
      end
      p_set(:keys => [:keys], :value => section_map, :name => 'map')
    end

    # Implement a section detection in a symbol/string
    # Help each auto_* functions to work without update.
    #
    def _detect_section(key, default_section)
      m = key.to_s.match(/^(.*)#(.*)$/)
      return [m[1].to_sym, m[2].to_sym] if m && m[1] != '' && m[2] != ''
      [default_section, key]
    end

    # set section data mapping
    #
    def update_map(section, data)
      keys = [:keys, data]
      map = p_get(:keys => keys, :name => 'map')
      if map.nil?
        map = [section]
      else
        map << section unless map.include?(section)
      end
      p_set(:keys => keys, :name => 'map', :value => map)
    end

    # delete section data mapping
    #
    def delete_map(section, data)
      keys = [:keys, data]
      map = p_set(:keys => keys, :name => 'map')
      return if map.nil?

      map.remove section
    end

    # parameters tester functions
    #
    # * *Args*
    #   Each data are defined by a couple parameters.
    #   - 1st one is the value to check
    #   - 2nd one is the expected class (Class object) or
    # acceptable classes (Array of class).
    #
    # * *Returns*
    #   - false if value is not of the expected Class.
    #   - true if all parameters are as expected.
    #
    def check_par(*parameters)
      parameters.each_index do |index|
        next unless index.odd?

        if parameters[index].is_a?(Array)
          unless parameters[index].include?(parameters[index - 1].class)
            return false
          end
        end

        if parameters[index].is_a?(Class)
          return false unless parameters[index - 1].is_a?(parameters[index])
        end
      end
      true
    end

    # build keys for set and del
    # We assume type, section, data_keys to be with appropriate type.
    def build_keys(type, section, data_keys)
      keys = [type, section]

      return keys.concat(data_keys) if data_keys.is_a?(Array)
      keys << data_keys
    end

    # Define the meta_data Application layer
    # It requires a Hash to initialize this layer until
    # a file load is done instead. (Planned for Lorj 2.0)
    def define_meta_app_layer(data)
      data.delete(:keys) if data.is_a?(Hash) && data.key?(:keys)

      PRC::CoreConfig.define_layer(:name => 'app',
                                   :config => PRC::BaseConfig.new(data),
                                   :set => false)
    end

    # Define the meta_data section/keys mapping layer
    def define_meta_map_layer
      PRC::CoreConfig.define_layer(:name => 'map', :set => true)
    end

    # Define the meta_data Application layer
    def define_meta_controller_layer
      PRC::CoreConfig.define_layer(:name => 'controller', :set => true,
                                   :load => true)
    end
  end

  # This class is the Meta Application configuration class accessible from
  # PrcLib.metadata
  #
  # A unique class instance load data from Lorj::Defaults thanks to the
  # defaults.yaml.
  # In the near future, sections `:setup` and `:sections` will be moved to
  # a different file and loaded by this instance itself.
  #
  # It implements Meta Config layers to help in loading default application meta
  # data, and any controller/process redefinition.
  #
  # The defaults.yaml :sections and :setup is defined as follow:
  #
  # * :setup:   Contains :ask_step array
  #   - :ask_step:
  #
  #     Array of group of keys/values to setup. Each group will be
  #     internally identified by a index starting at 0. parameters are as
  #     follow:
  #     - :desc:        string to print out before group setup
  #
  #       ERB template enable: To get config data in ERB context, use
  #       config[...]
  #
  #     - :explanation: longer string to display after :desc:
  #
  #       It is printed out in brown color.
  #
  #       It supports ERB template. To get config data, type
  #       <%= config[...] %>
  #
  #       In your defaults.yaml file, write multiline with |- after the key.
  #
  #       Ex: if config['text'] returns 'text', defaults.yaml can have the
  #       following explanation.
  #
  #           :setup:
  #             :ask_step:
  #             - :desc: 'Small description'
  #               :explanation: |-
  #                 My complete explanation is in
  #                 multiline <%= config['text'] %>
  #
  #       By default, thanks to data model dependency, the group is
  #       automatically populated. So, you need update this part only for data
  #       that are not found from the dependency.
  #
  #
  #     - :add: array of keys to add manually in the group. The Array can be
  #       written with [] or list of dash elements
  #
  #       Example of a defaults.yaml content:
  #
  #           :setup:
  #             :ask_step:
  #             - :desc: 'Small description'
  #               :add: [:key_pair_files, :ssh_user]
  #
  # * :section: Contains a list of sections with several keys and attributes
  #   and eventually :default:
  #
  #   This list of sections and keys will be used to build the account files
  #   with the lorj Lorj::Core.setup function.
  #   Those data is accessible through the Lorj.defaults.get_meta,
  #   Lorj.defaults.get_meta_auto or Lorj.defaults.get_meta_section
  #
  #   please note that Lorj.defaults.get_meta uses the controller config layer
  #   to redefine defaults application meta data on controller needs.
  #   See BaseDefinition.define_data for details.
  #
  #   Ex:
  #
  #       # Use Lorj.defaults.data exceptionnaly
  #       Lorj.defaults.data.merge({sections:
  #                                  {:mysection:
  #                                    {key:
  #                                      {
  #                                       data1: 'test1',
  #                                       data2: 'test2'
  #                                      }
  #                                    }
  #                                  }
  #                                })
  #
  #       puts Lorj.defaults.get_meta(:mysection, :key)
  #       # => { data1: 'test1', data2: 'test2' }
  #       puts Lorj.defaults.get_meta(:mysection)
  #       # => {:key => { data1: 'test1', data2: 'test2' }}
  #       puts Lorj.defaults.get_meta_section(:key)
  #       # => :mysection
  #       puts Lorj.defaults.get_meta_auto(:key)
  #       # => { data1: 'test1', data2: 'test2' }
  #
  #   - :default: This section define updatable data available from config.yaml.
  #     But will never be added in an account file.
  #
  #     It contains a list of key and options.
  #
  #     - :<aKey>: Possible options
  #       - :desc: default description for that <aKey>
  #
  #   - :<aSectionName>: Name of the section which should contains a list
  #     - :<aKeyName>: Name of the key to setup.
  #       - :desc:
  #
  #         Description of that key, printed out at setup time. default: nil
  #
  #       - :explanation: Multi line explanation. In yaml, use |- to write
  #         multilines
  #
  #         Print a multiline explanation before ask the key value.
  #         ERB template enable. To get config data, type <%= config[...] %>
  #
  #       - :encrypted: true if this has to be encrypted with ~/.cache/forj/.key
  #
  #       - :readonly: true if this key is not modifiable by a simple.
  #         Lorj::Account::set function. false otherwise.
  #         Default: false
  #
  #       - :account_exclusive: true to limit the data to account config layer.
  #
  #       - :account: Set to true for setup to ask this data to the user during
  #         setup process. default: false
  #
  #       - :validate:          Ruby Regex to validate the end user input.
  #
  #         Ex: :validate: !ruby/regexp /^\w?\w*$/
  #
  #       - :default: Default value. Replace /:default/<data>
  #
  #       - :default_value: default value proposed to the user.
  #
  #       - :ask_step: Define the group number to attach the key to be asked.
  #
  #         By default, setup will determine the step, thanks to lorj object
  #         dependencies tree.
  #
  #         This number start at 0. Each step can be defined by
  #         /:setup/:ask_step/<steps> list. See :setup section.
  #
  #         ex:
  #
  #             :sections:
  #               :mysection:
  #                 :mydata:
  #                   :setup:
  #                     :ask_step: 2
  #
  #       - :ask_sort:          Number which represents the ask order in the
  #         step group. (See /:setup/:ask_step for details)
  #
  #       - :after:  <Data>     Name of the previous <Data> to ask before the
  #         current one.
  #
  #       - :depends_on: Identify :data type required to be set before the
  #         current one.
  #
  #       - :value_mapping: list of values to map as defined by the controller
  #
  #         - :controller: mapping for get controller value from process
  #           values
  #
  #           <value> : <map> value map equivalence. See data_value_mapping
  #           function
  #        - :process: mapping for get process value from controller values
  #
  #          <value> : <map> value map equivalence. See data_value_mapping
  #          function
  #
  #       - :list_values:       Provide capabililities to get a list and choose
  #         from.
  #
  #         - :query_type: It can be:
  #
  #           - *:query_call* to execute a query on flavor, query_params is
  #             empty for all.
  #             Data are extracted thanks to :values.
  #
  #           - *:process_call* to execute a process function to get the values.
  #             Data are extracted thanks to :values.
  #
  #           - *:controller_call* to execute a controller query. Data are
  #             extracted thanks to :values.
  #
  #           - *:values* to get list of fixed values from :values.
  #
  #         - :object:
  #
  #           - When used with :query_type == :query_call or :controller_call,
  #             :object is the object type symbol to query.
  #
  #           - When used with :query_type == :process_call, :object is the
  #             object used in the process.
  #
  #         - :query
  #
  #           Used with :query_type=:process_call. process function name to call
  #
  #         - :query_call:
  #
  #           Used with :query_type=:controller_call. Handler function to use.
  #           (query_e, create_e, ...)
  #           The function called must return an Array.
  #
  #           Used with :query_type=:process_call. Function name to call
  #
  #         - :query_params:
  #
  #           Used with :query_type=:query_call. Query hash defining filtering
  #           capabilities.
  #
  #           Used with :query_type=:process_call. hParams data passed to the
  #           process function.
  #
  #         - :values: List of fields to get values or list of fixed values.
  #
  #           Depends on query type.
  #
  #         - :validate:
  #
  #           if :list_strict, the value is limited to the possible values from
  #           the list
  #       - :pre_step_function: Process called before asking the data.
  #
  #         if it returns true, user interaction is cancelled.
  #
  #       - :post_step_function:Process called after asking the data.
  #
  #         if it returns false, the user is requested to re-enter a new value.
  #
  class MetaAppConfig < PRC::CoreConfig
    # Implements a 2 layers metadata config.
    #
    def initialize(data)
      config_layers = []

      # Application layer
      config_layers << define_meta_app_layer(data)

      # mapping section/keys layer
      config_layers << define_meta_map_layer

      # controller Config layer
      config_layers << define_meta_controller_layer

      initialize_layers(config_layers)

      build_section_mapping
    end

    # Redefine CoreConfig#layer_add to add mapping build
    #
    # See CoreConfig#layer_add for details
    def layer_add(options)
      p_layer_add(options)
      build_section_mapping
    end

    # Redefine CoreConfig#layer_remove to add mapping build
    #
    # See CoreConfig#layer_remove for details
    def layer_remove(options)
      p_layer_remove(options)
      build_section_mapping
    end

    # Loop on Config metadata
    #
    # * *Args*    :
    #   - +code+ : Block of code on `section`, `key`, `value`
    #
    # * *Returns* :
    #   - nothing
    def meta_each
      data = p_get(:keys => [:sections], :merge => true)

      if data.nil?
        PrcLib.warning('No model data definition found. Do you have a model'\
                       ' loaded?')
        return
      end

      data.each do |section, hValue|
        hValue.each do |key, value|
          yield section, key, value
        end
      end
    end

    # return section/data existence
    #
    # * *Args*    :
    #   - +section+ : Section to search for data.
    #   - +data+    : data name to check
    #
    # * *Returns* :
    #   - true/false
    def meta_exist?(section, key)
      p_exist?(:keys => [:sections, section, key])
    end

    # return 1st section/data existence.
    #
    # If a key name is found in several different section,
    #
    # auto_* functions, usually, will get the first section
    # from a key/sections mapping Array except if you provide
    # a '#' in the data name. (Ex: :'section1#key1')
    #
    # The list of sections for one key is build thanks to
    # build_section_mapping.
    #
    # * *Args*    :
    #   - +data+ : data name to check. Support 'section#data'.
    #
    # * *Returns* :
    #   - true/false
    def auto_meta_exist?(data)
      return nil unless data

      section, data = first_section(data)

      p_exist?(:keys => [:sections, section, data])
    end

    # return the 1st section name found of a data or the section discovered.
    #
    # * *Args*    :
    #   - +data+ : data name to search. It supports section#name.
    #
    # * *Returns* :
    #   - Array:
    #     - section name
    #     - key name
    def first_section(data)
      section, data = _detect_section(data, nil)
      return [section, data] unless section.nil? &&
                                    p_exist?(:keys => [:keys, data])

      arr = p_get(:keys => [:keys, data])
      return nil unless arr.is_a?(Array) && arr[0]
      [arr[0], data]
    end

    # return the list of sections name of a data.
    #
    # * *Args*    :
    #   - +data+ : Optional. data name to search.
    #     If no name given, returns all existing sections.
    #
    # * *Returns* :
    #   - Array of sections name.
    def sections(data = nil)
      return p_get(:keys => [:sections]).keys if data.nil?

      _, data = _detect_section(data, nil)
      return nil unless p_exist?(:keys => [:keys, data])
      p_get(:keys => [:keys, data])
    end

    # return the list of valid keys found in meta data.
    #
    # * *Args*    :
    #
    # * *Returns* :
    #   - Array of data name.
    def datas
      p_get(:keys => [:keys], :name => 'map').keys
    end

    # Get model setup/data options. It returns the list of options, against
    # layers, of all Hash options, cloned and merged.
    # Warning! This function assumes data found to be a Hash or Array.
    # To get the top layer data, use #setup_data(options)
    #
    # * *Args*    :
    #   - +options+ : Array of setup options tree
    #
    # * *Returns* :
    #   - Merged cloned options values.
    #   OR
    #   - nil if:
    #     - missing section and data name as parameter.
    #     - data was not found. defined in /:sections/<section>/<data
    #     - data found is not an Array or a Hash.
    #
    def setup_options(*options)
      keys = [:setup]
      keys.concat(options)
      p_get(:keys => keys, :merge => true)
    end

    # Get setup options. It returns the top layer data for options requested
    #
    # * *Args*    :
    #   - +options+ : Array of options tree.
    #
    # * *Returns* :
    #   - top layer data found.
    #   OR
    #   - nil if:
    #     - data was not found. defined in /:setup/options...
    #
    def setup_data(*options)
      keys = [:setup]
      keys.concat(options)
      p_get(:keys => keys, :merge => true)
    end

    # Get model section/data options. It returns the list of options, against
    # layers, of all Hash options, cloned and merged.
    #
    # * *Args*    :
    #   - +section+ : section name
    #   - +data+    : data name
    #   - +options+ : Optionnal. List of sub keys in tree to get data.
    #
    # * *Returns* :
    #   - Merged cloned data options values.
    #   OR
    #   - nil if:
    #     - missing section and data name as parameter.
    #     - data was not found. defined in /:sections/<section>/<data
    #     - data found is not an Array or a Hash.
    #
    def section_data(section, key, *options)
      return nil if section.nil? || key.nil?
      keys = [:sections]
      keys << section << key
      keys.concat(options)
      p_get(:keys => keys, :merge => true)
    end

    # Get model data options. Section name is determined by the associated
    # data name
    #
    # auto_* functions, usually, will get the first section
    # from a key/sections mapping Array. But it supports also 'Section#Name' to
    # determine the section to use instead of first one.
    #
    #
    # The list of sections for one key is build thanks to
    # build_section_mapping.
    #
    # * *Args*    :
    #   - +data+    : data name. Support 'Section#Name'
    #   - +options+ : Optionnal. List of sub keys in tree to get data.
    # * *Returns* :
    #   - data options values
    #   OR
    #   - nil if:
    #     - missing data name as parameter.
    #     - data was not found. defined in /:sections/<section>/<data
    #
    def auto_section_data(data, *options)
      return nil if data.nil?
      section, data = first_section(data)
      section_data(section, data, *options)
    end

    # layer setting function
    #
    # * *Args*
    #   - +type+    : Define the section type name.
    #     Predefined section type are :setup and :sections
    #   - +section+ : Symbol. Section name of the data to define.
    #   - +data+    : Symbol or Array of Symbols. Name of the data
    #   - +options+ : Hash. List of options
    #   - +layer+   : optional. Layer name to define. All layers are authorized,
    #     except 'app'/'keys'. 'app' is the protected application layer data.
    #     By default, the layer configured is 'controller'
    #
    # * *Returns*
    #   - The value set or nil
    #   OR
    #   - nil if type, section are not Symbol.
    #   - nil if data is not a Symbol or an Array of Symbol
    #   - nil if options is not a Hash
    #   - nil if layer is not a String or Nil.
    #   - nil if data is :keys or first element of the data is :keys.
    #     :keys is built internally to keep sections/keys mapping updated.
    #
    def set(type, section, data_keys, options, layer = 'controller')
      return nil unless check_par(type,      Symbol,
                                  section,   Symbol,
                                  data_keys, [Symbol, Array],
                                  options,   Hash,
                                  layer,     [String, NilClass])

      keys = build_keys(type, section, data_keys)

      # :keys is a special sections used internally.
      return nil if keys[1] == :keys

      update_map(section, keys[2]) if keys[0] == :sections

      layer = 'controller' if layer.nil? || %w(app map).include?(layer)

      p_set(:keys => keys, :name => layer, :value => options)
    end

    # layer setting function
    #
    # * *Args*
    #   - +type+    : :sections by default. Define the section type name.
    #   - +section+ : Symbol. Section name of the data to define.
    #   - +keys+    : 1 Symbol or more Symbols. Name of the data and options.
    #   - +options+ : Hash. List of options
    #
    # * *Returns*
    #   - The value set or nil
    #
    def []=(type, section, *keys, options)
      return nil if keys.length == 0
      set(type, section, keys, options)
    end

    # section/data removal function
    #
    # * *Args*
    #   - +section+ : Symbol. Section name of the data to define.
    #   - +data+    : Symbol or Array of Symbols. Name of the data
    #   - +layer+   : optional. Layer name to define. All layers are authorized,
    #     except 'app'. 'app' is the protected application layer data.
    #     By default, the layer configured is 'controller'
    # * *Returns*
    #   - The value set or nil
    #
    def del(type, section, data_keys, layer = 'controller')
      return nil unless check_par(type,      Symbol,
                                  section,   Symbol,
                                  data_keys, [Symbol, Array],
                                  layer,     [String, NilClass])

      keys = build_keys(type, section, data_keys)

      layer = 'controller' if layer.nil? || %w(app map).include?(layer)

      delete_map(section, keys[2]) if keys[0] == :sections

      p_del(:keys => keys, :name => layer)
    end

    # Controller data definition which will enhance data Application definition.
    # This function replace any controller definition.
    # To update/add options to an existing controller data, use #update_data.
    # You can also use [], []=, etc... provided by parent class.
    # This will work only if the 'controller' is the highest layer.
    #
    # * *Args*:
    #   - +section+ : Symbol. Section name of the data to define.
    #   - +data+    : Symbol. Name of the data
    #   - +options+ : Hash. List of options
    #   - +layer+   : optional. Layer name to define. All layers are authorized,
    #     except 'app'. 'app' is the protected application layer data.
    #     By default, the layer configured is 'controller'
    def define_controller_data(section, data, options, layer = 'controller')
      return nil unless check_par(section, Symbol,
                                  data,    Symbol,
                                  options, Hash,
                                  layer,  [String, NilClass])

      keys = [:sections]
      keys << section << data

      layer = 'controller' if layer.nil? || layer == 'app'

      update_map(section, data)
      p_set(:keys => keys, :name => layer, :value => options)
    end

    # Controller data definition which will enhance data Application definition.
    # This function replace any controller definition.
    # To replace or redefine options to an existing controller data, use
    # #define_data.
    # You can also use [], []=, etc... provided by parent class.
    # This will work only if the 'controller' is the highest layer.
    #
    # * *Args*:
    #   - +section+ : Symbol. Section name of the data to define.
    #   - +data+    : Symbol. Name of the data
    #   - +options+ : Hash. List of options to add or update.
    #   - +layer+   : optional. Layer name to define. All layers are authorized,
    #     except 'app'. 'app' is the protected application layer data.
    #     By default, the layer configured is 'controller'
    def update_controller_data(section, data, options, layer = 'controller')
      return nil unless check_par(section, Symbol,
                                  data,    Symbol,
                                  options, Hash,
                                  layer,  [String, NilClass])

      keys = [:sections, section, data]
      value = p_get(:keys => keys, :name => 'controller')

      layer = 'controller' if layer.nil? || layer == 'app'

      p_set(:keys => keys, :name => layer, :value => value.merge(options))
    end
  end

  module_function

  # Lorj::defaults exposes the application defaults and Config Lorj metadata.
  #
  # You can set the Application layer of meta data, replacing load from
  # defaults.yaml
  #
  # * *Args*
  #   - data : Optionnal initialized Application layer meta data.
  def data(data = nil)
    return @metadata unless @metadata.nil?

    unless data.is_a?(Hash)
      data = {}
      # TODO: Replace load from defaults.yaml to a dedicated meta file def.
      if Lorj.defaults.data.key?(:setup)
        data[:setup] = Lorj.defaults.data[:setup]
        Lorj.defaults.data.delete(:setup)
      end
      if Lorj.defaults.data.key?(:sections)
        data[:sections] = Lorj.defaults.data[:sections]
        Lorj.defaults.data.delete(:sections)
      end
    end
    @metadata = Lorj::MetaAppConfig.new data

    @metadata
  end
end
