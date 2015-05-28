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

# Lorj implements Lorj::BaseDefinition core internal functions
module Lorj
  # Class Definition internal function.
  class BaseDefinition
    # function to update an existing ObjectData used as parameters to
    # process or controller
    #
    # *parameters*:
    # - data_to_refresh: ObjectData to refresh
    # - refresh_par    : Hash providing the parameter context used to refresh it
    #
    # *return*:
    # - data refreshed.
    #
    def update_params(data_to_refresh, refresh_par) # :nodoc:
      object_type = refresh_par[:object_type]
      event_type = refresh_par[:event_type]
      as_controller = refresh_par[:controller]

      _get_object_params(object_type, event_type, __callee__, as_controller,
                         data_to_refresh)
    end

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
    #     - :type   : hdata requires parameters to be :data.
    #     - :decrypt: true if the data needs to be decrypted automatically.
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

      if param_options[:decrypt].is_a?(TrueClass)
        value = _get_encrypted_value(value, _get_encrypt_key, attr_name)
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
    # - value : return the parameter value or nil if is :CloudObject type.
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
                              self.class, param_name, __callee__
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
    def _get_object_params(object_type, sEventType, fname, as_controller,
                           new_params = nil)
      # Building handler parameters
      # hdata is built for controller. ie, ObjectData is NOT internal.

      obj_params = PrcLib.model.meta_obj.rh_get(object_type, :params, :keys)

      PrcLib.runtime_fail "%s:'%s' Object data needs not set. Forgot "\
                           'obj_needs?', fname, object_type if obj_params.nil?

      if new_params.nil?
        new_params = _obj_param_init(object_type, sEventType, as_controller)
      end

      _object_params_event(object_type, sEventType).each do |param_obj|
        param_options = obj_params[param_obj.fpath]

        value = _build_param(new_params, param_obj, param_options)

        if as_controller && !value.nil?
          _build_hdata(object_type, new_params, param_obj, param_options, value)
        end
      end
      unless fname == :update_params
        new_params.refresh_set(self, object_type, sEventType, as_controller)
      end
      new_params
    end

    # Function to provide a list of valid attributes for an event given.
    #
    # * *args* :
    #   - +object_type+: object_type
    #   - +event_type+ : Can be create_e, delete_e, query_e, get_e
    #   - +param_type+ : Can be nil (default), :data or :CloudObject
    #
    # * *return*:
    #   - params_obj : List of valid attributes (KeyPath type) for
    #     the event given.
    def _object_params_event(object_type, sEventType, param_type = nil)
      obj_params = PrcLib.model.meta_obj.rh_get(object_type, :params, :keys)

      attrs = []
      obj_params.each do |param_path, param_options|
        next unless _param_event?(param_options, sEventType)

        next if param_type && param_type != param_options[:type]

        attrs << KeyPath.new(param_path)
      end
      attrs
    end

    # Internal runtime function checking if the attribute is valid with event
    # query
    #
    # * *args* :
    #   - +param_options+: Parameter options to use.
    #   - +param_path+   : Parameter path to check event
    #   - +event_type+   : Can be create_e, delete_e, query_e, get_e
    #
    # * *return*:
    #   - true if the attribute name is valid for this event.
    #   - false otherwise.
    def _param_event?(param_options, sEventType)
      if param_options.key?(:for)
        return false unless param_options[:for].include?(sEventType)
      end
      true
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
