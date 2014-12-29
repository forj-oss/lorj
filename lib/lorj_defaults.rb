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
  # This class is the Application configuration class used by Lorj::Config
  #
  # It load a defaults.yaml file (path defined by PrcLib::app_defaults)
  #
  # defaults.yaml is divided in 3 sections:
  #
  # * :default: Contains a list of key = value
  # * :setup:   Contains :ask_step array
  #   - :ask_step: Array of group of keys/values to setup. Each group will be
  #                internally identified by a index starting at 0. parameters
  #                are as follow:
  #     - :desc:        string to print out before group setup
  #     - :explanation: longer string to display after :desc:
  #     - :add:         array of keys to add manually in the group.
  #
  #       By default, thanks to data model dependency, the group is
  #       automatically populated.
  #
  # * :section: Contains a list of sections contains several key and attributes
  #             and eventually :default:
  #   This list of sections and keys will be used to build the account files
  #   with the lorj Lorj::Core::Setup function.
  #
  #   - :default: This section define updatable data available from config.yaml.
  #               But will never be added in an account file.
  #     It contains a list of key and options.
  #
  #     - :<aKey>: Possible options
  #       - :desc: default description for that <aKey>
  #
  #   - :<aSectionName>: Name of the section which should contains a list
  #     - :<aKeyName>: Name of the key to setup.
  #       - :desc:              Description of that key, printed out at setup
  #                             time.
  #       - :readonly:          true if this key is not modifiable by a simple
  #                             Lorj::Account::set function. false otherwise.
  #       - :account_exclusive: true if the key cannot be set as default from
  #                             config.yaml or defaults.yaml.
  #       - :account:           true to ask setup to ask this key to the user.
  #       - :validate:          Ruby Regex to validate the end user input.
  #                             Ex: !ruby/regexp /^\w?\w*$/
  #       - :default_value:     default value proposed to the user.
  #       - :ask_step:          Define the group number to attach the key to be
  #                             asked. ex: 2
  #       - :list_values:       Provide capabililities to get a list and choose
  #                             from.
  #         - :query_type:      Can be:
  #
  #           ':query_call' to execute a query on flavor, query_params is empty
  #           for all.
  #
  #           ':process_call' to execute a process function to get the values.
  #
  #           ':controller_call' to execute a controller query.
  #
  #         - :object:
  #
  #           Used with :query_type=:query_call. object type symbol to query.
  #
  #         - :query
  #
  #           Used with :query_type=:process_call. process function name to call
  #
  #         - :query_call:
  #
  #           Used with :query_type=:controller_call. Handler function to use.
  #           (query_e, create_e, ...)
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
  #         - :value:           fields to extract for the list of objects
  #                             displayed.
  #         - :validate:        if :list_strict, the value is limited to the
  #                             possible values from the list
  class Defaults < PRC::SectionConfig
    # Remove inherited method []=
    def []=(*_keys, _value)
    end

    # Load yaml documents (defaults)
    # If config doesn't exist, it will be created, empty with 'defaults:' only

    # Loop on Config metadata
    #
    #
    # * *Args*    :
    #   - ++ ->
    # * *Returns* :
    #   -
    # * *Raises* :
    #   - ++ ->
    def meta_each
      return nil if @data.rh_get(:sections).nil?

      @data.rh_get(:sections).each do | section, hValue |
        hValue.each do | key, value |
          yield section, key, value
        end
      end
    end

    #
    #
    # * *Args*    :
    #   - ++ ->
    # * *Returns* :
    #   -
    # * *Raises* :
    #   - ++ ->
    def meta_exist?(key)
      return nil unless key

      key = key.to_sym if key.class == String

      section = @account_section_mapping.rh_get(key)
      @data.rh_exist?(:sections, section, key)
    end

    # Get model data options. Section name is determined by the associated
    # data name
    #
    # * *Args*    :
    #   - +data+   : data name
    #   - options+ : options tree.
    # * *Returns* :
    #   - data options values
    #   OR
    #   - nil if:
    #     - missing data name as parameter.
    #     - data was not found. defined in /:sections/<section>/<data
    # * *Raises* :
    #   - ++ ->
    def get_meta_auto(*keys)
      return nil unless keys.length > 0
      section = @account_section_mapping.rh_get(keys[0])
      return nil if section.nil?
      @data.rh_get(:sections, section, keys)
    end

    # Get model section/data options.
    #
    # * *Args*    :
    #   - +section+ : section name
    #   - +data+    : data name
    #   - +options+ : options tree.
    #
    # * *Returns* :
    #   - data options values
    #   OR
    #   - nil if:
    #     - missing section and data name as parameter.
    #     - data was not found. defined in /:sections/<section>/<data
    # * *Raises* :
    #   - ++ ->
    def get_meta(*keys)
      return nil unless keys.length > 1
      @data.rh_get(:sections, keys)
    end

    #
    #
    # * *Args*    :
    #   - ++ ->
    # * *Returns* :
    #   -
    # * *Raises* :
    #   - ++ ->
    def build_section_mapping
      if @data.rh_get(:sections).nil?
        PrcLib.warning('defaults.yaml do not defines :sections')
        return nil
      end

      # TODO: Support multiple identical key name on distinct sections
      # The primary data key should change from key to section & key.
      @data.rh_get(:sections).each do | section, hValue |
        next if section == :default
        hValue.each_key do | map_key |
          if @account_section_mapping.rh_exist?(map_key)
            PrcLib.fatal(1, 'defaults.yaml: Duplicate entry between sections. '\
                            "'%s' defined in section '%s' already exists in"\
                            " section '%s'", map_key, section,
                         @account_section_mapping.rh_get(map_key))
          end
          @account_section_mapping.rh_set(section, map_key)
        end
      end
    end

    #
    #
    # * *Args*    :
    #   - ++ ->
    # * *Returns* :
    #   -
    # * *Raises* :
    #   - ++ ->
    def get_meta_section(key)
      key = key.to_sym if key.class == String
      @account_section_mapping.rh_get(key)
    end

    #
    #
    # * *Args*    :
    #   - ++ ->
    # * *Returns* :
    #   -
    # * *Raises* :
    #   - ++ ->
    def load
      @account_section_mapping = {}

      if !PrcLib.app_defaults
        PrcLib.warning('PrcLib.app_defaults is not set. Application defaults'\
                       " won't be loaded.")
      else
        @filename = File.join(PrcLib.app_defaults, 'defaults.yaml')

        PrcLib.info("Reading default configuration '%s'...", @filename)

        if File.exist?(@filename)
          _load(@filename)

          build_section_mapping
        else
          PrcLib.warning("PrcLib.app_defaults is set to '%s'. Trying to load"\
                         " '%s' but not found. Application defaults won't "\
                         'be loaded.', PrcLib.app_defaults, @filename)
        end

      end
    end
  end

  module_function

  # Lorj::defaults exposes the application defaults and Config Lorj metadata.
  def defaults
    return @defaults unless @defaults.nil?
    @defaults = Defaults.new

    @defaults.load

    @defaults
  end
end
