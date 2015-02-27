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

module PRC
  # SectionConfig class layer based on BaseConfig.
  #
  # It supports a data_options :section for #[], #[]=, etc...
  #
  class SectionConfig < PRC::BaseConfig
    # Get the value of a specific key under a section.
    # You have to call #data_options(:section => 'MySection')
    #
    # * *Args*    :
    #   - +keys+  : keys to get values from a section set by data_options.
    #     If section is not set, it will use :default
    # * *Returns* :
    #   - key value.
    # * *Raises* :
    #   Nothing
    def [](*keys)
      return nil if keys.length == 0
      return p_get(:default, *keys) if @data_options[:section].nil?
      p_get(@data_options[:section], *keys)
    end

    # Set the value of a specific key under a section.
    # You have to call #data_options(:section => 'MySection')
    #
    # * *Args*    :
    #   - +keys+  : keys to get values from a section set by data_options.
    #     If section is not set, it will use :default
    # * *Returns* :
    #   - key value.
    # * *Raises* :
    #   Nothing
    def []=(*keys, value)
      return nil if keys.length == 0
      return p_set(:default, *keys, value) if @data_options[:section].nil?
      p_set(@data_options[:section], *keys, value)
    end

    # Check key existence under a section.
    # You have to call #data_options(:section => 'MySection')
    #
    # * *Args*    :
    #   - +keys+  : keys to get values from a section set by data_options.
    #     If section is not set, it will use :default
    # * *Returns* :
    #   - key value.
    # * *Raises* :
    #   Nothing
    def exist?(*keys)
      return nil if keys.length == 0
      return p_exist?(:default, *keys) if @data_options[:section].nil?
      p_exist?(@data_options[:section], *keys)
    end

    # remove the key under a section.
    # You have to call #data_options(:section => 'MySection')
    #
    # * *Args*    :
    #   - +keys+  : keys to get values from a section set by data_options.
    #     If section is not set, it will use :default
    # * *Returns* :
    #   - key value.
    # * *Raises* :
    #   Nothing
    def del(*keys)
      return nil if keys.length == 0
      return p_del(:default, *keys) if @data_options[:section].nil?
      p_del(@data_options[:section], *keys)
    end
  end
end
