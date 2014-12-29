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
  # This class is Base config system of lorj.
  #
  # It implements basic config features:
  # * erase        - To cleanup all data in self config
  # * []           - To get a value for a key or tree of keys
  # * []=          - To set a value for a key in the tree.
  # * exist?       - To check the existence of a value from a key
  # * del          - To delete a key tree.
  # * save         - To save all data in a yaml file
  # * load         - To load data from a yaml file
  # * data_options - To influence on how exist?, [], []=, load and save will
  #                  behave
  #
  # Config Data are managed as Hash of Hashes.
  # It uses actively Hash.rh_* functions. See rh.rb.
  class BaseConfig
    attr_reader :data
    attr_reader :filename

    # initialize BaseConfig
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    #
    # * *Returns*
    #   - boolean : true if the key path was found
    #
    # ex:
    # value = CoreConfig.New({ :test => {:titi => 'found'}})
    # # => creates a CoreConfig with this Hash of Hash
    def initialize(value = nil)
      @data = {}
      @data = value if value.is_a?(Hash)
      @data_options = {} # Options for exist?/set/get/load/save
    end

    # data_options set data options used by exist?, get, set, load and save
    # functions.
    #
    # CoreConfig class type, call data_options to set options, before calling
    # functions: exist?, get, set, load and save.
    #
    # Currently, data_options implements:
    # - :data_readonly : The data cannot be updated. set will not update
    #                    the value.
    # - :file_readonly : The file used to load data cannot be updated.
    #                    save will not update the file.
    #
    # The child class can superseed or replace data options with their own
    # options.
    # Ex: If your child class want to introduce notion of sections,
    # you can define the following with get:
    # # by default, section name to use by get/set is :default
    # def data_options(options = {:section => :default})
    #   _data_options(options)
    # end
    #
    # def [](*keys)
    #   _get(@data_options[:section], *keys)
    # end
    #
    # def []=(*keys, value)
    #   _set(@data_options[:section], *keys, value)
    # end
    #
    # end
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    #
    # * *Returns*
    #   - boolean : true if the key path was found
    #
    # ex:
    # { :test => {:titi => 'found'}}
    def data_options(options = nil)
      _data_options options
    end

    # exist?
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    #
    # * *Returns*
    #   - boolean : true if the key path was found
    #
    # ex:
    # { :test => {:titi => 'found'}}
    def exist?(*keys)
      _exist?(*keys)
    end

    # Erase function
    #
    # * *Args*
    #
    # * *Returns*
    #   -
    #
    def erase
      @data = {}
    end

    # Get function
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    #
    # * *Returns*
    #   -
    #
    def [](*keys)
      _get(*keys)
    end

    # Set function
    #
    # * *Args*
    #   - +keys+ : set a value in the Array of key path.
    #
    # * *Returns*
    #   - The value set or nil
    #
    # ex:
    # value = CoreConfig.New
    #
    # value[:level1, :level2] = 'value'
    # # => {:level1 => {:level2 => 'value'}}

    def del(*keys)
      _del(*keys)
    end
    # Set function
    #
    # * *Args*
    #   - +keys+ : set a value in the Array of key path.
    #
    # * *Returns*
    #   - The value set or nil
    #
    # ex:
    # value = CoreConfig.New
    #
    # value[:level1, :level2] = 'value'
    # # => {:level1 => {:level2 => 'value'}}
    def []=(*keys, value)
      _set(*keys, value)
    end

    # Load from a file
    #
    # * *Args*    :
    #   - +filename+ : file name to load. This file name will become the default
    #                  file name to use next time.
    # * *Returns* :
    #   - true if loaded.
    # * *Raises* :
    #   - ++ ->
    def load(filename = nil)
      _load(filename)
    end

    # Save to a file
    #
    # * *Args*    :
    #   - +filename+ : file name to save. This file name will become the default
    #                  file name to use next time.
    # * *Returns* :
    #   - boolean if saved or not. true = saved.
    def save(filename = nil)
      _save(filename)
    end

    # transform keys from string to symbol until deep level. Default is 1.
    #
    # * *Args*    :
    #   - +level+ : Default 1. level to transform
    #
    # * *Returns* :
    #   - it self, with config updated.
    def rh_key_to_symbol(level = 1)
      data.rh_key_to_symbol level
    end

    # Check the need to transform keys from string to symbol until deep level.
    # Default is 1.
    #
    # * *Args*    :
    #   - +level+ : Default 1: levels to verify
    #
    # * *Returns* :
    #   - true if need to be updated.
    #
    def rh_key_to_symbol?(level = 1)
      data.rh_key_to_symbol? level
    end

    # Update default filename.
    #
    # * *Args*    :
    #   - +filename+ : default file name to use.
    # * *Returns* :
    #   - filename
    def filename=(filename)
      @filename = File.expand_path(filename) unless filename.nil?
    end

    def to_s
      msg = format("File : %s\n", @filename)
      msg += data.to_yaml
      msg
    end

    private

    def _data_options(options = nil)
      @data_options = options unless options.nil?
      @data_options
    end

    def _exist?(*keys)
      return nil if keys.length == 0

      (@data.rh_exist?(*keys))
    end

    def _get(*keys)
      return nil if keys.length == 0

      @data.rh_get(*keys)
    end

    def _del(*keys)
      return nil if keys.length == 0

      @data.rh_del(*keys)
    end

    def _set(*keys, value)
      return nil if keys.length == 0
      return _get(*keys) if @data_options[:data_readonly]

      @data.rh_set(value, keys)
    end

    def _load(file = nil)
      self.filename = file unless file.nil?

      fail 'Config filename not set.' if @filename.nil?

      @data = YAML.load_file(File.expand_path(@filename))
      true
    end

    def _save(file = nil)
      return false if @data_options[:file_readonly]
      self.filename = file unless file.nil?

      fail 'Config filename not set.' if @filename.nil?

      File.open(@filename, 'w+') { |out| YAML.dump(@data, out) }
      true
    end
  end
end
