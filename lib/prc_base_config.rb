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
  # * #erase        - To cleanup all data in self config
  # * #[]           - To get a value for a key or tree of keys
  # * #[]=          - To set a value for a key in the tree.
  # * #exist?       - To check the existence of a value from a key
  # * #del          - To delete a key tree.
  # * #save         - To save all data in a yaml file
  # * #load         - To load data from a yaml file
  # * #data_options - To influence on how exist?, [], []=, load and save will
  #   behave
  #
  # Config Data are managed as Hash of Hashes.
  # It uses actively Hash.rh_* functions. See rh.rb.
  class BaseConfig
    # internal Hash data of this config.
    # Do not use it except if you know what you are doing.
    attr_reader :data

    # * *set*: set the config file name. It accepts relative or absolute path to
    #   the file.
    # * *get*: get the config file name used by #load and #save.
    attr_accessor :filename

    # config layer version
    attr_accessor :version

    # config layer latest version
    attr_reader :latest_version

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
    def initialize(value = nil, latest_version = nil)
      @data = {}
      @data = value if value.is_a?(Hash)
      @data_options = {} # Options for exist?/set/get/load/save
      @latest_version = latest_version
      @version = latest_version
    end

    # data_options set data options used by exist?, get, set, load and save
    # functions.
    #
    # CoreConfig class type, call data_options to set options, before calling
    # functions: exist?, get, set, load and save.
    #
    # Currently, data_options implements:
    # - :data_readonly : The data cannot be updated. set will not update
    #   the value.
    # - :file_readonly : The file used to load data cannot be updated.
    #   save will not update the file.
    #
    # The child class can superseed or replace data options with their own
    # options.
    # Ex: If your child class want to introduce notion of sections,
    # you can define the following with get:
    #
    #    class MySection < PRC::BaseConfig
    #      # by default, section name to use by get/set is :default
    #      def data_options(options = {:section => :default})
    #        p_data_options(options)
    #      end
    #
    #      def [](*keys)
    #        p_get(@data_options[:section], *keys)
    #      end
    #
    #      def []=(*keys, value)
    #        p_set(@data_options[:section], *keys, value)
    #      end
    #    end
    #
    # * *Args*
    #   - +keys+ : Array of key path to found
    #
    # * *Returns*
    #   - boolean : true if the key path was found
    def data_options(options = nil)
      p_data_options options
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
      p_exist?(*keys)
    end

    # Erase the data in the object. internal version is cleared as well.
    #
    # * *Returns*
    #   - Hash : {}.
    #
    def erase
      @version = @latest_version
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
      p_get(*keys)
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
      p_del(*keys)
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
    #    value = CoreConfig.New
    #
    #    value[:level1, :level2] = 'value'
    #    # => {:level1 => {:level2 => 'value'}}
    def []=(*keys, value)
      p_set(*keys, value)
    end

    # Load from a file
    #
    # * *Args*    :
    #   - +filename+ : file name to load. This file name will become the default
    #     file name to use next time.
    # * *Returns* :
    #   - true if loaded.
    # * *Raises* :
    #   - ++ ->
    def load(filename = nil)
      p_load(filename)
    end

    # Save to a file
    #
    # * *Args*    :
    #   - +filename+ : file name to save. This file name will become the default
    #                  file name to use next time.
    # * *Returns* :
    #   - boolean if saved or not. true = saved.
    def save(filename = nil)
      p_save(filename)
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

    # Redefine the file name attribute set.
    #
    # * *Args*    :
    #   - +filename+ : default file name to use.
    # * *Returns* :
    #   - filename
    def filename=(filename) #:nodoc:
      @filename = File.expand_path(filename) unless filename.nil?
    end

    # Print a representation of the Layer data
    def to_s
      msg = format("File : %s\n", @filename)
      msg += data.to_yaml
      msg
    end

    def latest_version?
      (@version == @latest_version)
    end

    private

    def p_data_options(options = nil)
      @data_options = options unless options.nil?
      @data_options
    end

    def p_exist?(*keys)
      return nil if keys.length == 0

      (@data.rh_exist?(*keys))
    end

    def p_get(*keys)
      return nil if keys.length == 0

      @data.rh_get(*keys)
    end

    def p_del(*keys)
      return nil if keys.length == 0

      @data.rh_del(*keys)
    end

    def p_set(*keys, value)
      return nil if keys.length == 0
      return p_get(*keys) if @data_options[:data_readonly]

      @data.rh_set(value, keys)
    end

    def p_load(file = nil)
      self.filename = file unless file.nil?

      fail 'Config filename not set.' if @filename.nil?

      @data = YAML.load_file(File.expand_path(@filename))

      if @data.key?(:file_version)
        @version = @data[:file_version]
        @data.delete(:file_version)
      end
      true
    end

    def p_save(file = nil)
      return false if @data_options[:file_readonly]
      self.filename = file unless file.nil?

      fail 'Config filename not set.' if @filename.nil?
      @data_dup = @data.dup
      @data_dup[:file_version] = @version unless @version.nil?

      File.open(@filename, 'w+') { |out| YAML.dump(@data_dup, out) }
      true
    end
  end
end
