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

# - Lorj::BaseProcess   : Process functions to call create/delete/edit/query
#   processes on other objects.
module Lorj
  # class describing generic Object Process
  # with controller calls
  class BaseProcess
    def initialize
      @base_object = nil
    end

    # Simply raise an error
    #
    # * *Args*    :
    #   - +Msg+ : Error message to print out.
    # * *Returns* :
    #   - nil
    # * *Raises* :
    #  - Lorj::PrcError
    def process_error(msg, *p)
      msg = format(msg, *p)
      fail Lorj::PrcError.new, format('%s: %s', self.class, msg)
    end

    attr_writer :base_object

    def controller_connect(sObjectType, params = nil)
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_connect(sObjectType, params)
    end

    def controller_create(sObjectType, params = nil)
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_create(sObjectType, params)
    end

    def controller_query(sObjectType, sQuery, params = nil)
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_query(sObjectType, sQuery, params)
    end

    def controller_update(sObjectType, params = nil)
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_update(sObjectType, params)
    end

    def controller_delete(sObjectType, params = nil)
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_delete(sObjectType, params)
    end

    def controller_get(sObjectType, sId, params = nil)
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_get(sObjectType, sId, params)
    end
  end

  # class describing generic Object Process
  # with process calls
  class BaseProcess
    def process_create(sObjectType)
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_create(sObjectType)
    end

    def process_query(sObjectType, sQuery)
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_query(sObjectType, sQuery)
    end

    def process_update(sObjectType)
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_update(sObjectType)
    end

    def process_get(sObjectType, sId)
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_get(sObjectType, sId)
    end

    def process_delete(sObjectType)
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_delete(sObjectType)
    end
  end

  # class describing generic Object Process
  # with additionnal functions
  class BaseProcess
    private

    def query_cache_cleanup(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @base_object
      @base_object.query_cleanup(sObjectType)
    end

    def object_cache_cleanup(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @base_object
      @base_object.object_cleanup(sObjectType)
    end

    def controler
      PrcLib.warning('controler object call is obsolete. Please update your'\
                     " code. Use controller_<action> instead.\n%s", caller)
      PrcLib.runtime_fail 'No Controler object loaded.' unless @base_object
      @base_object
    end

    def object
      PrcLib.warning('object call is obsolete. Please update your code.'\
                     "Use <Action> instead.\n%s", caller)
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object
    end

    def format_object(sObjectType, oMiscObj)
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.format_object(sObjectType, oMiscObj)
    end

    def format_query(sObjectType, oMiscObj, hQuery)
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.format_list(sObjectType, oMiscObj, hQuery)
    end

    def data_objects(sObjectType, *key)
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.data_objects(sObjectType, *key)
    end

    def get_data(oObj, *key)
      PrcLib.warning('get_data call is obsolete. Please update your code. '\
                     "Use [] instead.\n%s", caller)
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.get_data(oObj, :attrs, key)
    end

    def register(oObject, sObjectType = nil)
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.register(oObject, sObjectType)
    end

    def config
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.config
    end

    def query_single(sCloudObj, sQuery, name, sInfoMsg = {})
      list = controller_query(sCloudObj, sQuery)

      info = _qs_info_init(sInfoMsg)

      case list.length
      when 0
        PrcLib.info(info[:notfound], sCloudObj, name)
        list
      when 1
        Lorj.debug(2, info[:checkmatch], sCloudObj, name)

        _qs_check_match(list, sQuery)

        if list.length == 0
          PrcLib.info(info[:nomatch], sCloudObj, name)
          return list
        end

        item = _qs_info(list, info[:items], info[:items_form])

        PrcLib.info(info[:found], sCloudObj, item)

        list
      else
        Lorj.debug(2, info[:more], sCloudObj, name)
        # Looping to find the one corresponding
        _qs_check_match(list, sQuery)

        if list.length == 0
          PrcLib.info(info[:notfound], sCloudObj, name)
          return list
        end
        item = _qs_info(list, info[:items], info[:items_form])
        PrcLib.info(info[:found], sCloudObj, item)

        list
      end
    end
  end

  # internal functions
  class BaseProcess
    private

    # Internal Function to printout a format string
    #
    # *Args*
    # - list : ObjectData
    # - items: Symbol or Array of symbols
    # - items_format : String format supported by format function
    #
    # *return:
    # - formated string thanks to data extracted from list.
    #   If the key is not found (or value nil) from list,
    #   an error message is return to the formated string
    #   with the wrong key.
    #
    def _qs_info(list, items, items_form)
      items_built = []
      if items.is_a?(Array)
        items.each do |key|
          items_built << _qs_value(list, 0, key)
        end
      else
        items_built << _qs_value(list, 0, items)
      end
      format(items_form, *items_built)
    end

    def _qs_value(list, index, key)
      value = list[index, key]
      (value.nil? ? format("\"key '%s' unknown\"", key) : value)
    end

    def _qs_check_match(list, sQuery)
      list.each do |oElem|
        is_found = true
        sQuery.each do |key, value|
          if oElem[key] != value
            is_found = false
            break
          end
        end
        :remove unless is_found
      end
    end

    # qs_info_init is not omplex as well described. Disabling rubocop
    # rubocop: disable PerceivedComplexity, CyclomaticComplexity

    def _qs_info_init(sInfoMsg)
      info = {
        :notfound => "No %s '%s' found",
        :checkmatch => "Found 1 %s. checking exact match for '%s'.",
        :nomatch => "No %s '%s' match",
        :found => "Found %s '%s'.",
        :more => "Found several %s. Searching for '%s'.",
        :items_form => '%s',
        :items => [:name]
      }
      info[:notfound]     = sInfoMsg[:notfound]   if sInfoMsg.key?(:notfound)
      info[:checkmatch]   = sInfoMsg[:checkmatch] if sInfoMsg.key?(:checkmatch)
      info[:nomatch]      = sInfoMsg[:nomatch]    if sInfoMsg.key?(:nomatch)
      info[:found]        = sInfoMsg[:found]      if sInfoMsg.key?(:found)
      info[:more]         = sInfoMsg[:more]       if sInfoMsg.key?(:more)
      info[:items]        = sInfoMsg[:items]      if sInfoMsg.key?(:items)
      info[:items_form]   = sInfoMsg[:items_form] if sInfoMsg.key?(:items_form)
      info
    end
  end
end
