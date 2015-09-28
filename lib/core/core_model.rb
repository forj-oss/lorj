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

# TODO: Move most declaration functions to Model class for simplification.

# - Lorj::Model : Model class reference.
module Lorj
  # Model Object
  class Model
    attr_accessor :meta_obj, :meta_data, :meta_predefined_values
    attr_accessor :query_auto_map, :config

    # Model initialisation
    def initialize
      ###################################################
      # Class management Section
      ###################################################

      # Meta Object declaration structure
      # <Object>
      #   :query_mapping        List of keypath mapped.
      #     <keypath> = <keypath mapped>
      #   :lambdas:
      #     :create_e:          function to call at 'Create' task
      #     :delete_e:          function to call at 'Delete' task
      #     :update_e:          function to call at 'Update' task
      #     :get_e:             function to call at 'Get'    task
      #     :query_e:           function to call at 'Query'  task
      #   :value_mapping:       Define list of Object's key values mapping.
      #     <keypath>           key value mapping lists
      #       <value> = <map>   Define the value mapping.
      #   :returns
      #     <keypath>           key value to extract from controller object.
      #   :params:              Defines CloudData (:data) or object (:CloudObj)
      #                         needs by the <Object>
      #     :keys:              Contains keys in a tree of hash.
      #       <keypath>:        String. One element (string with : and /) of
      #                         :list defining the key
      #         :type:          :data or :CloudObj
      #         :for:           Array of events which requires the data or
      #                         CloudObj to work.
      #         :mapping:       To automatically create a provider hash data
      #                         mapped (hdata).
      #         :required:      True if this parameter is required.
      #         :extract_from:  Array. Build the keypath value from another
      #                         params value.
      #                         Ex: This example will extract :id from
      #                             :security_groups object
      #                             :extract_from => [:security_groups, :id]
      #
      @meta_obj =  {}

      # meta data are defined in defaults.yaml and loaded in Lorj::Default class
      # definition.
      # Cloud provider can redefine ForjData defaults and add some extra
      # parameters.
      # To get Application defaults, read defaults.yaml, under :sections:
      # Those values can be updated by the controller with define_data
      # <Section>:
      #   <Data>:               Required. Symbol/String. default: nil
      #                         => Data name. This symbol must be unique, across
      #                            sections.
      #     :desc:              Required. String. default: nil
      #                         => Description
      #     :explanation:  |-   Print a multiline explanation before ask the key
      #                         value.
      #                         ERB template enable. To get config data,
      #                         type <%= config[...] %>
      #     :readonly:          Optional. true/false. Default: false
      #                         => oForjConfig.set() will fail if readonly is
      #                            true. It can be set, only thanks to:
      #                            - oForjConfig.setup()
      #                              or using private
      #                            - oForjConfig._set()
      #     :account_exclusive: Optional. true/false. Default: false
      #                         => Only oConfig.account_get/set() can handle the
      #                            value
      #                            oConfig.set/get cannot.
      #     :account:           Optional. default: False
      #                         => setup will configure the account with this
      #                           <Data>
      #     :ask_sort:          Number which represents the ask order in the
      #                         step group. (See /:setup/:ask_step for details)
      #     :after:  <Data>     Name of the previous <Data> to ask before the
      #                         current one.
      #     :depends_on:
      #                         => Identify :data type required to be set before
      #                            the current one.
      #     :default_value:     Default value at setup time. This is not
      #                         necessarily the Application default value
      #                         (See /:default)
      #     :validate:          Regular expression to validate end user input
      #                         during setup.
      #     :value_mapping:     list of values to map as defined by the
      #                         controller
      #       :controller:      mapping for get controller value from process
      #                         values
      #         <value> : <map> value map equivalence. See data_value_mapping
      #                         function
      #       :process:         mapping for get process value from controller
      #                         values
      #         <value> : <map> value map equivalence. See data_value_mapping
      #                         function
      #     :default:           Default value. Replace /:default/<data>
      #     :list_values:       Defines a list of valid values for the current
      #                         data.
      #       :query_type       :controller_call to execute a function defined
      #                         in the controller object.
      #                         :process_call to execute a function defined in
      #                         the process object.
      #                         :values to get list of values from :values.
      #       :object           Object to load before calling the function.
      #                           Only :query_type = :*_call
      #       :query_call       Symbol. function name to call.
      #                           Only :query_type = :*_call
      #                         function must return an Array.
      #       :query_params     Hash. Controler function parameters.
      #                           Only :query_type = :*_call
      #       :validate         :list_strict. valid only if value is one of
      #                          thoselisted.
      #       :values:          to retrieve from.
      #                         otherwise define simply a list of possible
      #                         values.
      #       :ask_step:        Step number. By default, setup will determine
      #                         the step, thanks to meta lorj object
      #                         dependencies tree.
      #                         This number start at 0. Each step can be defined
      #                         by /:setup/:ask_step/<steps> list.
      #     :pre_step_function: Process called before asking the data.
      #                         if it returns true, user interaction is
      #                         cancelled.
      #     :post_step_function:Process called after asking the data.
      #                         if it returns false, the user is requested to
      #                         re-enter a new value.
      #
      # :setup:                  This section describes group of fields to ask,
      #                          step by step.
      #     :ask_step:           Define an Array of setup steps to ask to the
      #                          end user. The step order is respected, and
      #                          start at 0
      #     -  :desc:            Define the step description. ERB template
      #                          enable. To get config data, type config[...]
      #        :explanation:  |- Define a multiline explanation. This is printed
      #                          out in brown color.
      #                          ERB template enable. To get config data, type
      #                          <%= config[...] %>
      #        :add:             Define a list of additionnal fields to ask.
      #        - <Data>          Data to ask.
      #
      # :default:                List of <Data> application default values.
      #     <Data> :             Value to use at the config application level.
      @meta_data = {}

      # The Generic Process can pre-define some data and value
      # (function predefine_data)
      # The Generic Process (and external framework call) only knows about
      # Generic data.
      # information used:
      #
      @meta_predefined_values = {}

      # <Data>:                  Data name
      #   :values:               List of possible values
      #      <Value>:            Value Name attached to the data
      #        options:          Options
      #          :desc:          Description of that predefine value.

      @context = {
        :oCurrentObj => nil,    # Defines the Current Object to manipulate
        :needs_optional => nil, # set optional to true for any next needs
        # declaration
        :ClassProcess => nil,   # Current Process Class declaration
        :oCurrentData => nil,   # Current data model declaration
        :oCurrentKey => nil     # Current attribute declaration
      }

      # Available functions for:
      # - BaseDefinition class declaration
      # - Controler (derived from BaseDefinition) class declaration

      @query_auto_map = false

      # Model options
      @options = {}
    end

    # Model options (get/set)
    # Uses Hash merge to set model options.
    def options(options = nil)
      @options.merge!(options) unless options.nil?
      @options
    end

    def [](option)
      return nil if option.nil?
      @options[option] if @options.key?(option)
    end

    def []=(option, value)
      return nil if option.nil?
      @options[option] = value
    end

    # Current Attribute identifier
    #
    # parameters: (Hash)
    # - +option+     : optional. KeyPath or a string.
    #   - if option is a KeyPath, save the keypath.
    #   - if option is a Symbol, consider it as function_name for error report.
    #
    # return:
    # - string : KeyPath attribute
    def attribute_context(options = nil)
      function_name = nil
      function_name = options.to_s if options.is_a?(Symbol)
      @context[:oCurrentKey] = options if options.is_a?(KeyPath)

      msg = ''
      msg += '-' + function_name unless function_name.nil?
      msg += ': No model object attribute context defined. '\
             'Missing attr_mapping or obj_needs?'

      PrcLib.dcl_fail('%s%s', self.class, msg) if @context[:oCurrentKey].nil?

      @context[:oCurrentKey]
    end

    # Internal Current Data identifier
    #
    # parameters: (Hash)
    # - +:data+     : optional. Data name to keep in context.
    #
    # return:
    # - string : Data name
    def data_context(data = nil)
      @context[:oCurrentData] = data unless data.nil?

      data = @context[:oCurrentData]

      PrcLib.dcl_fail('Config data context not set. at least, you '\
                      'need to call define_data before.') if data.nil?

      data
    end

    # Internal Current Process identifier
    # parameters: (Hash)
    # - +:process+        : optional. Process name to keep in context.
    # return:
    # - string : Process name
    def process_context(process = nil)
      @context[:ClassProcess] = process unless process.nil?
      process = @context[:ClassProcess]

      _lorj_dcl_error('Config process context not set. at least, you '\
                      'need to call define_data before.') if process.nil?

      process
    end

    def needs_optional(value = nil)
      @context[:needs_optional] = value unless value.nil? || !value.boolean?
      @context[:needs_optional]
    end

    def needs_setup(value = nil)
      @context[:needs_setup] = value unless value.nil? || !value.boolean?
      @context[:needs_setup]
    end

    # Object Context identifier (get/set)
    # parameters:
    # - options: Hash.
    #   - +:object+        : optional. Object to keep in context.
    #   - +:function_name+ : optional. Symbol. Call function name for error
    #                        report
    # return:
    # - string : Object name
    def object_context(options = nil)
      if options.is_a?(Hash)
        if options.key?(:object)
          @context[:oCurrentObj] = options[:object]
          needs_optional false
          needs_setup false
        end
      else
        options = {}
      end

      msg = ''
      if options.rh_exist?(:function_name) &&
         options[:function_name].is_a?(Symbol)
        msg += '-' + options[:function_name].to_s
      end
      msg += ': No model object context defined. Missing define_obj?'

      PrcLib.dcl_fail('%s%s', self.class, msg) if @context[:oCurrentObj].nil?
      @context[:oCurrentObj]
    end

    def heap(value = nil)
      @context[:heap] = caller[1..-1] if value.is_a?(TrueClass)
      @context[:heap]
    end

    def clear_heap
      @context[:heap] = nil
    end
  end
end
