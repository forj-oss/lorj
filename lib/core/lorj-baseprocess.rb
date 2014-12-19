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
# - controler (BaseControler) : If a provider is defined, define how will do object creation/etc...
# - definition(BaseDefinition): Functions to declare objects, query/data mapping and setup
# this task to make it to work.

module Lorj
  # class describing generic Object Process
  # Ex: How to get a Network Object (ie: get a network or create it if missing)
  class BaseProcess
    def initialize
      @oDefinition = nil
    end

    def set_BaseObject(oDefinition)
      @oDefinition = oDefinition
    end

    def controller_connect(sObjectType, _hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @oDefinition
      @oDefinition.connect(sObjectType)
    end

    def controller_create(sObjectType, _hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @oDefinition
      @oDefinition.create(sObjectType)
    end

    def controller_query(sObjectType, sQuery, _hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @oDefinition
      @oDefinition.query(sObjectType, sQuery)
    end

    def controller_update(sObjectType, _hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @oDefinition
      @oDefinition.update(sObjectType)
    end

    def controller_delete(sObjectType, _hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @oDefinition
      @oDefinition.delete(sObjectType)
    end

    def controller_get(sObjectType, sId, _hParams = {})
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @oDefinition
      @oDefinition.get(sObjectType, sId)
    end

    def Create(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.Create(sObjectType)
    end

    def Query(sObjectType, sQuery)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.Query(sObjectType, sQuery)
    end

    def Update(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.Update(sObjectType)
    end

    def Get(sObjectType, sId)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.Get(sObjectType, sId)
    end

    def Delete(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.Delete(sObjectType)
    end

    private

    def query_cache_cleanup(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.query_cleanup(sObjectType)
    end

    def object_cache_cleanup(sObjectType)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.object_cleanup(sObjectType)
    end

    def controler
      PrcLib.warning("controler object call is obsolete. Please update your code. Use controller_<action> instead.\n%s" % caller)
      fail Lorj::PrcError.new, 'No Controler object loaded.' unless @oDefinition
      @oDefinition
    end

    def object
      PrcLib.warning("object call is obsolete. Please update your code. Use <Action> instead.\n%s" % caller)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition
    end

    def format_object(sObjectType, oMiscObj)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.format_object(sObjectType, oMiscObj)
    end

    def format_query(sObjectType, oMiscObj, hQuery)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.format_list(sObjectType, oMiscObj, hQuery)
    end

    def DataObjects(sObjectType, *key)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.DataObjects(sObjectType, *key)
    end

    def get_data(oObj, *key)
      PrcLib.warning("get_data call is obsolete. Please update your code. Use [] instead.\n%s" % caller)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.get_data(oObj, :attrs, key)
    end

    def register(oObject, sObjectType = nil)
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.register(oObject, sObjectType)
    end

    def config
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @oDefinition
      @oDefinition.config
    end

    def query_single(sCloudObj, oList, sQuery, name, sInfoMsg = {})
      oList = controller_query(sCloudObj, sQuery)
      sInfo = {
        notfound: "No %s '%s' found",
        checkmatch: "Found 1 %s. checking exact match for '%s'.",
        nomatch: "No %s '%s' match",
        found: "Found %s '%s'.",
        more: "Found several %s. Searching for '%s'.",
        items_form: '%s',
        items: [:name]
      }
      sInfo[:notfound]     = sInfoMsg[:notfound]   if sInfoMsg.key?(:notfound)
      sInfo[:checkmatch]   = sInfoMsg[:checkmatch] if sInfoMsg.key?(:checkmatch)
      sInfo[:nomatch]      = sInfoMsg[:nomatch]    if sInfoMsg.key?(:nomatch)
      sInfo[:found]        = sInfoMsg[:found]      if sInfoMsg.key?(:found)
      sInfo[:more]         = sInfoMsg[:more]       if sInfoMsg.key?(:more)
      sInfo[:items]        = sInfoMsg[:items]      if sInfoMsg.key?(:items)
      sInfo[:items_form]   = sInfoMsg[:items_form] if sInfoMsg.key?(:items_form)
      case oList.length
         when 0
           PrcLib.info(sInfo[:notfound] % [sCloudObj, name])
           oList
         when 1
           Lorj.debug(2, sInfo[:checkmatch] % [sCloudObj, name])
           element = nil
           oList.each do | oElem |
             bFound = true
             sQuery.each do | key, value |
               if oElem[key] != value
                 bFound = false
                 break
               end
             end
             :remove unless bFound
           end
           if oList.length == 0
             PrcLib.info(sInfo[:nomatch] % [sCloudObj, name])
           else
             sItems = []
             if sInfo[:items].is_a?(Array)
               sInfo[:items].each do | key |
                 sItems << oList[0, key]
               end
             else
               sItems << oList[0, sInfo[:items]]
             end
             sItem = sInfo[:items_form] % sItems
             PrcLib.info(sInfo[:found] % [sCloudObj, sItem])
           end
           oList
         else
           Lorj.debug(2, sInfo[:more] % [sCloudObj, name])
           # Looping to find the one corresponding
           element = nil
           oList.each do | oElem |
             bFound = true
             sQuery.each do | key, value |
               if oElem[key] != value
                 bFound = false
                 break
               end
             end
             :remove unless bFound
           end
           if oList.length == 0
             PrcLib.info(sInfo[:notfound] % [sCloudObj, name])
           else
             sItems = []
             if sInfo[:items].is_a?(Array)
               sInfo[:items].each do | key |
                 sItems << oList[0, key]
               end
             else
               sItems << oList[0, sInfo[:items]]
             end
             sItem = sInfo[:items_form] % sItems
             PrcLib.info(sInfo[:found] % [sCloudObj, sItem])
           end
           oList
      end
    end
  end
end
