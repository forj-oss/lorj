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

require 'highline/import'
require 'erb'

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
  # Adding process core functions.
  class BaseDefinition
    # Load /:setup/:ask_step section of the defaults.yaml
    #
    # See lib/core/core_model.rb
    #
    # * *Returns*:
    #   - hash : setup data structure.
    #
    # * *Raises* :
    #
    def _setup_load
      ask_steps = Lorj.defaults.data.rh_get(:setup, :ask_step)
      setup_steps = []
      ask_steps.each do |value|
        setup_steps << {
          :desc => value[:desc],
          :explanation => value[:explanation],
          :pre_step_handler => value[:pre_step_function],
          :order => [[]], # attributes in array of level/order
          :post_step_handler => value[:post_step_function]
        }
      end
      setup_steps
    end

    # check for any additional data to ask to the user
    # thanks to the /:setup/:ask_step/<steps>/:add option of each steps
    #
    # * *Args* :
    #   - setup_steps : Hash. setup data structure to update.
    #                   It will update setup_steps:/:order 2 dimensions array
    #
    # * *Returns*:
    #
    # * *Raises* :
    #
    def _setup_check_additional(setup_steps)
      setup_steps.each_index do |step|
        value = setup_steps[step]
        next unless value.rh_exist?(:add)

        datas_to_add = value.rh_get(:add)
        datas_to_add.each do |data_to_add|
          order_array = setup_steps[step][:order]
          next if _setup_attr_already_added?(order_array, data_to_add)

          _setup_data_insert(setup_steps, data_to_add, step, order_array.length)
        end
      end
    end

    # Loop on object dependencies to determine the list of attributes to setup.
    #
    #
    # * *Args* :
    #   - setup_steps : Hash. setup data structure to update.
    #                   It will update setup_steps:/:order 2 dimensions array
    #
    # * *Returns*:
    #   - Nothing. But setup_steps is updated.
    #
    # * *Raises* :
    #
    def _setup_identify(sObjectType, setup_steps)
      objs_to_inspect = [sObjectType]
      inspected_objects = []

      while objs_to_inspect.length > 0
        # Identify data to ask
        # A data to ask is a data needs from an object type
        # which is declared in section of defaults.yaml
        # and is declared :account to true (in defaults.yaml or in process
        # declaration - define_data)

        object_type = objs_to_inspect.pop

        Lorj.debug(1, "Checking '%s'", object_type)
        attributes = PrcLib.model.meta_obj.rh_get(object_type,
                                                  :params, :keys)
        if attributes.nil?
          Lorj.debug(1, "Warning! Object '%s' has no data/object needs. Check"\
                        ' the process', object_type)
          next
        end
        attributes.each do |attr_path, attr_params|
          attr_name = KeyPath.new(attr_path).key
          _setup_identify_obj_params(setup_steps,
                                     inspected_objects, objs_to_inspect,
                                     attr_name, attr_params)
        end
      end
    end

    # Internal setup function to identify data to ask
    # Navigate through objects dependencies to determine the need.
    def _setup_identify_obj_params(setup_steps,
                                   inspected_objects, objs_to_inspect,
                                   attr_name, attr_params)

      attr_type = attr_params[:type]

      case attr_type
      when :data
        return unless _setup_obj_param_is_data(setup_steps,
                                               inspected_objects, attr_name)
        inspected_objects << attr_name
        return
      when :CloudObject
        return if objs_to_inspect.include?(attr_name) ||
                  inspected_objects.include?(attr_name)
        # New object to inspect
        objs_to_inspect << attr_name
      end
    end

    def _setup_display_step(setup_step, step)
      Lorj.debug(2, 'Ask step %s:', step)
      puts ANSI.bold(setup_step[:desc]) unless setup_step[:desc].nil?
      begin
        erb_msg = ANSI.yellow(
          erb(setup_step[:explanation])
        ) unless setup_step[:explanation].nil?
      rescue => e
        PrcLib.error "setup step '%d/:explanation' : %s", step, e.message
      end
      puts format("%s\n\n", erb_msg) unless erb_msg.nil?
    end

    # internal setup function to display step information
    #
    # * *Args* :
    #  - +data+    : data name to ask.
    #  - +options+ : data options
    #
    # * *Returns*:
    #  - +desc+ : Description of the data to ask.
    #
    # * *Raises* :
    #
    def _setup_display_data(data, options)
      desc = format("'%s' value", data)

      unless options[:explanation].nil?
        begin
          puts format('%s: %s',
                      data,
                      erb(options[:explanation]))
        rescue => e
          PrcLib.error "setup key '%s/:explanation' : %s", data, e.message
        end
      end

      begin
        desc = erb(options[:desc]) unless options[:desc].nil?
      rescue => e
        PrcLib.error "setup key '%s/:desc' : %s", data, e.message
      end

      desc
    end

    # internal setup core function which ask user to enter values.
    # looping step by step and presenting sorted data to set.
    #
    # It execute pre-process if defined by:
    # /:section/<section name>/<data>/:pre_step_function
    #
    # If pre-process returns true, end user interaction is canceled.
    #
    # * *Args* :
    #  - +setup_steps+ : setup data structure.
    #
    # * *Returns*:
    #
    # * *Raises* :
    #
    def _setup_ask(setup_steps)
      # Ask for user input
      # TODO: Enhance to support section::data to avoid duplicated data name
      #   against sections.
      setup_steps.each_index do |iStep|
        _setup_display_step(setup_steps[iStep], iStep)

        order_array = setup_steps[iStep][:order]

        order_array.each_index do |iIndex|
          Lorj.debug(2, 'Ask order %s:', iIndex)
          order_array[iIndex].each do |data|
            options = _get_meta_data_auto(data)
            options = {} if options.nil?

            data_desc = _setup_display_data(data, options)

            if options[:pre_step_function]
              proc = options[:pre_step_function]
              next unless @process.method(proc).call(data)
            end

            _setup_ask_data(data_desc, data, options)
          end
        end
      end
    end
  end
end
