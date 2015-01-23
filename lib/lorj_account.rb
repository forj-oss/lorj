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

module Lorj
  # Simple List of accounts class.
  class Accounts
    # Class to query FORJ Accounts list.
    def initialize
      @account_path = File.join(PrcLib.data_path, 'accounts')
    end

    def dump
      accounts = []
      Dir.foreach(@account_path) do |x|
        accounts << x unless x.match(/^\..?$/)
      end
      accounts
    end
  end
end

module Lorj
  # AccountConfig class layer
  class AccountConfig < PRC::SectionConfig
    # Function to initialize read only account attribute.
    def ac_new(account_name, provider = 'lorj')
      @data = {}
      data_options :section => :account
      self[:name] = account_name
      self[:provider] = provider
      true
    end

    def data_options(options = { :section => :default })
      _data_options(options)
    end
  end
end

module Lorj
  # Lorj::Account manage a list of key/value grouped by section.
  # The intent of Lorj::Account is to attach some keys/values to
  # an account to help end users to switch between accounts.
  #
  # Lorj::Account is based on Lorj::Config (see lorj-config.rb)
  # This ensure ForjConfig and Lorj::Account defines following common functions
  # - set or []= (key, value)
  # - get or []  (key)
  #
  # Those function do not expose any section name.
  # It means, that keys have to be unique across sections.
  # Sections are defined in the application defaults.yaml, under sections
  # :sections.
  #
  # defaults.yaml structure is:
  # sections:
  #   default: => defines key/values recognized by Lorj::Account to be only
  #               managed by ForjConfig.
  #     <key> :
  #       :desc : <value> => defines the ForjConfig key description.
  #   <section>: Define a section name. For each keys on this section, the
  #              account file will kept those data under this section.
  #     <key>:
  #       :desc:              defines the key description.
  #       :readonly:          true if this key cannot be updated by
  #                           Lorj::Account.set
  #       :account_exclusive: true if this key cannot be predefined on
  #                           ForjConfig keys list
  #       :default:           *OBSOLETE*. It will be removed soon
  #                           default values have to be defined as
  #                           :default_value instead of /:default/<key>
  #                           <ForjConfig real key name> Used to map the
  #                           Lorj::Account key to a different ForjConfig key
  #                           name.
  #       :default_value:     default application value for this key.
  #                           ':default_value' superseed /:default/<key>/<value>
  #                           name.
  #
  # Currently, this class derived from Lorj::Config
  # defines the following functions:
  # where? exist?, get or [], set or []=, save and load.
  #
  # exist?, get uses the config layers to get data. By default, the order is:
  # - runtime    : get the data from runtime (runtimeSet/runtime_get)
  # - Account    : otherwise, get data from account file under section
  #                described in defaults.yaml (:account_section_mapping), as
  #                soon as this mapping exists.
  # - local      : otherwise, get the data from the local configuration file.
  #                Usually ~/.forj/config.yaml
  # - application: otherwise, get the data from defaults.yaml (class Default)
  class Account < Lorj::Config
    attr_reader :account_name

    # This object manage data located in oConfig[:hpc_accounts/AccountName]

    # The class new accept to provide a local config file different than
    # standard one configured by PrcLib.app_path/.config.yaml
    def initialize(config_name = nil)
      config_layers = []

      # Application layer
      config_layers << define_default_layer

      # Local Config layer
      config_layers << define_local_layer

      # Account config layer
      config_layers << define_account_layer

      # runtime Config layer
      config_layers << define_runtime_layer

      if PrcLib.data_path.nil?
        PrcLib.fatal(1, 'Internal PrcLib.data_path was not set.')
      end

      initialize_local(config_layers[1][:config], config_name)

      initialize_account

      initialize_layers(config_layers)
    end

    # get function.
    # If the Application meta data option of the key is set with
    # :account_exclusive => true, get will limit to runtime then account.
    # otherwise, search in all layers.
    #
    # * *Args*    :
    # - +key+     : key name. It do not support it to be a key tree (Arrays of
    #               keys).
    # - +default+ : default value, if not found.
    # - +options+ : Options for get:
    #   - +:section+ : Get will use this section name instead of searching it.
    #   - +:name+    : layer to exclusively get data.
    #   - +:indexes+ : layer index to exclusively get data.
    #                  If neither :name or :index is set, get will search
    #                  data on all predefined layers, first found.
    # * *Returns* :
    #   - key value.
    # * *Raises* :
    #   Nothing
    def get(key, default = nil, options = {})
      key = key.to_sym if key.class == String
      options = {} unless options.is_a?(Hash)

      section = options[:section]
      section = Lorj.defaults.get_meta_section(key) if section.nil?

      options = { :keys => [key], :section => section }

      indexes = _identify_indexes(options, exclusive?(key, section))
      names = []
      indexes.each { |index| names << @config_layers[index][:name] }

      options[:data_options] = _set_data_options_per_names(names)

      return _get(options) if _exist?(options)

      default
    end

    def [](key, default = nil)
      get(key, default)
    end

    # where? function.
    # If the Application meta data option of the key is set with
    # :account_exclusive => true, get will limit to runtime then account.
    # otherwise, search in all layers.
    #
    # * *Args*    :
    # - +key+     : key name. It do not support it to be a key tree (Arrays of
    #               keys).
    # - +options+ : possible options:
    #   - +:section+ : Force to use a specific section name.
    #   - +:name+    : layer to exclusively get data.
    #   - +:indexes+ : layer index to exclusively get data.
    #                  If neither :name or :index is set, get will search
    #                  data on all predefined layers, first found, first listed.
    # * *Returns* :
    #   - key value.
    # * *Raises* :
    #   Nothing
    def where?(key, options = {})
      key = key.to_sym if key.class == String
      options = {} unless options.is_a?(Hash)

      section = options[:section]
      section = Lorj.defaults.get_meta_section(key) if section.nil?

      indexes = _identify_array_indexes(options, exclusive?(key, section))

      names = []
      indexes.each { |index| names << @config_layers[index][:name] }

      where_options = {
        :keys => [key],
        :section => section,
        :indexes => indexes,
        :data_options => _set_data_options_per_names(names)
      }

      _where?(where_options)
    end

    # check key/value existence in config layers
    #
    # * *Args*    :
    # - +key+     : key name. It do not support it to be a key tree (Arrays of
    #               keys).
    # - +options+ : possible options:
    #   - +:section+ : Force to use a specific section name.
    #   - +:name+    : layer to exclusively get data.
    #   - +:indexes+ : layer index to exclusively get data.
    #                  If neither :name or :index is set, get will search
    #                  data on all predefined layers, first found.
    #
    # * *Returns* :
    #   - 'runtime'       : if found in runtime.
    #   - '<AccountName>' : if found in the Account data structure.
    #   - 'local'         : if found in the local configuration file.
    #                       Usually ~/.forj/config.yaml
    #   - 'default'       : if found in the Application default
    #                       (File 'defaults.yaml') (class Default)
    # * *Raises* :
    #   Nothing
    def exist?(key, options = nil)
      key = key.to_sym if key.class == String
      options = {} unless options.is_a?(Hash)

      section = options[:section]
      section = Lorj.defaults.get_meta_section(key) if section.nil?
      options = { :keys => [key], :section => section }

      indexes = _identify_indexes(options, exclusive?(key, section))

      names = []
      indexes.each { |index| names << @config_layers[index][:name] }

      options[:data_options] = _set_data_options_per_names(names)

      _exist?(options)
    end

    # Return true if readonly. set won't be able to update this value.
    # Only _set (private function) is able.
    #
    # * *Args*    :
    #   - +key+     : key name. It can support it to be a key tree (Arrays of
    #                 keys).
    #   - +section+ : optionnal. If missing the section name is determined by
    #                 the data name associated
    # * *Returns* :
    #   - true/false : readonly value
    #   OR
    #   - nil if:
    #     - section was not found
    def readonly?(key, section = nil)
      return nil unless key

      key = key.to_sym if key.class == String
      section = Lorj.defaults.get_meta_section(key) if section.nil?

      return nil if section.nil?

      result = Lorj.defaults.get_meta(section, key, :readonly)
      return result if result.boolean?
      false
    end

    # Return true if exclusive
    # set won't be able to update this value.
    # Only _set (private function) is able.
    #
    # * *Args*    :
    #   - +key+     : key name. It can support it to be a key tree (Arrays of
    #                 keys).
    #   - +section+ : optionnal. If missing the section name is determined by
    #                 the data name associated
    # * *Returns* :
    #   - true/false : readonly value
    #   OR
    #   - nil if:
    #     - section was not found
    def exclusive?(key, section = nil)
      return nil unless key

      key = key.to_sym if key.class == String
      section = Lorj.defaults.get_meta_section(key) if section.nil?

      return nil if section.nil?
      result = Lorj.defaults.get_meta(section, key,
                                      :account_exclusive)
      return result if result.boolean?
      result
    end

    # This function update a section/key=value if the account structure is
    # defined.
    # If no section is defined, set it in runtime config.
    #
    # * *Args*    :
    # - +key+     : key name. It do not support it to be a key tree (Arrays of
    #               keys).
    # - +value+   : value to set
    # - +options+ : possible options:
    #   - +:section+ : Force to use a specific section name.
    #   - +:name+    : layer to exclusively get data.
    #   - +:indexes+ : layer index to exclusively get data.
    #                  If neither :name or :index is set, set will use the
    #                  'runtime' layer.
    #
    # * *Returns* :
    # - the value set
    # OR
    # - nil if:
    #   - lorj data model set this key as readonly.
    #   - value is nil. The value is set to nil, then.
    #   - key is nil. No update is done.
    #
    # * *Raises* :
    #   Nothing
    def set(key, value, options = {})
      parameters = validate_key_and_options(key, options)
      return nil if parameters.nil?

      key = parameters[0][0]
      layer_name, section = parameters[1]

      section = Lorj.defaults.get_meta_section(key) if section.nil?
      section = :default if section.nil?

      return nil if readonly?(key, section)

      options = { :keys => [key], :section => section, :value => value }

      options[:indexes] = index_to_update(layer_name, key, section)

      _set(options)
    end

    def []=(key, value)
      set(key, value)
    end

    def del(key, options = {})
      parameters = validate_key_and_options(key, options)
      return nil if parameters.nil?

      key = parameters[0][0]
      layer_name, section = parameters[1]

      section = Lorj.defaults.get_meta_section(key) if section.nil?
      section = :default if section.nil?

      return nil if readonly?(key, section)

      options = { :keys => [key], :section => section }

      options[:indexes] = index_to_update(layer_name, key, section)

      _del(options)
    end
  end

  # Defines Account exclusive functions
  class Account
    def ac_new(sAccountName, provider_name = nil)
      return nil if sAccountName.nil?
      @account_name = sAccountName

      account = @config_layers[1][:config]
      account.erase
      account.ac_new sAccountName, provider_name
    end

    # Load Account Information
    def ac_load(sAccountName = @account_name)
      @account_name = sAccountName unless !sAccountName.nil? &&
                                          sAccountName == @account_name
      return false if @account_name.nil?

      account_file = File.join(@account_path, @account_name)
      return false unless File.exist?(account_file)

      _do_load(@config_layers[1][:config], account_file)
    end

    # Account save function.
    # Use set/get to manage those data that you will be able to save in an
    # account file.
    # * *Args*    :
    #
    # * *Returns* :
    # - true if saved
    # OR
    # - false if:
    #   - the account do not set the :provider name.
    #   - value is nil. The value is set to nil, then.
    # OR
    # - nil if:
    #   - account_name is not set
    #
    # * *Raises* :
    #   Nothing
    def ac_save
      return nil if @account_name.nil?

      account_file = File.join(@account_path, @account_name)

      account = @config_layers[1][:config]
      local = @config_layers[2][:config]

      account.data_options(:section => :account)
      if account[:provider].nil?
        PrcLib.error "Provider name is not set. Unable to save the account '"\
                     "%s' to '%s'", @account_name, account_file
        return false
      end

      account.filename = account_file
      result = account.save

      return result unless result

      return true if local.exist?(:account_name)

      local[:account_name] = @account_name
      local.save

      true
    end
  end

  # Defines internal functions
  class Account
    # TODO: Strange function!!! To revisit

    def meta_type?(key)
      return nil unless key

      section = Lorj.defaults.get_meta_section(key)

      return section if section == :default
      @account_name
    end

    # private functions

    private

    def _identify_array_indexes(options, account_exclusive)
      def_indexes = options[:indexes] if options.key?(:indexes)
      if options[:names].is_a?(Array)
        def_indexes = layers_indexes(options[:names])
      end

      indexes = exclusive_indexes(account_exclusive)
      options[:indexes] = indexes

      return indexes if def_indexes.nil? || def_indexes.length == 0

      def_indexes.delete_if { |index| !indexes.include?(index) }

      def_indexes
    end

    def layers_indexes(names)
      return nil unless names.is_a?(Array)

      indexes = [] if names.is_a?(Array)
      names.each do |name|
        indexes << layer_index(name) if name.is_a?(String)
      end
      indexes
    end

    def exclusive_indexes(account_exclusive)
      return [0, 1] if account_exclusive
      [0, 1, 2, 3]
    end

    def _identify_indexes(options, account_exclusive)
      index = options[:index] if options.key?(:index)
      index = layer_index(options[:name]) if options.key?(:name)

      indexes = exclusive_indexes(account_exclusive)
      options[:indexes] = indexes

      indexes = [index] if !index.nil? && indexes.include?(index)
      indexes
    end

    def _set_data_options_per_names(names)
      data_options = []

      names.each { |name| data_options <<  _data_options_per_layer(name) }

      data_options
    end

    # This internal function defines default section name per config index.
    # TODO: Change local and default way to get default values, not in /:default
    def _data_options_per_layer(layer_name)
      # runtime and local and default uses :default section
      case layer_name
      when 'local', 'default'
        # local & default are SectionConfig and is forced to use :default as
        # section name for each data.
        { :section => :default }
      end
      # nil: layer_index = 0 => runtime. runtime is not a SectionConfig.

      # nil: layer_index = 1 => account
      # account is a SectionConfig and use section value defined by the
      # lorj data model. So the section name is not forced.
    end

    def _do_load(config, account_file)
      result = config.load account_file
      return result unless result == true

      config.data_options :section => :account
      config[:name] = @account_name unless config[:name]
      unless config.exist?(:provider)
        config[:provider] = nil
        PrcLib.warning "'%s' defines an empty provider name.", account_file
      end

      if config.rh_key_to_symbol?(2)
        config.rh_key_to_symbol(2)
        config.save
      end
      true
    end

    def index_to_update(layer_name, key, section)
      indexes = [0] # choose runtime by default.
      indexes = _layer_indexes([layer_name]) unless layer_name.nil?

      if layer_name.nil?
        # Return runtime layer, if layer requested is not updatable.
        return [0] if indexes[0] <= (exclusive?(key, section) ? 1 : 3)
      end
      indexes
    end

    def define_account_layer
      PRC::CoreConfig.define_layer(:name     => 'account',
                                   :config   => Lorj::AccountConfig.new,
                                   :file_set => true,
                                   :load     => true, :save     => true)
    end

    def initialize_account
      @account_path = File.join(PrcLib.data_path, 'accounts')

      PrcLib.ensure_dir_exists(@account_path)
    end

    def validate_key_and_options(key, options = {})
      return nil unless key

      key = key.to_sym if key.class == String

      options = {} unless options.is_a?(Hash)

      parameters = _valid_options(options, [], [:name, :section])

      return nil if parameters.nil?

      parameters[0] << key
      parameters
    end
  end
end
