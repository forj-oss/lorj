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

    # internal runtime function for process call
    # Build a process/controller parameter object (ObjectData)
    #
    # *parameters*:
    #   - +new_params+        : Parameters ObjectData
    #   - +param_object+      : parameter object
    #   - +param_options+     : parameter options
    #
    # *return*:
    # - value : return the parameter value added.
    #           The value comes :
    #   - from an existing param value if the param_options defines
    #     :extract_from
    #   - from config layers if exist
    #   - from param_option[:default_value] if set
    # OR
    # - nil   : if not found
    #
    # *raise*:
    #
    def _build_data(new_params, param_obj, param_options)
      param_name = param_obj.key

      unless param_options[:extract_from].nil?
        value = new_params[param_options[:extract_from]]
        new_params[param_obj.tree] = value
        return value
      end

      return nil unless param_options.key?(:default_value) ||
                        @config.exist?(param_name)

      default = param_options.rh_get(:default_value)
      value = @config.get(param_name, default)
      new_params[param_obj.tree] = value

      value
    end

    # internal runtime function for process call
    # Build a process/controller parameter object (ObjectData)
    #
    # *parameters*:
    #   - +object_type+   : object type needing this parameter.
    #   - +new_params+    : Parameters ObjectData
    #   - +param_obj+     : parameter object
    #   - +param_options+ : parameter options
    #   - +value+         : value to add in hdata Hash.
    #
    # *return*:
    #
    # *raise*:
    #
    def _build_hdata(object_type, new_params, param_obj, param_options, value)
      return unless param_options[:type] == :data

      value_mapping = PrcLib.model.meta_obj.rh_get(object_type, :value_mapping,
                                                   param_obj.fpath)

      attr_name = param_obj.key

      # Mapping from Object/data definition
      if value_mapping.is_a?(Hash)
        PrcLib.runtime_fail("'%s.%s': No value mapping for '%s'",
                            object_type, attr_name,
                            value) unless value_mapping.key?(value)
        value = value_mapping[value]
      end

      return unless param_options[:mapping]

      # NOTE: if mapping is set, the definition subtree
      # is ignored.
      # if key map to mykey
      # [:section1][subsect][key] = value
      # new_params => [:hdata][mykey] = value
      # not new_params => [:hdata][:section1][subsect][mykey] = value
      new_params[:hdata].rh_set(value, param_options[:mapping])
      nil
    end

    # internal runtime function for process call
    # Build a process/controller parameter object (ObjectData)
    #
    # *parameters*:
    #   - +new_params+        : ObjectData. Parameters ObjectData
    #   - +param_path+        : Symbol. parameter name
    #   - +param_options+     : Hash. parameter options
    #
    #
    # *return*:
    # - value : return the parameter value.
    #
    # *raise*:
    #
    def _build_param(new_params, param_obj, param_options)
      param_name = param_obj.key

      case param_options[:type]
      when :data
        return _build_data(new_params, param_obj, param_options)
      when :CloudObject
        if param_options[:required] &&
           @object_data.type?(param_name) != :DataObject
          PrcLib.runtime_fail "Object '%s/%s' is not defined. '%s' "\
                               'requirement failed.',
                              self.class, param_name, fname
        end
        if @object_data.exist?(param_name)
          new_params.add(@object_data[param_name, :ObjectData])
        else
          Lorj.debug(2, "The optional '%s' was not loaded", param_name)
        end
      else
        PrcLib.runtime_fail("Undefined ObjectData '%s'.", param_options[:type])
      end
      nil
    end

    # internal runtime function for process call
    # Build a process parameters object (ObjectData)
    #
    # *parameters*:
    #   - +object_type+       : object type requiring parameters.
    #   - +sEventType+        : event type used to call the process
    #   - +fname+             : caller function
    #
    # *return*:
    # - ObjectData : list of data and objects wanted by the process or
    #                the controller. In case of the controller, hdata
    #                controller map is also added.
    #
    # *raise*:
    # - runtime error if required data is not set. (empty or nil)
    #
    def _get_process_params(object_type, sEventType, fname)
      _get_object_params(object_type, sEventType, fname, false)
    end

    # internal runtime function for process call
    # Build a controller parameters object (ObjectData)
    #
    # *parameters*:
    #   - +object_type+       : object type requiring parameters.
    #   - +sEventType+        : event type used to call the process
    #   - +fname+             : caller function
    #
    # *return*:
    # - ObjectData : list of data and objects wanted by the process or
    #                the controller. In case of the controller, hdata
    #                controller map is also added.
    #
    # *raise*:
    # - runtime error if required data is not set. (empty or nil)
    #
    def _get_controller_params(object_type, sEventType, fname)
      _get_object_params(object_type, sEventType, fname, true)
    end

    # internal runtime function for process call
    # Build a process/controller parameters object (ObjectData)
    #
    # *parameters*:
    #   - +object_type+       : object type requiring parameters.
    #   - +sEventType+        : event type used to call the process
    #   - +fname+             : caller function
    #   - +as_controller+     : true to store parameters for controller.
    #                           false to store parameters for process.
    #
    # *return*:
    # - ObjectData : list of data and objects wanted by the process or
    #                the controller. In case of the controller, hdata
    #                controller map is also added.
    #
    # *raise*:
    # - runtime error if required data is not set. (empty or nil)
    #
    def _get_object_params(object_type, sEventType, fname, as_controller)
      # Building handler parameters
      # hdata is built for controller. ie, ObjectData is NOT internal.

      obj_params = PrcLib.model.meta_obj.rh_get(object_type, :params, :keys)

      PrcLib.runtime_fail "%s:'%s' Object data needs not set. Forgot "\
                           'obj_needs?', fname, object_type if obj_params.nil?

      new_params = _obj_param_init(object_type, sEventType, as_controller)

      obj_params.each do |param_path, param_options|
        if param_options.key?(:for)
          next unless param_options[:for].include?(sEventType)
        end

        param_obj = KeyPath.new(param_path)

        value = _build_param(new_params, param_obj, param_options)

        if as_controller && !value.nil?
          _build_hdata(object_type, new_params, param_obj, param_options, value)
        end
      end
      new_params
    end

    # Internal runtime function for process call
    #
    # initialize Object parameters object (ObjectData)
    # And add the current object in parameters in case we called
    # delete_e handler
    #
    # *parameters*:
    #   - +object_type+  : ObjectData parameters for this object type.
    #   - +sEventType+   : Event handler called
    #   - +as_controller+: true if this will be a controller parameters object.
    #
    # *returns*
    #   - ObjectData: for controller or process
    #
    def _obj_param_init(object_type, sEventType, as_controller)
      new_params = ObjectData.new(!as_controller)

      if sEventType == :delete_e && @object_data.exist?(object_type)
        new_params.add(@object_data[object_type, :ObjectData])
      end
      new_params
    end
    # unused function???
    # def _get_controller_map_value(keypath, sProcessValue)
    #   section = Lorj.defaults.get_meta_section(sData)
    #   section = :runtime if section.nil?
    #   keypath = KeyPath.new(keypath).keyPath
    #   return nil if Lorj.rhExist?(PrcLib.model.meta_data, section, keypath,
    #                               :controller, sProcessValue) != 4
    #   PrcLib.model.meta_data.rh_get(section, keypath,
    #              :controller, sProcessValue)
    # end

    # unused function???
    # def _get_process_map_value(keypath, sControllerValue)
    #   section = Lorj.defaults.get_meta_section(sData)
    #   section = :runtime if section.nil?
    #   keypath = KeyPath.new(keypath).keyPath
    #   return nil if Lorj.rhExist?(PrcLib.model.meta_data, section, keypath,
    #                               :process, sControllerValue) != 4
    #   PrcLib.model.meta_data.rh_get(section, keypath,
    #              :process, sControllerValue)
    # end
  end
end
