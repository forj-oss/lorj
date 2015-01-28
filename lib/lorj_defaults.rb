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
  # It loads a defaults.yaml file (path defined by PrcLib::app_defaults)
  #
  # The defaults.yaml data is accessible through Lorj.defaults.data
  # Use this capability with caution, as it contents is R/W.
  #
  # For getting Application defaults, use Lorj::Config[]
  # or Lorj::Account[], Lorj::Account.get(key, nil, :names => ['default'])
  # For setup meta data, use Lorj.defaults.get_meta,
  # Lorj.defaults.get_meta_auto or Lorj.defaults.get_meta_section
  #
  # defaults.yaml is divided in 3 sections:
  #
  # * :default: Contains a list of key = value representing the application
  #   default configuration.
  #
  #   Data stored in this section are accessible through Lorj::Config[]
  #   or Lorj::Account[], Lorj::Account.get(key, nil, :names => ['default'])
  #
  #   Ex:
  #    # Use Lorj.defaults.data exceptionnaly
  #    Lorj.defaults.data.merge(:default => { data: 'test'}})
  #
  #    config = Lorj::Account.new
  #    puts config.get(:data, nil, :names => ['default'])
  #    # => test
  #    puts Lorj.defaults[:data]
  #    # => test
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
  #    [...]
  #    :explanation: |-
  #      My complete explanation is in
  #      multiline <%= config['text'] %>
  #    [...]
  #
  #
  #     - :add: array of keys to add manually in the group. The Array can be
  #       written with [] or list of dash elements
  #
  #       Example of a defaults.yaml content:
  #
  #    [...]
  #    :ports: [22, 25]
  #
  #    :ports:
  #      - 22
  #      - 25
  #    [...]
  #
  #       By default, thanks to data model dependency, the group is
  #       automatically populated. So, you need update this part only for
  #       data that are not found from the dependency.
  # * :section: Contains a list of sections with several keys and attributes
  #   and eventually :default:
  #
  #   This list of sections and keys will be used to build the account files
  #   with the lorj Lorj::Core.setup function.
  #   Those data is accessible through the Lorj.defaults.get_meta,
  #   Lorj.defaults.get_meta_auto or Lorj.defaults.get_meta_section
  #
  #   Ex:
  #    # Use Lorj.defaults.data exceptionnaly
  #    Lorj.defaults.data.merge({sections: {:mysection: {key: {
  #                                                            data1: 'test1',
  #                                                            data2: 'test2'
  #                                                           }}}})
  #
  #    puts Lorj.defaults.get_meta(:mysection, :key)
  #    # => { data1: 'test1', data2: 'test2' }
  #    puts Lorj.defaults.get_meta(:mysection)
  #    # => {:key => { data1: 'test1', data2: 'test2' }}
  #    puts Lorj.defaults.get_meta_section(:key)
  #    # => :mysection
  #    puts Lorj.defaults.get_meta_auto(:key)
  #    # => { data1: 'test1', data2: 'test2' }
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
  #         Description of that key, printed out at setup time.
  #
  #       - :readonly:          true if this key is not modifiable by a simple
  #
  #         Lorj::Account::set function. false otherwise.
  #
  #       - :account_exclusive: true if the key cannot be set as default from
  #         config.yaml or defaults.yaml.
  #
  #       - :account:           true to ask setup to ask this key to the user.
  #
  #       - :validate:          Ruby Regex to validate the end user input.
  #
  #         Ex: !ruby/regexp /^\w?\w*$/
  #
  #       - :default_value:     default value proposed to the user.
  #
  #       - :ask_step:          Define the group number to attach the key to be
  #         asked. ex: 2
  #
  #       - :list_values:       Provide capabililities to get a list and choose
  #         from.
  #
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
  #         - :value:
  #
  #           fields to extract for the list of objects displayed.
  #
  #         - :validate:
  #
  #           if :list_strict, the value is limited to the possible values from
  #           the list

  # meta data are defined in defaults.yaml and loaded in Lorj::Default class
  # definition.
  # Cloud provider can redefine ForjData defaults and add some extra
  # parameters.
  # To get Application defaults, read defaults.yaml, under :sections:
  # Those values can be updated by the controller with define_data
  # <Section>:
  #   <Data>:               Required. Symbol/String. default: nil
  #                         => Data name. This symbol must be unique, across
  #                            sections.
  #     :desc:              Required. String. default: nil
  #                         => Description
  #     :explanation:  |-   Print a multiline explanation before ask the key
  #                         value.
  #                         ERB template enable. To get config data,
  #                         type <%= config[...] %>
  #     :readonly:          Optional. true/false. Default: false
  #                         => oForjConfig.set() will fail if readonly is
  #                            true. It can be set, only thanks to:
  #                            - oForjConfig.setup()
  #                              or using private
  #                            - oForjConfig._set()
  #     :account_exclusive: Optional. true/false. Default: false
  #                         => Only oConfig.account_get/set() can handle the
  #                            value
  #                            oConfig.set/get cannot.
  #     :account:           Optional. default: False
  #                         => setup will configure the account with this
  #                           <Data>
  #     :ask_sort:          Number which represents the ask order in the
  #                         step group. (See /:setup/:ask_step for details)
  #     :after:  <Data>     Name of the previous <Data> to ask before the
  #                         current one.
  #     :depends_on:
  #                         => Identify :data type required to be set before
  #                            the current one.
  #     :default_value:     Default value at setup time. This is not
  #                         necessarily the Application default value
  #                         (See /:default)
  #     :validate:          Regular expression to validate end user input
  #                         during setup.
  #     :value_mapping:     list of values to map as defined by the
  #                         controller
  #       :controller:      mapping for get controller value from process
  #                         values
  #         <value> : <map> value map equivalence. See data_value_mapping
  #                         function
  #       :process:         mapping for get process value from controller
  #                         values
  #         <value> : <map> value map equivalence. See data_value_mapping
  #                         function
  #     :default:           Default value. Replace /:default/<data>
  #     :list_values:       Defines a list of valid values for the current
  #                         data.
  #       :query_type       :controller_call to execute a function defined
  #                         in the controller object.
  #                         :process_call to execute a function defined in
  #                         the process object.
  #                         :values to get list of values from :values.
  #       :object           Object to load before calling the function.
  #                           Only :query_type = :*_call
  #       :query_call       Symbol. function name to call.
  #                           Only :query_type = :*_call
  #                         function must return an Array.
  #       :query_params     Hash. Controler function parameters.
  #                           Only :query_type = :*_call
  #       :validate         :list_strict. valid only if value is one of
  #                          thoselisted.
  #       :values:          to retrieve from.
  #                         otherwise define simply a list of possible
  #                         values.
  #       :ask_step:        Step number. By default, setup will determine
  #                         the step, thanks to meta lorj object
  #                         dependencies tree.
  #                         This number start at 0. Each step can be defined
  #                         by /:setup/:ask_step/<steps> list.
  #     :pre_step_function: Process called before asking the data.
  #                         if it returns true, user interaction is
  #                         cancelled.
  #     :post_step_function:Process called after asking the data.
  #                         if it returns false, the user is requested to
  #                         re-enter a new value.
  #
  # :setup:                  This section describes group of fields to ask,
  #                          step by step.
  #     :ask_step:           Define an Array of setup steps to ask to the
  #                          end user. The step order is respected, and
  #                          start at 0
  #     -  :desc:            Define the step description. ERB template
  #                          enable. To get config data, type config[...]
  #        :explanation:  |- Define a multiline explanation. This is printed
  #                          out in brown color.
  #                          ERB template enable. To get config data, type
  #                          <%= config[...] %>
  #        :add:             Define a list of additionnal fields to ask.
  #        - <Data>          Data to ask.
  #
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

      @data.rh_get(:sections).each do |section, hValue|
        hValue.each do |key, value|
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

    # def get_meta_section(*keys)
    #   return nil unless keys.length > 0
    #   @account_section_mapping.rh_get(keys[0])
    # end

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
      @data.rh_get(:sections).each do |section, hValue|
        next if section == :default
        hValue.each_key do |map_key|
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
