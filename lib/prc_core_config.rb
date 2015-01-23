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

require 'yaml'

module PRC
  # This class implement The CoreConfig system of lorj.
  #
  # * You can use it directly. See PRC::CoreConfig.initialize.
  # * you can enhance it with class heritage feature.
  #   See Class child discussion later in this class documentation.
  #
  # It implements several layer of CoreConfig object type
  # to provide several source of data in layers priorities.
  # Ex: RunTime => LocalConfig => AppDefault
  #
  # It implements config features:
  # * []           - To get a value for a key or tree of keys
  # * []=          - To set a Config value in the highest config.
  # * del          - To delete key or simply nil the value in highest config.
  # * exist?       - To check the existence of a value in config levels.
  # * where?       - To get the name of the level where the value was found.
  # * file         - To get or set a filename to a config layer.
  # * save         - To save one config data level in a yaml file.
  # * load         - To load data from a yaml file to a config data layer.
  #
  # It implements Config Layer settings at init time.
  # See initialize(config_layers)
  #
  # For details about Config data management, See BaseConfig.
  #
  # Child Class:
  # ------------
  #
  # This class can be enhanced with any kind of additional functionality.
  #
  # You can redefine following functions:
  # exist?, [], []=, file, save, load, del.
  #
  # * Your child class can limit or re-organize config layers to query.
  #   Use :indexes or :names options to select which layer you want to query
  #   and call the core function.
  #
  #   Ex: If you have 4 config levels and want to limit to 2 top ones
  #
  #     def [](*keys)
  #       options = { keys: keys}
  #       options[:indexes] = [0, 1]
  #       _get(options)
  #     end
  #
  #   Ex: If you have 4 config levels and want to limit to 2 names.
  #
  #     def [](*keys)
  #       options = { keys: keys}
  #       options[:names] = ['local', 'default_app']
  #       _get(options)
  #    end
  #
  # * Your child class can force some levels options.
  #   Use :data_options to define each of them
  #
  #   Ex: If your class has 4 levels. /:name is not updatable for level 1.
  #
  #     def [](*keys)
  #       options = { keys: keys }
  #       # The following defines data_readonly for the config level 1
  #       if keys[0] == :name
  #          options[:data_options] = [nil, {data_readonly: true}]
  #       end
  #       _get(options)
  #    end
  #
  #
  #
  #
  #
  class CoreConfig
    # exist?
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    #
    # * *Returns*
    #   - boolean : true if the key path was found
    #
    # Class child:
    # A class child can redefine this function to increase default
    # features.
    #
    def exist?(*keys)
      _exist?(:keys => keys)
    end

    # where?
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    #
    # * *Returns*
    #   - boolean : true if the key path was found
    #
    def where?(*keys)
      _where?(:keys => keys)
    end

    # Get function
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    #
    # * *Returns*
    #   value found or nil.
    #
    def [](*keys)
      _get(:keys => keys)
    end

    # Set function
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    # * *Returns*
    #   - The value set or nil
    #
    # ex:
    # value = CoreConfig.New
    #
    # value[:level1, :level2] = 'value'
    # # => {:level1 => {:level2 => 'value'}}
    def []=(*keys, value)
      _set(:keys => keys, :value => value)
    end

    # Del function
    #
    # * *Args*
    #   - +keys+ : Array of key path to found and delete the last element.
    # * *Returns*
    #   - The Hash updated.
    #
    # ex:
    # value = CoreConfig.New
    #
    # value[:level1, :level2] = 'value'
    # # => {:level1 => {:level2 => 'value'}}
    # {:level1 => {:level2 => 'value'}}.del(:level1, :level2)
    # # => {:level1 => {}}
    def del(*keys)
      _del(:keys => keys)
    end

    # Load from a file to the highest layer or a specific layer.
    #
    # * *Args*    :
    # - +options+ : Supported options for load
    #   - +:name+ : layer to get data.
    #   - +:index+: layer index to get data.
    #               If neither :name or :index is set, set will use the highest
    #               layer
    #
    # * *Returns* :
    #   -
    # * *Raises* :
    #   - ++ ->
    def load(options = {})
      _load(options)
    end

    # Save to a file
    #
    # * *Args*    :
    # - +options+ : Supported options for save
    #   - +:name+ : layer to get data.
    #   - +:index+: layer index to get data.
    #               If neither :name or :index is set, set will use the highest
    #               layer
    #
    # * *Returns* :
    #   -
    def save(options = {})
      _save(options)
    end

    # Get/Set the file name.
    #
    # * *Args*
    # - +:file+   : file name for the layer identified.
    # - +options+ : Supported options for save
    #   - +:index+: layer index to get data.
    #   - +:name+ : layer to get data.
    #               If neither :name or :index is set, nil is returned.
    #
    # * *Returns*
    #   - The file name.
    def file(filename = nil, options = {})
      _file(filename, options)
    end

    def layers
      result = []
      @config_layers.each { | layer | result << layer[:name] }
      result
    end

    def to_s
      data = "Configs list ordered:\n"
      @config_layers.each do | layer |
        data += format("---- Config : %s ----\noptions: ", layer[:name])

        if layer[:set]
          data += 'data RW '
        else
          data += 'data RO '
        end
        data += format(", %s\n", to_s_file_opts(layer))

        data += format("%s\n", layer[:config].to_s)
      end
      data
    end

    private

    def to_s_file_opts(layer)
      data = 'File '
      if layer[:load] &&
         if layer[:save]
           data += 'RW'
         else
           data += 'RO'
         end
        data += ', filename updatable' if layer[:file_set]
      else
        data += 'None'
      end
      data
    end

    def _file_common_options_get(options)
      options = {} if options.nil?
      options[:names] = [options[:name]] if options.key?(:name)
      options[:indexes] = [options[:index]] if options.key?(:index)

      _common_options_get(options)
    end
  end

  # Internal core functions
  class CoreConfig
    # *****************************************************

    private

    # *****************************************************

    # _file? Core file function called by default by file.
    #
    # This function can be used by child class to set one layer file name
    #
    # * *Args*
    # - +options+ : Hash parameters
    #   - +:name+  : layer to get data.
    #   - +:index+ : Array layer indexes to get data.
    #                If neither :name or :index is set, level 0 is used.
    #
    # * *Returns*
    #   - filename : if updated.
    #   OR
    #   - false    : if not updated.
    #   OR
    #   - nil      : If something went wrong.
    #
    # ex:
    # { :test => {:titi => 'found'}}
    def _file(filename = nil, options = {})
      parameters = _file_common_options_get(options)

      return nil if parameters.nil?

      config_layers = parameters[0][0]

      layer = config_layers[0]

      return layer[:config].filename unless filename.is_a?(String)

      return false if _filename_unsetable(layer)

      layer[:config].filename = filename
      filename
    end

    def _filename_unsetable(layer)
      return true if !layer[:load] && !layer[:save]

      !layer[:config].filename.nil? && !layer[:file_set]
    end

    # _exist? Core exist function called by default by exist?.
    #
    # * *Args*
    # - +options+ : Hash parameters
    #   - +:keys+      : key tree to check existence in config layers
    #   - +:names+     : layer to get data.
    #   - +:indexes+   : Array layer indexes to get data.
    #                    If neither :name or :index is set, get will search data
    #                    per layers priority.
    #   - +:data_opts+ : Array or Hash. Define data options per layer.
    #
    # * *Returns*
    #   - boolean : true if the key path was found
    #
    # ex:
    # { :test => {:titi => 'found'}}
    def _exist?(options)
      parameters = _common_options_get(options, [:keys])
      return nil if parameters.nil?

      config_layers, data_opts, keys = parameters[0]

      return nil if keys.length == 0 || keys[0].nil? || config_layers[0].nil?

      config_layers.each_index do | index |
        config = @config_layers[index][:config]

        data_options = options.clone
        data_options.delete_if do |key|
          [:keys, :names, :indexes, :name, :index].include?(key)
        end
        data_options.merge!(data_opts[index])

        config.data_options(data_options)
        return true if config.exist?(*keys)
      end
      false
    end

    # _where? called by default by where
    #
    # - +options+ : Hash parameters
    #   - +:keys+      : key tree to check existence in config layers
    #   - +:names+     : layer to get data.
    #   - +:indexes+   : Array layer indexes to get data.
    #                    If neither :name or :index is set, get will search data
    #                    per layers priority.
    #   - +:data_opts+ : Array or Hash. Define data options per layer.
    #
    # * *Returns*
    #   - array of config name : list of first layers where the key was found.
    #   OR
    #   - nil can be returned for several reasons:
    #     - keys is not an array
    #     - keys array is empty.

    #
    # ex:
    # { :test => {:titi => 'found'}}
    def _where?(options)
      parameters = _common_options_get(options, [:keys])
      return nil if parameters.nil?

      config_layers, data_opts, keys = parameters[0]

      return nil if keys.length == 0 || keys[0].nil? || config_layers[0].nil?

      _do_where?(config_layers, keys, options, data_opts)
    end

    def _do_where?(config_layers, keys, options, data_opts)
      layer_indexes = []
      config_layers.each_index do | index |
        config = config_layers[index][:config]

        data_options = options.clone
        data_options.delete_if do |key|
          [:keys, :names, :indexes, :name, :index].include?(key)
        end
        data_options.merge!(data_opts[index]) if data_opts[index].is_a?(Hash)

        config.data_options(data_options)
        layer_indexes << config_layers[index][:name] if config.exist?(keys)
      end
      return layer_indexes if layer_indexes.length > 0
      false
    end
    # Get function called by default by []
    #
    # * *Args*
    # - +options+ : Hash of how to get the data
    #   - +:keys+      : Array of key path to found
    #   - +:names+     : layer to get data.
    #   - +:indexes+   : Array layer indexes to get data.
    #                    If neither :name or :index is set, get will search data
    #                    per layers priority.
    #   - +:data_opts+ : Array or Hash. Define data options per layer.
    #
    # * *Returns*
    #   value found or nil.
    #     nil can be returned for several reasons:
    #     - keys is not an array
    #     - keys array is empty.
    #
    def _get(options)
      parameters = _common_options_get(options, [:keys])
      return nil if parameters.nil?

      config_layers, data_opts, keys = parameters[0]

      return nil if keys.length == 0 || keys[0].nil? || config_layers[0].nil?

      config_layers.each_index do | layer_index |
        layer = config_layers[layer_index]

        data_options = options.clone
        data_options.delete_if do |key|
          [:keys, :names, :indexes, :name, :index].include?(key)
        end
        data_options = data_options.merge!(data_opts[layer_index])

        layer[:config].data_options(data_options)
        return layer[:config][*keys] if layer[:config].exist?(*keys)
      end
      nil
    end

    # Set function called by default by []=
    #
    # * *Args*
    # - +options+ : Hash of how to get the data
    #   - +:value+: Value to set
    #   - +:keys+ : Array of key path to found
    #   - +:name+ : layer to get data.
    #   - +:index+: layer index to get data.
    #               If neither :name or :index is set, set will use the highest
    #               layer
    #   - +:data_opts+ : Array or Hash. Define data options per layer.
    #
    # * *Returns*
    #   - The value set.
    #   OR
    #   - nil can be returned for several reasons:
    #     - layer options :set is false
    #     - options defines a :data_readonly to true.
    #     - value is nil
    #     - keys is not an array
    #     - keys array is empty.
    #
    # ex:
    # value = CoreConfig.New
    #
    # value[:level1, :level2] = 'value'
    # # => {:level1 => {:level2 => 'value'}}
    def _set(options)
      parameters = _common_options_get(options, [:keys, :value])
      return nil if parameters.nil?

      config_layers, data_opts, keys, value = parameters[0]

      # get data options for level 0
      data_options = options.clone.merge!(data_opts[0])

      return nil if keys.length == 0 || keys[0].nil? || config_layers[0].nil?

      data_options.delete_if do |key|
        [:keys, :names, :indexes, :name, :index, :value].include?(key)
      end

      return nil unless @config_layers[0][:set]

      config_layer = config_layers[0][:config]
      config_layer.data_options(data_options)
      config_layer[keys] = value
    end

    # Del function called by default by del
    #
    # * *Args*
    # - +options+      : Hash of how to get the data
    #   - +:keys+      : Array of key path to found
    #   - +:name+      : layer to get data.
    #   - +:index+     : layer index to get data.
    #                    If neither :name or :index is set, set will use the
    #                    highest layer
    #   - +:data_opts+ : Array or Hash. Define data options per layer.
    #
    # * *Returns*
    #   - The value attached to the key deleted.
    #   OR
    #   - nil can be returned for several reasons:
    #     - value is nil
    #     - keys is not an array
    #     - keys array is empty.
    #
    # ex:
    # value = CoreConfig.New
    #
    # value[:level1, :level2] = 'value'
    # # => {:level1 => {:level2 => 'value'}}
    #
    # value.del(:keys => [:level1, :level2])
    # # => {:level1 => {}}
    def _del(options)
      parameters = _common_options_get(options, [:keys])
      return nil if parameters.nil?

      config_layers, data_opts, keys = parameters[0]

      # get data options for level 0
      data_options = options.clone.merge!(data_opts[0])

      return nil if keys.length == 0

      data_options.delete_if do |key|
        [:keys, :names, :indexes, :name, :index].include?(key)
      end

      return nil unless @config_layers[0][:set]

      config_layers[0][:config].data_options(data_options)
      config_layers[0][:config].del(keys)
    end

    # Load from a file called by default by load.
    #
    # * *Args*    :
    # - +options+   : Supported options for load
    #   - +:name+  : layer name to get data.
    #   - +:index+ : layer index to get data.
    #                If neither :name or :index is set, set will use the highest
    #                layer.
    #
    # * *Returns* :
    #   - true : loaded
    #   - false: not loaded. There are several possible reasons:
    #     - input/output issue (normally raised)
    #     - layer option :load is false.
    def _load(options = {})
      options = {} if options.nil?
      options[:names] = [options[:name]] if options.key?(:name)
      options[:indexes] = [options[:index]] if options.key?(:index)

      parameters = _file_common_options_get(options)
      return nil if parameters.nil?

      config_layers = parameters[0][0]

      return nil unless config_layers[0][:load]

      config_layers[0][:config].load
    end

    # Save to a file called by default by save
    #
    # * *Args*    :
    # - +options+ : Supported options for save
    #   - +:name+ : layer to get data.
    #   - +:index+: layer index to get data.
    #               If neither :name or :index is set, set will use the highest
    #               layer
    #
    # * *Returns* :
    #   - true : saved
    #   - false: not saved. There are several possible reasons:
    #     - options defines a :file_readonly to true.
    #     - input/output issue (normally raised)
    #     - layer option :save is false.
    def _save(options = {})
      options[:names] = [options[:name]] if options.key?(:name)
      options[:indexes] = [options[:index]] if options.key?(:index)

      parameters = _file_common_options_get(options)
      return nil if parameters.nil?

      config_layers = parameters[0][0]

      return nil unless config_layers[0][:save]

      config_layers[0][:config].save
    end
  end

  # Internal functions
  class CoreConfig
    # initialize CoreConfig
    #
    # * *Args*
    # - +config_layers+ : Array config layers configuration.
    #   Each layer options have those options:
    #   - :config   : optional. See `Defining Config layer instance` for details
    #   - :name     : required. String. Name of the config layer.
    #                 Warning! unique name on layers is no tested.
    #   - :set      : boolean. True if authorized. Default is True.
    #   - :load     : boolean. True if authorized. Default is False.
    #   - :save     : boolean. True if authorized. Default is False.
    #   - :file_set : boolean. True if authorized to update a filename.
    #                 Default is False.
    #
    # each layers can defines some options for the layer to behave differently
    # CoreConfig call a layer data_options to set some options, before
    # exist?, get or [], set or []=, save and load functions.
    # See BaseConfig::data_options for predefined options.
    #
    # Core config provides some private additionnal functions for
    # child class functions:
    #   - _set_data_options(layers, options) - To set data_options on one or
    #                                          more config layers
    #   - _get(options)                      - core get function
    #   - _set(options)                      - core set function
    #   - _save(options)                     - core save function
    #   - _load(options)                     - core load function
    #
    # if +config_layers+ is not provided, CoreConfig will instanciate a runtime
    # like system:
    # config = CoreConfig.New
    # # is equivalent as :
    # config_layers = [{name: 'runtime',
    #                   config: PRC::BaseConfig.new, set: true}]
    # config = CoreConfig.New(config_layers)
    #
    # Defining Config layer instance:
    # -------------------------------
    #
    # :config value requires it to be of type 'BaseConfig'
    # By default, it uses `:config => PRC::BaseConfig.new`
    # Instead, you can set:
    # * directly BaseConfig. `:config => PRC::BaseConfig.new`
    # * a child based on BaseConfig. `:config => MyConfig.new`
    # * some predefined enhanced BaseConfig:
    #   * PRC::SectionConfig. See prc_section_config.rb.
    #     `:config => PRC::SectionConfig.new`
    #
    def initialize(config_layers = nil)
      if config_layers.nil?
        config_layers = []
        config_layers << CoreConfig.define_layer
      end
      initialize_layers(config_layers)
    end

    def self.define_layer(options = {})
      attributes = [:name, :config, :set, :load, :save, :file_set]

      layer = {}

      attributes.each do | attribute |
        if options.key?(attribute)
          layer[attribute] = options[attribute]
        else
          layer[attribute] = case attribute
                             when :name
                               'runtime'
                             when :config
                               PRC::BaseConfig.new
                             when :set
                               true
                             else
                               false
                             end
        end
      end
      layer
    end

    # Function to initialize Config layers.
    #
    # *Args*
    # - +config_layers+ : Array of config layers.
    #                     First layer is the deepest config object.
    #                     last layer is the first config object queried.
    #
    # Ex: If we define 2 config layer:
    # local = PRC::BaseConfig.new(:test => :found_local)
    # runtime = PRC::BaseConfig.new(:test => :found_runtime)
    # layers = []
    # layers << CoreConfig.define_layer(name: 'local', config: local )
    # layers << CoreConfig.define_layer(name: 'runtime', config: runtime )
    # config = PRC::CoreConfig.new
    # config.initialize_layers(layers)
    #
    # p config[:test] # => :found_runtime
    #
    # config[:test] = "where?"
    # p config.where?(:test) # => ["runtime", "local"]
    #
    # config.del(:test)
    # p config.where?(:test) # => ["local"]
    # p config[:test] # => :found_local
    #
    # config[:test] = "and now?"
    # p config.where?(:test) # => ["runtime", "local"]
    #
    def initialize_layers(config_layers = nil)
      @config_layers = []

      config_layers.each do | layer |
        next unless layer.is_a?(Hash) && layer.key?(:config) &&
                    layer[:config].is_a?(BaseConfig)
        next unless layer[:name].is_a?(String)
        @config_layers << initialize_layer(layer)
      end
      @config_layers.reverse!
    end

    def initialize_layer(layer)
      newlayer = { :config => layer[:config], :name => layer[:name] }
      newlayer[:set] = layer[:set].boolean? ? layer[:set] : true
      newlayer[:load] = layer[:load].boolean? ? layer[:load] : false
      newlayer[:save] = layer[:save].boolean? ? layer[:save] : false
      newlayer[:file_set] = layer[:file_set].boolean? ? layer[:file_set] : false
      newlayer
    end

    # layer_indexes function
    #
    # * *Args*
    # - +:name+ : layer to identify.
    #
    # * *Returns*
    #   first index found or nil.
    #
    def _layer_indexes(names)
      names = [names] if names.is_a?(String)
      return nil unless names.is_a?(Array)

      layers = []

      names.each do | name |
        index = layer_index(name)
        layers << index unless index.nil?
      end
      return layers if layers.length > 0
      nil
    end

    # layer_index function
    #
    # * *Args*
    # - +:name+ : layer to identify.
    #
    # * *Returns*
    #   first index found or nil.
    #
    def layer_index(name)
      return nil unless name.is_a?(String)
      return nil if @config_layers.nil?

      @config_layers.each_index do | index |
        return index if @config_layers[index][:name] == name
      end
      nil
    end

    # Check and returns values of options required and optionnal.
    #
    # * *Args*
    # - +options+   : options to extract information.
    # - +required+  : Array of required option keys.
    # - +optionnal+ : Array of optionnal option keys.
    #
    # * *Returns*
    # - nil if at least one required keys doesn't exist
    # - Array of combined required and optionnql values.
    #
    def _valid_options(options, required, optionnal = [])
      return nil unless options.is_a?(Hash)
      return nil unless required.is_a?(Array)
      optionnal = [] unless optionnal.is_a?(Array)

      result = [[], []]

      required.each do | key |
        return nil unless options.key?(key)
        result[0] << options[key]
      end

      optionnal.each { | key | result[1] << options[key] }

      result
    end

    # Take care of keys, indexes and names.
    # if names if found, it will replace indexes.
    def _common_options_get(options, required = [], optionnal = [])
      return nil unless options.is_a?(Hash)
      required = [] unless required.is_a?(Array)
      optionnal = [] unless optionnal.is_a?(Array)

      result = _valid_options(options, required,
                              [:indexes, :names,
                               :data_options].concat(optionnal))
      # result Array is structured as:
      # required [0] => [...]
      # optional [1] => [indexes, names, data_options, ...]

      # Following eliminates the optional :names (1) element
      _set_indexes result
      # required [0] => [...]
      # optional [1] => [indexes, data_options, ...]
      return nil if _keys_data_missing(options, required, result)

      # Following eliminates the optional :indexes (0) element
      # But add it as required in the Array, at pos 0
      _build_layers(result)
      # required [0] => [layers, ...]
      # optional [1] => [data_options, ...]

      # following eliminates the optional :data_options (0) element
      # But data_options is added in required Array, at pos 1.
      _set_data_opts(result)
      # required [0] => [layers, data_options, ...]
      # optional [1] => [...]

      result
    end

    def _keys_data_missing(options, required, result)
      return false unless required[0] == :keys

      return true unless options.key?(:keys)
      return true unless result[0][0].is_a?(Array)
      return true if result[0][0].length == 0
      false
    end

    # Setting indexes from names or indexes.
    def _set_indexes(result)
      names_indexes = _layer_indexes(result[1][1])
      # replaced indexes by names indexes if exists.
      result[1][0] = names_indexes if names_indexes
      result[1].delete_at(1)
    end

    def _set_data_opts(result)
      data_opts = []

      result[0][0].each_index do | layer_index |
        data_options = result[1][0][layer_index] if result[1][0].is_a?(Array)
        data_options = {} unless data_options.is_a?(Hash)
        data_opts << data_options
      end
      result[0].insert(1, data_opts)

      # And removing the optionnal :data_options
      result[1].delete_at(0)
    end

    def _build_layers(result)
      # Setting layers at required [0]
      if result[1][0].nil? || result[1][0].length == 0
        config_layers = @config_layers
      else
        config_layers = []
        result[1][0].each do | index |
          config_layers << @config_layers[index] if index.is_a?(Fixnum)
        end
        config_layers = @config_layers if config_layers.length == 0
      end
      result[0].insert(0, config_layers)

      # And removing the optionnal indexes
      result[1].delete_at(0)
      result
    end
  end
end
