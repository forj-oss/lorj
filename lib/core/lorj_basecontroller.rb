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
  # Defining basic Controller functions
  class BaseController
    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Create functions.
    def connect(_sObjectType, _hParams)
      controller_error 'connect has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Create functions.
    def create(_sObjectType, _hParams)
      controller_error 'create_object has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Delete functions.
    def delete(_sObjectType, _hParams)
      controller_error 'delete_object has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Get functions.
    def get(_sObjectType, _sUniqId, _hParams)
      controller_error 'get_object has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Query functions.
    def query(_sObjectType, _sQuery, _hParams)
      controller_error 'query_object has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Update functions.
    def update(_sObjectType, _oObject, _hParams)
      controller_error 'update_object has not been redefined by the controller.'
    end

    # Simply raise an error
    #
    # * *Args*    :
    #   - +Msg+ : Error message to print out.
    # * *Returns* :
    #   - nil
    # * *Raises* :
    #  - Lorj::PrcError
    def controller_error(msg, *p)
      msg = format(msg, *p)
      fail Lorj::PrcError.new, format('%s: %s', self.class, msg)
    end

    # check if required data is loaded. raise an error if not
    #
    # * *Args*    :
    #   - +Params+ : Lorj::ObjectData object for controller.
    #   - +key+    : Key to check.
    # * *Returns* :
    #   - nil
    # * *Raises* :
    #   - +Error+ if the key do not exist.
    def required?(oParams, *key)
      if oParams.exist?(key)
        if RUBY_VERSION =~ /1\.8/
          #  debugger # rubocop: disable Lint/Debugger
          if oParams.otype?(*key) == :DataObject &&
             oParams[key, :ObjectData].empty?
            controller_error '%s is empty.', key
          end
        else
          if oParams.type?(*key) == :DataObject &&
             oParams[key, :ObjectData].empty?
            controller_error '%s is empty.', key
          end
        end
        return
      end
      controller_error '%s is not set.', key
    end
  end

  # Defining private internal controller functions
  class BaseController
    private

    # controller helper function:
    # This helper controller function helps to query and object list
    # from a Lorj query Hash. See query Hash details in #ctrl_query_match.
    #
    # * *args*:
    #   - +objects+ : Collection of object which respond to each
    #   - +query+   : Hash. Containing a list of attributes to test
    #     See #ctrl_do_query_match for details
    #   - +triggers+: Hash. Optional. Procs to interact at several places:
    #     - :before  : &code(object) - To execute some code on the object
    #       before extract.
    #       *return* true to go on, or false to ignore the object.
    #     - :after   : &code(object, query, selected) - To execute some code on
    #       the object after extract.
    #       This after trigger is the last change to select or not the object
    #       for the query. Note that query structure defined by lorj by default.
    #       *return* true if the object is selected. false otherwise.
    #     - :extract : &code(object, key) - To execute the data extraction
    #       This block is required only if call of [] or :<key> is not supported
    #       *return* the value extracted.
    #
    def ctrl_query_each(objects, query, triggers = {}) # :doc:
      results = []
      Lorj.debug(4, "Filtering with '%s'", query)
      unless objects.class.method_defined?(:each)
        controller_error "'%s' do not have 'each' function.", objects.class
      end
      objects.each do |o|
        trig_ret = _run_trigger(triggers, :before, [TrueClass, FalseClass],
                                true, o, query)
        next unless trig_ret
        if [Proc, Method].include?(triggers[:extract].class)
          code = triggers[:extract]
          selected = ctrl_do_query_match(o, query) { |d, k| code.call d, k }
        else
          selected = ctrl_do_query_match(o, query)
        end
        selected = _run_trigger(triggers, :after, [TrueClass, FalseClass],
                                selected, o, query, selected)
        results.push o if selected
      end
      Lorj.debug(4, '%d records selected', results.length)
      results
    end

    # Internal functions used by #ctrl_query_each to give control
    # on the query feature.
    def _run_trigger(triggers, name, expect, default, *p)
      return default if triggers[name].nil?

      code = triggers[name]
      begin
        trig_ret = code.call(*p)
      rescue
        Lorj.error("trigger '%s' '%s' is in error: \n%s",
                   name, method_name, e)
      end
      method_name = "Unamed #{code.class}"
      method_name = code.name if code.is_a?(Method)
      if expect.length > 0 && !expect.include?(trig_ret.class)
        PrcLib.warning("trigger '%s': Method '%s' should return one of '%s' ."\
                       " It returns '%s'. Ignored.",
                       name, method_name, expect, trig_ret.class)
        return default
      end
      trig_ret
    end

    # controller helper function:
    # Function to return match status
    # from a list of attributes regarding a query attribute list
    #
    # * *args*:
    #   - +object+ : Object to query.
    #   - +query+  : Hash containing a list of attributes to test
    #     The query value support several cases:
    #     - Regexp : must Regexp.match
    #     - default equality : must match ==
    #   - +&block+ : block to extract the object data from a key.
    #
    # * *returns*:
    #   - true if this object is selected by the query.
    # OR
    #   - false otherwise
    #
    # * *exception*:
    #   - No exception
    #
    #   by default, this function will extract data from the object
    #   with following functions: If one fails, it will try the next one.
    #   :[], or :key or &block.
    #   The optional &block is a third way defined by the controller to extract
    #   data.
    #   The &block is defined as followed:
    #   * *args*:
    #     - +object+ : The object to get data from
    #     - +key+    : The key used to extract data
    #   * *returns*:
    #     - value extracted.
    #   * *exception*:
    #     - Any object exception during data extraction.
    #
    def ctrl_do_query_match(object, query)
      return true unless query.is_a?(Hash)

      Lorj.debug(3, "'%s' selected by '%s'?", object.class, query)
      selected = true
      query.each do |key, match_value|
        Lorj.debug(4, "'%s' match '%s'?", key, match_value)
        key_path = KeyPath.new(key)
        if block_given?
          found, v = _get_from(object, key_path.tree) { |d, k| yield d, k }
        else
          found, v = _get_from(object, key_path.tree)
        end

        controller_error("'%s': '%s' not found", object.class, key) unless found

        Lorj.debug(4, "'%s.%s' = '%s'", object.class, key, v)

        %w(regexp hash array default).each do |f|
          t, s = method("lorj_filter_#{f}".to_sym).call v, match_value
          next unless t
          selected &= s
          Lorj.debug(5, "Filter used '%s' returned '%s'", f, s)
          break
        end
        break unless selected
      end
      Lorj.debug(4, 'object selected.') if selected
      selected
    end

    def ctrl_query_select(query, *limit)
      return {} if limit.length == 0
      query.select { |_k, v| limit.include?(v.class) }
    end

    def _get_from(data, *key)
      ret = nil
      found = false
      key.flatten!

      if data.is_a?(Hash)
        found = data.rh_exist?(*key)
        ret = data.rh_get(*key)
        return [found, ret]
      end

      if block_given?
        begin
          Lorj.debug(4, "yield extract '%s' from '%s'", key, data.class)
          return [true, yield(data, *key)]
        rescue => e
          PrcLib.error("yield extract '%s' from '%s' error  \n%s",
                       key, object.class, e)
        end
        return [found, ret]
      end

      [:[], key[0]].each do |f|
        found, ret = _get_from_func(data, key[0], f)
        return _get_from(ret, key[1..-1]) if found && key.length > 1
        break if found
      end
      [found, ret]
    end

    def _get_from_func(data, key, func = nil)
      func = key if func.nil?
      v = nil
      found = false
      if data.class.method_defined?(func)
        begin
          found = true
          if key == func
            Lorj.debug(5, "extract try with '%s.%s'", data.class, func)
            v = data.send(func)
          else
            Lorj.debug(5, "extract try with '%s.%s(%s)'",
                       data.class, func, key)
            v = data.send(func, key)
          end
        rescue => e
          Lorj.debug(5, "'%s': error reported by '%s.%s(%s)'\n%s",
                     __method__, data.class, func, key, e)
          found = false
        end
      end
      [found, v]
    end

    # Function to check if a value match a regexp
    #
    # * *args*:
    #   - value      : The controller value to test matching.
    #   - match_value: RegExp object to match against value.
    #
    # * *returns*:
    #   - treated: true if match_value is RegExp
    #   - status : true if match. false otherwise
    #
    def lorj_filter_regexp(value, match_value) # :doc:
      return [false, false] unless match_value.is_a?(Regexp)

      return [true, true] if match_value.match(value)
      [true, false]
    end

    # Function to check if match_value is found in an Array.
    #
    # * *args*:
    #   - value      : The controller value to test matching.
    #   - match_value: The matching subhash match.
    #     It can be an Array of match_value or just match_value
    #
    # * *returns*:
    #   - treated: true if match_value is Array
    #   - status : true if match. false otherwise
    #
    def lorj_filter_array(value, match_value) # :doc:
      return [false, false] unless value.is_a?(Array) ||
                                   match_value.is_a?(Array)

      if value.is_a?(Array) && match_value.is_a?(Array)
        return [true, (match_value - value).empty?]
      end

      [true, value.include?(match_value)]
    end

    # Function to check if a value match a filter value.
    #
    # * *args*:
    #   - value    : The controller value to test matching
    #   - structure: The matching subhash match.
    #     It will be interpreted by #Lorj::KeyPath.
    #
    # * *returns*:
    #   - treated: true if match_value is Hash
    #   - status : true if match. false otherwise
    #
    def lorj_filter_hash(value, structure) # :doc:
      return [false, false] unless value.is_a?(Hash)

      key_path = KeyPath.new(structure)
      tree = key_path.tree[0..-2]
      return [true, false] unless value.rh_exist?(tree)
      match_value = key_path.key
      res = value.rh_get(tree)
      return lorj_filter_array(res.flatten, match_value) if res.is_a?(Array)
      lorj_filter_default(res, match_value)
    end

    # Function to check if a value match a filter value.
    #
    # * *args*:
    #   - value    : The controller value to test matching
    #   - structure: The matching subhash match.
    #
    # * *returns*:
    #   - treated: true if match_value is Hash
    #   - status : true if match. false otherwise
    #
    def lorj_filter_default(value, match_value) # :doc:
      [true, (value == match_value)]
    end
  end
end
