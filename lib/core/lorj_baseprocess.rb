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

# Module Lorj which contains several classes.
#
# Those classes describes :
# - processes (BaseProcess)   : How to create/delete/edit/query object.
# - controler (BaseControler) : If a provider is defined, define how will do
#                               object creation/etc...
# - definition(BaseDefinition): Functions to declare objects, query/data mapping
#                               and setup
# this task to make it to work.

module Lorj
  # class describing generic Object Process
  # with controller calls
  class BaseProcess
    def initialize
      @definition = nil
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
      runtime_fail '%s: %s', self.class, msg
    end

    attr_writer :base_object

    def controller_connect(sObjectType, hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @definition
      @definition.controller_connect(sObjectType, hParams)
    end

    def controller_create(sObjectType, hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @definition
      @definition.controller_create(sObjectType, hParams)
    end

    def controller_query(sObjectType, sQuery, hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @definition
      @definition.controller_query(sObjectType, sQuery, hParams)
    end

    def controller_update(sObjectType, hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @definition
      @definition.controller_update(sObjectType, hParams)
    end

    def controller_delete(sObjectType, hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @definition
      @definition.controller_delete(sObjectType, hParams)
    end

    def controller_get(sObjectType, sId, hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @definition
      @definition.controller_get(sObjectType, sId, hParams)
    end
  end

  # class describing generic Object Process
  # with process calls
  class BaseProcess
    def process_create(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.process_create(sObjectType)
    end

    def process_query(sObjectType, sQuery)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.process_query(sObjectType, sQuery)
    end

    def process_update(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.process_update(sObjectType)
    end

    def process_get(sObjectType, sId)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.process_get(sObjectType, sId)
    end

    def process_delete(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.process_delete(sObjectType)
    end
  end

  # class describing generic Object Process
  # with additionnal functions
  class BaseProcess
    private

    def query_cache_cleanup(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.query_cleanup(sObjectType)
    end

    def object_cache_cleanup(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.object_cleanup(sObjectType)
    end

    def controler
      PrcLib.warning('controler object call is obsolete. Please update your'\
                     " code. Use controller_<action> instead.\n%s", caller)
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @definition
      @definition
    end

    def object
      PrcLib.warning('object call is obsolete. Please update your code.'\
                     "Use <Action> instead.\n%s", caller)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition
    end

    def format_object(sObjectType, oMiscObj)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.format_object(sObjectType, oMiscObj)
    end

    def format_query(sObjectType, oMiscObj, hQuery)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.format_list(sObjectType, oMiscObj, hQuery)
    end

    def data_objects(sObjectType, *key)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.data_objects(sObjectType, *key)
    end

    def get_data(oObj, *key)
      PrcLib.warning('get_data call is obsolete. Please update your code. '\
                     "Use [] instead.\n%s", caller)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.get_data(oObj, :attrs, key)
    end

    def register(oObject, sObjectType = nil)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.register(oObject, sObjectType)
    end

    def config
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @definition
      @definition.config
    end

    def query_single(sCloudObj, list, sQuery, name, sInfoMsg = {})
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

    def _qs_info(list, items, items_form)
      items_built = []
      if items.is_a?(Array)
        items.each do | key |
          items_built << list[0, key]
        end
      else
        items_built << list[0, items]
      end
      format(items_form, items_built)
    end

    def _qs_check_match(list, sQuery)
      list.each do | oElem |
        is_found = true
        sQuery.each do | key, value |
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
