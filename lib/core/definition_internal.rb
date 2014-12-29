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

module Lorj
  # Class Definition internal function.
  class BaseDefinition
    private

    # return Object data meta data.
    def _get_meta_data(key)
      meta_default = Lorj.defaults.get_meta(key)
      return nil if meta_default.nil?
      meta_default = meta_default.clone

      section = Lorj.defaults.get_meta_section(key)
      return meta_default if section.nil?
      meta = PrcLib.model.meta_data.rh_get(section, key)
      return meta_default if meta.nil?

      meta_default.merge!(meta)
    end

    # internal runtime function for process call
    # Get the controller result and map controller object data to
    # lorj object attributes, using controller mapping function.
    #
    # *parameters*:
    #   - +object_type+       : object_type to map
    #   - +oControlerObject+  : Controller object
    #
    # *return*:
    # - value : Hash. return the parameter value.
    #
    # *raise*:
    #
    def _return_map(object_type, oControlerObject)
      return nil if oControlerObject.nil?

      attr_value = {}

      map_handler = _map_identify_mapping_handler(object_type)
      return nil if map_handler.nil?

      object_opts = PrcLib.model.meta_obj.rh_get(object_type)

      maps = object_opts[:returns]
      maps.each do |key, map|
        next unless map

        key_obj = KeyPath.new(key)
        map_obj = KeyPath.new(map)

        value = _call_controller_map(map_handler, oControlerObject,
                                     map_obj.tree)
        value = _mapping_data(object_type, key_obj, object_opts, value)
        attr_value.rh_set(value, key_path.tree)
      end
      attr_value
    end

    # internal runtime function for process call
    # Get the object controller mapping method and method origin.
    #
    # If the object is fully managed by the process, ie no controller
    # object is attached to it, the process will own the mapping method.
    #
    # *parameters*:
    #   - +object_type+       : object_type to map
    #
    # *return*:
    # - map_method    : return the parameter value.
    # - method_name   : Name of the map method.
    # - is_controller : true if the map method is owned by the controller
    #                   false if the map method is owned by the process.
    # - class owner   : Class owner of the map method.
    #
    # *raise*:
    #
    def _map_identify_mapping_handler(object_type)
      proc_name = PrcLib.model.meta_obj.rh_get(object_type,
                                               :lambdas, :get_attr_e)

      is_controller = PrcLib.model.meta_obj.rh_get(object_type,
                                                   :options, :controller)

      return nil if !proc_name && !is_controller

      if proc_name
        map_handler = [@process.method(proc_name), proc_name, false]
        map_handler << @process.class
        return map_handler
      end

      [@controller.method(:get_attr), :get_attr, true, @controller.class]
    end

    # internal runtime function for process call
    # Call the mapping method to get the controller attribute data.
    #
    #
    # *parameters*:
    #   - +map_handler+    : map array returned by _map_identify_mapping_handler
    #   - +controller_obj+ : Controller object
    #   - +attr_tree+      : Array of attribute tree to get the controller data.
    #
    # *return*:
    # - controller data.
    #
    # *raise*:
    #
    def _call_controller_map(map_handler, oControlerObject, attr_tree)
      if map_handler[2]
        type = 'controller'
      else
        type = 'process'
      end
      Lorj.debug(4, "Calling '%s.%s' to retrieve/map %s object '%s' data ",
                 map_handler[3], map_handler[1], type, attr_tree)

      map_handler[0].call(oControlerObject, attr_tree)
    end

    # internal runtime function for process call
    # Do the mapping of the value as defined by obj_needs options:
    # :value_mapping => (Array of attribute tree)
    #
    # *parameters*:
    #   - +object_type+ : Object type to get data mapped.
    #   - +key_obj+     : Attribute to map
    #   - +object_opts+ : Attribute options.
    #   - +value+       : Controller value to map.
    #
    # *return*:
    # - controller data.
    #
    # *raise*:
    #
    def _mapping_data(object_type, key_obj, object_opts, value)
      value_mapping = object_opts.rh_get(:value_mapping, key_obj.fpath)
      if value_mapping && !value.nil?
        value_mapping.each do | map_key, map_value |
          next unless value == map_value
          Lorj.debug(5, "Object '%s' value mapped '%s': '%s' => '%s'",
                     object_type, key_obj.tree,
                     value, map_value)
          return map_key
        end
        runtime_fail("'%s.%s': No controller value mapping for '%s'.",
                     object_type, key_obj.tree, value)
      end

      Lorj.debug(5, "Object '%s' value '%s' extracted: '%s'",
                 object_type, key_obj.tree, value)
      value
    end

    # internal runtime function for process call
    # Check object needs list, to report missing required data.
    # raise a runtime error if at least, one data is not set.
    # It returns a list "missing objects".
    #
    # *parameters*:
    #   - +object_missing+ : Array of missing object for process caller.
    #   - +attr_name+      : attribute/data name
    #   - +attr_options+   : attribute options
    #   - +fname+          : caller function
    #
    # *return*:
    # - Array : missing objects.
    #
    # *raise*:
    # - runtime error if required data is not set. (empty or nil)
    #
    def _check_required(object_type, sEventType, fname)
      object_missing = []

      attr_paths = PrcLib.model.meta_obj.rh_get(object_type,
                                                :params, :keys)
      PrcLib.runtime_fail("'%s' Object data needs not set. Forgot "\
                          'obj_needs?', object_type) if attr_paths.nil?

      if sEventType == :delete_e &&
         @object_data.type?(object_type) != :DataObject
        object_missing << object_type
      end

      attr_paths.each do | _attr_path, attr_options|
        next if attr_options[:for] && !attr_options[:for].include?(sEventType)
        _check_required_attr(object_missing, attr_name, attr_options, fname)
      end
      object_missing
    end

    # internal runtime function
    # Check while the attribute data or object is required, if it is set.
    # raise a runtime error if data is not set.
    # add object in the missing object Array if object is not set.
    #
    # *parameters*:
    #   - +object_missing+ : Array of missing object for process caller.
    #   - +attr_name+      : attribute/data name
    #   - +attr_options+   : attribute options
    #   - +fname+          : caller function
    #
    # *return*:
    #
    # *raise*:
    # - runtime error if required data is not set. (empty or nil)
    #
    def _check_required_attr(object_missing, attr_name, attr_options, fname)
      attr_obj = KeyPath.new(attr_path)

      attr_name = attr_obj.key
      case attr_options[:type]
      when :data
        _check_required_attr_data(attr_name, attr_options, fname)
      when :CloudObject
        if attr_options[:required] &&
           @object_data.type?(attr_name) != :DataObject
          object_missing << attr_name
        end
      end
    end

    # internal runtime function
    # Check while the attribute data is required, if data is not set
    # raise a runtime error if not.
    #
    # *parameters*:
    #   - +attr_name+    : attribute/data name
    #   - +attr_options+ : attribute options
    #   - +fname+        : caller function
    #
    # *return*:
    #
    # *raise*:
    # - runtime error if required data is not set. (empty or nil)
    #
    def _check_required_attr_data(attr_name, attr_options, fname)
      default = attr_options.rh_get(:default_value)

      return unless attr_options[:required]

      if attr_options.key?(:extract_from)
        unless @object_data.exist?(attr_options[:extract_from])
          PrcLib.runtime_fail("key '%s' was not extracted from '%s'"\
                              ". '%s' requirement failed.",
                              attr_name, attr_options[:extract_from], fname)
        end
      elsif @config.get(attr_name, default).nil?
        section = Lorj.defaults.get_meta_section(attr_name)
        section = 'runtime' unless section
        PrcLib.runtime_fail("key '%s/%s' is not set. '%s' requirement"\
                            ' failed.', section, attr_name, fname)
      end
    end

    # Obsolete function
    #
    # *parameters*:
    #   -

    #  def _identify_data(object_type, sEventType, data_type = :data)
    #  data_array = []
    #
    # key_paths = PrcLib.model.meta_obj.rh_get(object_type,
    #                         :params, :keys)
    #  runtime_fail("'%s' Object data needs not set. Forgot obj_needs?",
    #  object_type) if key_paths.nil?
    #
    #  key_paths.each do | sKeypath, hParams|
    #  next if hParams[:for] && !hParams[:for].include?(sEventType)
    #  key_path = KeyPath.new(sKeypath)
    #
    #  data_array << key_path.tree if hParams[:type] == data_type
    #  end
    #  data_array
    #  end
  end
end
