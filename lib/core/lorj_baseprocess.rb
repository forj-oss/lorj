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

    def controller_connect(sObjectType, params = nil) #:doc:
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_connect(sObjectType, params)
    end

    def controller_create(sObjectType, params = nil) #:doc:
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_create(sObjectType, params)
    end

    def controller_query(sObjectType, sQuery, params = nil) #:doc:
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_query(sObjectType, sQuery, params)
    end

    def controller_update(sObjectType, params = nil) #:doc:
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_update(sObjectType, params)
    end

    def controller_delete(sObjectType, params = nil) #:doc:
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_delete(sObjectType, params)
    end

    def controller_get(sObjectType, sId, params = nil) #:doc:
      process_error 'No Controler object loaded.' unless @base_object
      params = nil unless params.is_a?(Hash)
      @base_object.controller_get(sObjectType, sId, params)
    end
  end

  # class describing generic Object Process
  # with process calls
  class BaseProcess
    def process_create(sObjectType, hConfig = nil) #:doc:
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_create(sObjectType, hConfig)
    end

    def process_query(sObjectType, sQuery, hConfig = nil) #:doc:
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_query(sObjectType, sQuery, hConfig)
    end

    def process_update(sObjectType, hConfig = nil) #:doc:
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_update(sObjectType, hConfig)
    end

    def process_get(sObjectType, sId, hConfig = nil) #:doc:
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_get(sObjectType, sId, hConfig)
    end

    def process_delete(sObjectType, hConfig = nil) #:doc:
      process_error 'No Base object loaded.' unless @base_object
      @base_object.process_delete(sObjectType, hConfig)
    end
  end

  # class describing generic Object Process
  # with additionnal functions
  class BaseProcess
    private

    def query_cache_cleanup(sObjectType) #:doc:
      fail Lorj::PrcError.new, 'No Base object loaded.' unless @base_object
      @base_object.query_cleanup(sObjectType)
    end

    def object_cache_cleanup(sObjectType) #:doc:
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

    def format_object(sObjectType, oMiscObj) #:doc:
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.format_object(sObjectType, oMiscObj)
    end

    def format_query(sObjectType, oMiscObj, hQuery) #:doc:
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.format_list(sObjectType, oMiscObj, hQuery)
    end

    # Function to provides Lorj Core data cache access.
    #
    # See BaseDefinition#data_objects for details.
    #
    # AVOID CALLING THIS FUNCTION, except in debug case.
    # Usually, if you are using this function to access some data,
    # it means you need to declare those data in your object model.
    #
    # As normally this data should be accessible to the function parameter
    # call. Please review.
    #
    def data_objects(sObjectType, *key) #:doc:
      PrcLib.debug('data_objects is depreciated. To access "%s", you should '\
                   'declare it with obj_needs of "%s". Please update your code'\
                   "\n%s", sObjectType, sObjectType, caller)
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.data_objects(sObjectType, *key)
    end

    # Function to provides Lorj Core data cache access.
    #
    # See BaseDefinition#cache_objects_keys for details.
    #
    def cache_objects_keys #:doc:
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.cache_objects_keys
    end

    def get_data(oObj, *key)
      PrcLib.warning('get_data call is obsolete. Please update your code. '\
                     "Use [] instead.\n%s", caller)
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.get_data(oObj, :attrs, key)
    end

    def register(oObject, sObjectType = nil) #:doc:
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.register(oObject, sObjectType)
    end

    def config #:doc:
      PrcLib.runtime_fail 'No Base object loaded.' unless @base_object
      @base_object.config
    end

    # Function to execute a query and return one or no record.
    #
    # * *Args*
    #   - +type+   : Symbol. meta object type to query.
    #   - +sQuery+ : Hash. Represents the query to execute
    #   - +name+   : String. Human name of the object to search.
    #   - +info+   : List of message to format. This string is printed out
    #     thanks to #Lorj.debug or #PrcLib.info
    #     - :notfound   : not found string formated with: type, name
    #     - :checkmatch : checking match string formated with: type, name
    #     - :nomatch    : No match string formated with: type, name
    #     - :found      : Found string formated with: type, item
    #       item string built from :items and :items_form
    #     - :more       : Found several string formated with: type, name
    #     - :items_form : Combined with :items. Represent a valid format string
    #       for Ruby format function
    #     - :items      : Symbol or Array of Symbol.
    #       List of elements extracted from the first element of the query
    #       result.
    #       It is used to format the `item` string with :items_form format
    #       string.
    #       by default, the element extracted is :name and :items_form is '%s'.
    #
    # * *returns*
    #   - Lorj::Data of type :list. It represents the query result.
    #     It contains 0 or more Lorj::Data of type :data
    #
    # Example: following info is the default setting. If this setting is what
    # want, then info can be missed. Otherwise, set one or all of this setting
    # to change the default query_single print out.
    #
    #    info = {
    #            :notfound => "No %s '%s' found",
    #            :checkmatch => "Found 1 %s. checking exact match for '%s'.",
    #            :nomatch => "No %s '%s' match",
    #            :found => "Found %s '%s'.",
    #            :more => "Found several %s. Searching for '%s'.",
    #            :items_form => '%s',
    #            :items => [:name]
    #           }
    #    item_searched = 'forj'
    #    query = { :name => item_searched }
    #    query_single(:network, query, item_searched, info)
    #    # if no record is found
    #    # => Will print "No network 'forj' found"
    #
    #    # If found one record.
    #    # => Will print "Found 1 network. checking exact match for 'forj'."
    #
    #    # if found but no match the query.
    #    # => Will print "No network 'forj' match"
    #
    #    # if several record is returned:
    #    # => Will print "Found several network. Searching for 'forj'."
    #
    #    # Considering query should return records with at least the attribute
    #    # :name, if the query return the wanted record, :name should be 'forj'.
    #    #
    #    # As defined by :items and :items_form, an item string will be set
    #    # with format('%s', record[:name]). ie 'forj'
    #    # So, in this case, query_single will print "Found network 'forj'."
    def query_single(sCloudObj, sQuery, name, sInfoMsg = {}) #:doc:
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

      info.each { |key, _| info[key] = sInfoMsg[key] if sInfoMsg.key?(key) }
      info
    end
  end
end
