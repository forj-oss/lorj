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
  # SectionConfig class layer
  class SectionConfig < PRC::BaseConfig
    # Get the value of a specific key under a section.
    #
    # * *Args*    :
    #   - +keys+  : keys to get values from a section set by data_options.
    #               If section is set, it will use :default
    # * *Returns* :
    #   - key value.
    # * *Raises* :
    #   Nothing
    def [](*keys)
      return nil if keys.length == 0
      return _get(:default, *keys) if @data_options[:section].nil?
      _get(@data_options[:section], *keys)
    end

    def []=(*keys, value)
      return nil if keys.length == 0
      return _set(:default, *keys, value) if @data_options[:section].nil?
      _set(@data_options[:section], *keys, value)
    end

    def exist?(*keys)
      return nil if keys.length == 0
      return _exist?(:default, *keys) if @data_options[:section].nil?
      _exist?(@data_options[:section], *keys)
    end

    def where?(*keys)
      return nil if keys.length == 0
      return _exist?(:default, *keys) if @data_options[:section].nil?
      _where?(@data_options[:section], *keys)
    end

    def del(*keys)
      return nil if keys.length == 0
      return _del(:default, *keys) if @data_options[:section].nil?
      _del(@data_options[:section], *keys)
    end
  end
end
