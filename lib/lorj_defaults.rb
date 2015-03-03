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
  # defaults.yaml is divided in 3 sections.
  # But only defaults section is loaded in Defaults instance.
  # Defaults implements a AppConfig class, which provides meta data access
  # Accessible through PrcLib.appdata
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
  #   For details, see Lorj::MetaAppConfig
  # * :section: Contains a list of sections with several keys and attributes
  #   and eventually :default:
  #   For details, see Lorj::MetaAppConfig
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
    # This function is obsolete. Use Lorj.metadata.meta_each instead
    #
    # * *Args*    :
    #   - +code+ : Block of code on `section`, `key`, `value`
    #
    # * *Returns* :
    #   - nothing
    def meta_each
      PrcLib.debug("'Lorj.defaults.%s' is obsolete and will be removed "\
                   'in Lorj 2.0. Please update your code to call '\
                   "'Lorj.data.%s' instead.\n%s",
                   __method__, 'meta_each', caller[0])
      Lorj.data.meta_each do |section, key, value|
        yield section, key, value
      end
    end

    # Check existence of the key in metadata.
    # This function is obsolete. Use Lorj.metadata.auto_meta_exist? instead
    # Consider also the Lorj.metadata.auto_meta_exist? which check from a
    # section name, a well.
    #
    # * *Args*    :
    #   - +key+ : Key name to check.
    #
    # * *Returns* :
    #   - true if found, false otherwise.
    def meta_exist?(key)
      PrcLib.debug("'Lorj.defaults.%s' is obsolete and will be removed "\
                   'in Lorj 2.0. Please update your code to call '\
                   "'Lorj.data.%s' instead.\n%s",
                   __method__, 'auto_meta_exist?', caller[0])
      Lorj.data.auto_meta_exist?(key)
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
    def get_meta_auto(data, *options)
      PrcLib.debug("'Lorj.defaults.%s' is obsolete and will be removed "\
                   'in Lorj 2.0. Please update your code to call '\
                   "'Lorj.data.%s' instead.\n%s",
                   __method__, 'auto_section_data', caller[0])
      Lorj.data.auto_section_data(data, *options)
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
    def get_meta(section, data, *options)
      PrcLib.debug("'Lorj.defaults.%s' is obsolete and will be removed "\
                   'in Lorj 2.0. Please update your code to call '\
                   "'Lorj.data.%s' instead.\n%s",
                   __method__, 'section_data', caller[0])
      Lorj.data.section_data(section, data, *options)
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
      PrcLib.debug("'Lorj.defaults.%s' is obsolete and will be removed "\
                   'in Lorj 2.0. Please update your code to call '\
                   "'Lorj.data.%s' instead.\n%s",
                   __method__, 'first_section', caller[0])
      Lorj.data.first_section(key)
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
      if !PrcLib.app_defaults
        PrcLib.warning('PrcLib.app_defaults is not set. Application defaults'\
                       " won't be loaded.")
      else
        @filename = File.join(PrcLib.app_defaults, 'defaults.yaml')

        PrcLib.info("Reading default configuration '%s'...", @filename)

        if File.exist?(@filename)
          p_load(@filename)

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
