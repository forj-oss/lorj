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
  # Global Process functions
  class BaseDefinition
    # Process declaration
    # Defines current Process context
    #
    # parameters:
    # - +process_class+ : Process Class object.
    #
    def self.current_process(cProcessClass)
      PrcLib.model.heap true
      PrcLib.model.process_context(cProcessClass)
    end

    # Process declaration
    # Set obj_needs requirement setting to false
    #
    def self.obj_needs_optional
      PrcLib.model.heap true
      PrcLib.model.needs_optional true
    end

    # Process declaration
    # Set obj_needs requirement setting to True
    #
    def self.obj_needs_requires
      PrcLib.model.heap true
      PrcLib.model.needs_optional false
    end

    # Process declaration
    # Defines default process options
    #
    # parameters:
    # - +options+ : Supported options are:
    #   - use_controller : Boolean. True if the model require a controller
    #                      False otherwise. Default is true.
    #
    def self.process_default(hOptions)
      PrcLib.model.heap true
      supported_options = [:use_controller]
      unless hOptions.nil?
        hOptions.each_key do |key|
          case key
          when :use_controller
            value = hOptions.rh_get(:use_controller)
            next unless value.boolean?
            PrcLib.model[key] = hOptions[key]
          else
            PrcLib.dcl_fail("Unknown default process options '%s'. "\
                            "Supported are '%s'",
                            key, supported_options.join(','))
          end
        end
      end
    end
  end

  # Base definition class for Process declaration
  class BaseDefinition
    # Application process or controller to defines an object.
    #
    # The context will be set by this definition for next declaration.
    # Depending on the context, define_obj is not used identically:
    #
    # *Context* : Application Process
    # 'define_obj' is the first object declaration. It sets the object context
    # for next declaration.
    # At least it needs to create an handler or define it with :nohandler: true
    #
    # Usually, this definition is followed by:
    # - def_attribute      : Object attribute list
    # - obj_needs          : Handler parameters needs
    # - undefine_attribute : Remove predefined attributes.
    # - def_query_attribute: Query attribute definition
    #
    # *Context*: Controller
    #
    # A controller uses define_obj to update an existing object.
    # A controller can create a new object, only if the controller
    # defines specific process.
    #
    # Usually, this definition is followed by:
    # - query_mapping     : Adapt query attribute to match controller query
    #                       settings
    # - obj_needs         : Adapt needed parameters, and/or set mapping.
    # - def_hdata         : Define Controller Hash parameter, for handlers.
    # - def_attr_mapping  : Define object attribute mapping.
    # - data_value_mapping: Define Data model values mapping.
    #
    # * *Args*
    #   - type     : Symbol. Object type to declare.
    #   - handlers : Hash. List of Process handler to call for
    #     create/query/get/delete/update/get_attr.
    #     Handlers supported:
    #     - :create_e   : Process function to call with create
    #     - :delete_e   : Process function to call with delete
    #     - :update_e   : Process function to call with update
    #     - :get_e      : Process function to call with get
    #     - :query_e    : Process function to call with query
    #     - :get_attr_e : Process function to call with get_attr
    def self.define_obj(obj_type_name, handlers = nil)
      return nil unless [NilClass, String, Symbol].include?(obj_type_name.class)
      PrcLib.model.heap true

      obj_type_name = obj_type_name.to_sym if obj_type_name.is_a?(String)

      handlers = {} unless handlers.is_a?(Hash)

      lorj_object = PrcLib.model.meta_obj.rh_get(obj_type_name)

      # Checking handlers_options data
      _verify_handlers(obj_type_name, lorj_object, handlers)

      if lorj_object.nil?
        lorj_object = _define_obj_initialize(obj_type_name, handlers)
        PrcLib.model.meta_obj.rh_set(lorj_object, obj_type_name)
      end

      PrcLib.model.object_context(:object => obj_type_name)

      _handler_settings(lorj_object, handlers)

      nil
    end

    # Application process to defines query attributes.
    #
    # This function is depreciated.
    #
    # def_attribute or def_attr_mapping already set the attribute as
    # queriable. If the controller needs to redefine how the attribute is
    # queried, use it will needs to call query_mapping.
    #
    # But from process point of view, all attribute must be queriable.
    #
    # So, use def_attribute(process), then query_mapping(controller)
    def self.def_query_attribute(key)
      PrcLib.model.heap true
      query_mapping(key, key)
    end

    # Available functions exclusively for Controller (derived from
    # BaseDefinition) class declaration

    # Following functions are related to Object Attributes
    # ----------------------------------------------------

    # Function to declare handlers data/object needs.
    # Used by application process declaration and controller declaration
    # to defines the object data needs or sub-object dependency.
    #
    # The application process declare global objects/data dependency
    # while the controller can complete it with any needed other object/data
    # as required by the controller code.
    #
    # Ex: A process can define a generic connection object.
    #     define_obj :connection
    #     obj_needs :data, :user,   :for => [:create_e]
    #     obj_needs :data, :passwd, :for => [:create_e]
    #
    #     The controller can add several other needs, specifically
    #     to this controller.
    #
    #     define_obj :connection
    #     obj_needs :data, :user,   mapping => :username
    #     obj_needs :data, :uri
    #
    # Requires Object context
    #
    # parameters:
    # - +type+    : :data or :object requirement
    # - +name+    : Name of the data or the object.
    # - +options+ : Possible options
    #   - :for    : Array: requirement for a limited list of handler.
    #               By default, all handlers requires this data or object.
    def self.obj_needs(type, name, options = {})
      return nil unless [String, Symbol].include?(type.class)
      return nil unless [String, Symbol, Array].include?(name.class)
      PrcLib.model.heap true

      type = type.to_sym if type.is_a?(String)

      options = {} unless options.is_a?(Hash)

      unless options.key?(:required)
        options[:required] = !PrcLib.model.needs_optional
      end

      _configure_options_handlers(options)

      params = PrcLib.model.meta_obj.rh_get(PrcLib.model.object_context,
                                            :params)

      _define_object_needs(params, type,
                           _initialize_object_needs(name), options)
    end

    # Function used by the Process to define Model Object attributes.
    # By default, any attributes are queriable as well. No need to call
    # query_mapping
    #
    # parameters:
    # - +key+    : name of the default object attribute
    # - +options+: optional.
    def self.def_attribute(key, options = {})
      PrcLib.model.heap true

      key_path = _set_attr_mapping(key, key, options)[0]

      Lorj.debug(4, "%s: Defining object attribute '%s'",
                 PrcLib.model.object_context, key_path)
    end

    # Process to undeclare default lorj object attributes
    # By default, while process declares a new lorj object,
    # :id and :name are predefined.
    # If the model of this lorj object do not have any ID or Name
    # the process will needs to undeclare it.
    #
    # The Controller can undeclare some attribute defined by the
    # Application process model. But it requires the controller to
    # re-define any object handler which can use those attributes.
    #
    # parameters:
    # - +key+ : Attribute name to undeclare.
    def self.undefine_attribute(key)
      return nil unless [String, Symbol].include?(key.class)
      PrcLib.model.heap true

      PrcLib.dcl_fail('%s: No Object defined. Missing define_obj?',
                      self.class) if PrcLib.model.object_context.nil?

      key_path = KeyPath.new(key)

      PrcLib.model.meta_obj.rh_set(nil, PrcLib.model.object_context,
                                   :returns, key_path.fpath)
      PrcLib.model.attribute_context key_path
      Lorj.debug(4, "%s: Undefining attribute mapping '%s'",
                 PrcLib.model.object_context, key_path.fpath)

      _query_mapping(key, nil)
    end

    # Process or controller to defines or update data model options
    # Possible data model options are defined definition under <section>/<data>
    # of defaults.yaml
    #
    # Parameters:
    # - +data+    : String/Symbol. Name of the data
    # - +options+ : Hash. List of options
    def self.define_data(data, options)
      return nil unless [String, Symbol].include?(data.class)
      return nil if options.class != Hash
      PrcLib.model.heap true

      data = KeyPath.new data, 2
      PrcLib.dcl_fail("%s: Config data '%s' unknown",
                      self.class,
                      data) unless Lorj.data.auto_meta_exist?(data.key)

      PrcLib.model.data_context data

      section, key = Lorj.data.first_section(data.key)

      Lorj.data.define_controller_data(section, key, options)
    end

    # Controller to declare a model Data value mapping
    #
    # Parameters:
    # - +value+ : Value to map
    # - +map+   : Value mapped
    def self.data_value_mapping(value, map)
      return nil unless _decl_data_valid?(value, map)
      PrcLib.model.heap true

      data = PrcLib.model.data_context

      section = _section_from(data)

      Lorj.debug(2, format("%s/%s: Define config data value mapping: '%s' => "\
                           "'%s'", section, data.fpath, value, map))
      PrcLib.model.meta_data.rh_set(map, section, data,
                                    :value_mapping,  :controller, value)
      PrcLib.model.meta_data.rh_set(value, section, data,
                                    :value_mapping,  :process, map)
    end

    def self.defined?(objType)
      PrcLib.model.heap true
      @obj_type.include?(objType)
    end

    # Internal BaseDefinition function

    def self.predefine_data_value(data, hOptions)
      PrcLib.model.heap true
      # Refuse to run if not a
      return nil if self.class != BaseDefinition
      # BaseDefinition call
      return nil unless [String, Symbol].include?(value.class)
      return nil unless [NilClass, Symbol, String].include?(map.class)

      key_path = PrcLib.model.attribute_context

      value = { data => { :options => hOptions } }

      PrcLib.model.predefine_data_value.rh_set(value,
                                               key_path.fpath, :values)
    end

    # function to interpret a template data, and use ERBConfig as data context.
    # ERBConfig contains config object only.
    def erb(str)
      ERB.new(str).result(@erb_config.get_binding)
    end
  end

  ##############################################################
  # Completing BaseDefinition with Exclusive controller functions
  class BaseDefinition
    attr_writer :obj_type

    # Controller declaration to map an query attribute
    # By default, def_attribute configure those attributes as queriable.
    # The controller can redefine the query part.
    # Use def_attribute or def_attr_mapping
    # All attributes are considered as queriable.
    def self.query_mapping(key, map)
      PrcLib.model.heap true
      _query_mapping(key, map)
    end

    # Function used by the controler to define mapping.
    # By default, any attributes are queriable as well. No need to call
    # query_mapping
    #
    # parameters:
    # - +key+    : name of the default object attribute
    # - +map+    : optional.
    # - +options+: optional.
    def self.def_attr_mapping(key, map, options = {})
      PrcLib.model.heap true
      key_paths = _set_attr_mapping(key, map, options)

      Lorj.debug(4, "%s: Defining object attribute mapping '%s' => '%s'",
                 PrcLib.model.object_context, key_paths[0], key_paths[1])
    end

    # Controller to declare an lorj object attribute data mapping.
    #
    # You need to define object and attribute context before attr_value_mapping
    #
    # parameters:
    # - +value+ : name of the default object attribute
    # - +map+   : Map a predefined object attribute value.
    #
    # Ex: If the application model has defined:
    #     :server[:status] = [:create, :boot, :active]
    #
    #  define_obj :server # Required to set object context
    #  get_attr_mapping :status, :state # set attribute mapping and context.
    #  attr_value_mapping :create, 'BUILD'
    #  attr_value_mapping :boot,   :boot
    #  attr_value_mapping :active, 'ACTIVE'
    #
    def self.attr_value_mapping(value, map)
      PrcLib.model.heap true

      return nil unless _decl_data_valid?(value, map)

      object_type = PrcLib.model.object_context

      key_path = PrcLib.model.attribute_context __callee__

      keypath = key_path.fpath
      Lorj.debug(2, "%s-%s: Attribute value mapping '%s' => '%s'",
                 object_type, key_path.to_s, value, map)
      PrcLib.model.meta_obj.rh_set(map,
                                   object_type, :value_mapping, keypath, value)
    end

    # Controller to declare predefined Hash options for controller wrapper code.
    #
    # When a controller wrapper code is called to execute a function,
    # the controller may/should provides some options.
    #
    # lorj framework can simplify the way to call this function
    # and provide a predefined options list, prepared by lorj.
    #
    # Ex: If you are calling a connection function, which requires one
    #     or more parameters passed as an Hash:
    # wrapper code without using :hdata:
    #   def connect(params)
    #      options = { :hp_access_key => params[:account_id],
    #                  :hp_secret_key => params[:account_key]
    #                  :hp_auth_uri => params[:auth_uri]
    #                  :hp_tenant_id => params[:tenant]
    #                  :hp_avl_zone => params[:network]
    #      }
    #      Fog::HP::Network.new(options)
    #   end
    #
    # wrapper code  using :hdata and def_hdata:
    #   def connect(params)
    #      Fog::HP::Network.new(params[:hdata])
    #   end
    #
    # def_hdata requires the object context.
    # Ex:
    #   define_obj(:student)
    #   def_hdata :first_name
    #   def_hdata :last_name
    #   def_hdata :course,      mapping: :training
    #
    # parameters:
    # - +attr_name+ : Attribute name to add in :hdata Hash
    #                 as hdata[attr_name] = value.
    # - +options+: Possible options:
    #   - :mapping : map name to use mapping instead of attr_name.
    #                hdata[map_name] = value
    #
    #
    def self.def_hdata(attr_name, options = {})
      PrcLib.model.heap true
      fct_context = { :function_name => __callee__ }
      return nil unless [String, Symbol, Array].include?(attr_name.class)

      options = {} unless options.is_a?(Hash)

      object_type = PrcLib.model.object_context(fct_context)

      key_access = KeyPath.new(attr_name).fpath

      # PrcLib.model.meta_obj://<Object>/:params/:keys/<keypath> must exist.
      object_param = PrcLib.model.meta_obj.rh_get(object_type,
                                                  :params, :keys, key_access)

      object_param[:mapping] = attr_name
      object_param[:mapping] = options[:mapping] unless options[:mapping].nil?

      Lorj.debug(2, "%-28s: hdata set '%s' => '%s'",
                 _object_name(object_type), attr_name, object_param[:mapping])

      # Internally, lorj stores this declaration in
      # PrcLib.model.meta_obj://<Object>/:params/:keys/<keypath>/:mapping)
    end
  end

  ##############################################################
  # Completing BaseDefinition with internal functions
  class BaseDefinition
    # Internal function
    def self._query_mapping(key, map)
      return nil unless [String, Symbol].include?(key.class)
      return nil unless [NilClass, Symbol, String].include?(map.class)

      object_type = PrcLib.model.object_context
      key_path = KeyPath.new(key)
      map_path_obj = KeyPath.new(map)

      PrcLib.model.attribute_context key_path

      PrcLib.model.meta_obj.rh_set(map_path_obj.fpath, object_type,
                                   :query_mapping, key_path.fpath)
    end

    # Internal function to store object attribute and mapping information
    # parameters:
    # - +key+    : KeyPath. key object
    # - +map+    : KeyPath. map object
    # - +options+: Hash. Options to set.
    def self._set_attr_mapping(key, map, options)
      return nil unless _decl_object_attr_valid?(key, map, options)

      object_type = PrcLib.model.object_context
      key_path_obj = KeyPath.new(key)

      map_path_obj = KeyPath.new(map)

      PrcLib.model.meta_obj.rh_set(map_path_obj.fpath, object_type,
                                   :returns, key_path_obj.fpath)

      PrcLib.model.attribute_context key_path_obj

      return if options[:not_queriable] == true
      query_mapping(key, map)
      [key_path_obj.fpath, map_path_obj.fpath]
    end

    # Internal section detection based on a keyPath Object
    def self._section_from(data)
      return data.key[0] if data.length == 2
      section = Lorj.defaults.get_meta_section(data.key)
      section = :runtime if section.nil?

      section
    end

    # Internal model data validation
    # return true if valid. false otherwise.
    def self._decl_object_attr_valid?(key, map, options)
      return false unless [String, Symbol].include?(key.class)
      return false unless options.is_a?(Hash)
      return false unless [Symbol, String, Array].include?(map.class)

      true
    end

    # Internal model data validation
    # return true if valid. false otherwise.
    def self._decl_data_valid?(value, map)
      return false unless [String, Symbol].include?(value.class)
      return false unless [NilClass, Symbol, String].include?(map.class)
      true
    end

    # Internal function to get the object_name as class.object
    #
    # return formated string.
    def self._object_name(name)
      format("'%s.%s'", self.class, name)
    end

    # Internal function for obj_needs
    # Initialize :params/:keys/
    def self._initialize_object_needs(name)
      top_param_obj = PrcLib.model.meta_obj.rh_get(PrcLib.model.object_context,
                                                   :params)

      PrcLib.model.attribute_context KeyPath.new(name)
      key_access = PrcLib.model.attribute_context.fpath

      unless top_param_obj[:keys].key?(key_access)
        top_param_obj[:keys][key_access] = {}
        return 'New'
      end

      'Upd'
    end

    # Internal function
    def self._define_object_needs(params, type, msg_action, options)
      attribute = PrcLib.model.attribute_context

      case type
      when :data
        return _obj_needs_data(params[:keys][attribute.fpath],
                               msg_action, options)
      when :CloudObject, :object
        return _obj_needs_object(params[:keys][attribute.fpath],
                                 options)
      end
      PrcLib.dcl_fail("%s: Object parameter type '%s' unknown.",
                      self.class, type)
    end

    # Internal function
    def self._configure_options_handlers(options)
      for_events = PrcLib.model.meta_obj.rh_get(PrcLib.model.object_context,
                                                :lambdas).keys
      options.merge(:for => for_events) unless options.key?(:for)
    end
  end

  ##############################################################
  # Completing BaseDefinition with internal functions for obj_needs
  class BaseDefinition
    # Internal function
    def self._obj_needs_data(object_attr, msg_action, new_params)
      attr_name = PrcLib.model.attribute_context
      if Lorj.data.auto_meta_exist?(attr_name)
        Lorj.debug(2, "%-28s: %s predefined config '%s'.",
                   _object_name(PrcLib.model.object_context),
                   msg_action, attr_name)
      else
        Lorj.debug(2, "%-28s: %s runtime    config '%s'.",
                   _object_name(PrcLib.model.object_context),
                   msg_action, attr_name)
      end
      # Merge from predefined params, but ensure type is never updated.
      object_attr.merge!(new_params.merge(:type => :data))
    end

    # Internal function
    def self._obj_needs_object(object_attr, new_params)
      attr_name = PrcLib.model.attribute_context
      unless PrcLib.model.meta_obj.key?(attr_name.key)
        PrcLib.dcl_fail("%s: '%s' not declared. Missing define_obj(%s)?",
                        self.class,
                        attr_name,
                        attr_name)
      end
      # Merge from predefined params, but ensure type is never updated.
      object_attr.merge!(new_params.merge(:type => :CloudObject))
    end

    # Internal function
    def self._define_obj_initialize(obj_type_name, handlers)
      use_controller = PrcLib.model[:use_controller]

      if use_controller.nil?
        PrcLib.model.options :use_controller => true
        use_controller = true
      end

      # TODO: Cleanup un-used 2 levels :params/:keys by single :params
      object = { :lambdas => { :create_e => nil, :delete_e => nil,
                               :update_e => nil, :get_e => nil,
                               :query_e => nil, :get_attr_e => nil },
                 :params =>  { :keys => {} },
                 :options => { :controller => use_controller },
                 :query_mapping => { ':id' => ':id', ':name' => ':name' },
                 :returns => { ':id' => ':id', ':name' => ':name' }
               }

      PrcLib.dcl_fail("A new declared object '%s' requires at "\
                      'least one handler. Ex: define_obj :%s, '\
                      'create_e: myhandler or nohandler: true',
                      obj_type_name,
                      obj_type_name) if handlers.length == 0

      if !handlers.rh_get(:nohandler)
        msg = '%-28s object declared.'
      else
        msg = '%-28s meta object declared.'
      end
      Lorj.debug(2, msg, _object_name(obj_type_name))
      object
    end

    # Internal function for define_obj
    # Check handler options.
    # Return the list of handlers set if handler list is ok (exist 1 at least)
    # return false if no handler is set.
    def self._verify_handlers(type_name, object, handlers)
      return false if handlers.rh_get(:nohandler)

      PrcLib.dcl_fail("A new declared object '%s' requires at "\
                      'least one handler. Ex: define_obj :%s, '\
                      'create_e: myhandler or nohandler: true',
                      type_name, type_name) if object.nil? &&
                                               handlers.length == 0

      return handlers if object.nil?

      handlers_list = object[:lambdas].keys.join(', ')
      handlers.each_key do |key|
        next if object.rh_exist?(:lambdas, key)

        PrcLib.dcl_fail("'%s' parameter is invalid. Use '%s'",
                        key, handlers_list)
      end
      handlers
    end

    # Setting procs
    def self._handler_settings(object, handlers_options)
      handlers_dcl = object[:lambdas]
      process_context = PrcLib.model.process_context

      handlers_dcl.each_key do |key|
        next unless handlers_options.key?(key)

        # Warning! Use BaseProcess._instance_methods Compatibility function
        # instead of BaseProcess.instance_methods
        unless process_context._instance_methods.include?(handlers_options[key])
          PrcLib.dcl_fail("'%s' parameter requires a valid instance method"\
                          " '%s' in the process '%s'.",
                          key, handlers_options[key], process_context)
        end
        if handlers_options[key] == :default
          # By default, we use the event name as default function to call.
          # Those function are predefined in ForjController
          # The Provider needs to derive from ForjController and redefine those
          # functions.
          object[:lambdas][key] = key
        else
          # If needed, ForjProviver redefined can contains some additionnal
          # functions to call.
          object[:lambdas][key] = handlers_options[key]
        end
      end
    end
  end
end
