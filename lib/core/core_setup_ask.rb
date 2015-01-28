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
    # Internal setup function to ask to the end user.
    # It execute post-process if defined by:
    # /:section/<section name>/<data>/:post_step_function
    #
    # if post-process returns false, the user is requested to re-enter a
    # new value
    #
    # * *Args* :
    #  - +desc+   : Data description
    #  - +data+   : Data to ask.
    #  - +options+: list and validation options
    #
    # * *Returns*:
    #   - value : value entered by the end user.
    #
    # * *Raises* :
    #
    def _setup_ask_data(desc, data, options)
      loop do
        if options[:list_values].nil?
          value = _setup_ask_data_from_keyboard(desc, data, options)
        else
          value = _setup_ask_data_from_list(data, options[:list_values],
                                            desc, options)
        end

        @config.set(data, value)

        section = _get_account_section(data)
        @config.set(data, value, :name =>
                    'account', :section => section) unless section.nil?

        break if options[:post_step_function].nil?

        proc = options[:post_step_function]
        result = @process.method(proc).call

        PrcLib.debug("Warning: '%s' did not return any boolean"\
                     ' value. Ignored', proc) unless result.boolean?

        break unless result.is_a?(FalseClass)
      end
    end

    # Internal setup function to ask to the end user from a list.
    #
    # * *Args* :
    #  - +obj_to_load+ : Object to get list from.
    #  - +list_options+: list and validation options
    #
    # * *Returns*:
    #   - Hash : list of possible values and default.
    #     :default_value : Value pre-selected.
    #     :list          : list of possible values
    #
    # * *Raises* :
    #
    def _setup_choose_list_process(obj_to_load, list_options)
      result = { :list => [], :default_value => nil }
      case list_options[:query_type]
      when :controller_call
        result = _setup_list_from_controller_call(obj_to_load, list_options)
      when :query_call
        result = _setup_list_from_query_call(obj_to_load, list_options)
      when :process_call
        result = _setup_list_from_process_call(obj_to_load, list_options)
      else
        PrcLib.runtime_fail "%s: '%s' invalid query type. valid is: '%s'.",
                            obj_to_load, list_options[:values_type],
                            [:controller_call, :query_call, :process_call]
      end
      result
    end

    # Internal setup function to ask to the end user from a list.
    #
    # * *Args* :
    #  - +data+        : Data to ask.
    #  - +list_options+: list and validation options
    #  - +desc+        : Data description
    #  - +options+     : Used when user have to enter a string instead of
    #                    selecting from a list.
    #
    # * *Returns*:
    #   - value : value entered by the end user.
    #
    # * *Raises* :
    #
    def _setup_ask_data_from_list(data, list_options, desc, options)
      obj_to_load = list_options[:object]

      result = _setup_choose_list_process(obj_to_load, list_options)

      list = result[:list]

      is_strict_list = (list_options[:validate] == :list_strict)

      if list.nil?
        list = []

        if is_strict_list
          PrcLib.fatal(1, "%s requires a value from the '%s' query which is "\
                      'empty.', data, obj_to_load)
        else
          list << 'Not in this list'
        end
      end

      value = _setup_choose_data_from_list(data, desc, list, options)

      if !is_strict_list && value == 'Not in this list'
        value = _setup_ask_data_from_keyboard(desc, data, options,
                                              result[:default_value])
      end
      value
    end

    # Internal setup function to present the list to the user and ask to choose.
    #
    # * *Args* :
    #  - +data+        : Data to ask.
    #  - +desc+        : Data description
    #  - +list+        : list of values to choose
    #  - +options+     : Used when user have to enter a string instead of
    #                    selecting from a list.
    #
    # * *Returns*:
    #   - value : value entered by the end user.
    #
    # * *Raises* :
    #
    def _setup_choose_data_from_list(data, desc, list, options)
      default = @config.get(data, options[:default_value])

      say_msg = format("Select '%s' from the list:", desc)
      say_msg += format(' |%s|', default) unless default.nil?
      say(say_msg)
      value = choose do |q|
        q.choices(*list)
        q.default = default if default
      end
      value
    end

    # Internal setup function to ask to the end user.
    #
    # * *Args* :
    #  - +desc+   : Data description
    #  - +data+   : Data to ask.
    #  - +options+: list and validation options
    #
    # * *Returns*:
    #   - value : value entered by the end user.
    #
    # * *Raises* :
    #
    def _setup_ask_data_from_keyboard(desc, data, options, default = nil)
      valid_regex = nil
      valid_regex = options[:validate] unless options[:validate].nil?

      is_required = (options[:required] == true)
      is_encrypted = options[:encrypted]

      default = options[:default_value] if default.nil?
      default = @config.get(data, default)

      # validate_proc = options[:validate_function]
      proc_ask = options[:ask_function]

      if proc_ask.nil?
        # proc_method = _ask(desc, default, valid_regex,
        #                    is_encrypted, is_required)
        value = _ask(desc, default, valid_regex,
                     is_encrypted, is_required)
      else
        # proc_method = @process.method(proc_ask)
        value = @process.method(proc_ask)
      end

      # loop do
      #   value = proc_method.call(desc, default, valid_regex,
      #                            is_encrypted, is_required)
      #   break if validate_proc.nil?

      #   validate_method = @process.method(validate_proc)
      #   break if validate_method.call(value)
      # end
      value
    end

    # internal runtime function for process call
    # Ask function executed by setup
    #
    # *parameters*:
    #   - +sDesc+       : data description
    #   - +default+     : default value
    #   - +rValidate+   : RegEx to validate the end user input.
    #   - +bEncrypted+  : Encrypt data
    #   - +bRequired+   : true if a value is required.
    #
    # *return*:
    # - value : value or encrypted value.
    #
    # *raise*:
    #
    def _ask(sDesc, default, rValidate, bEncrypted, bRequired)
      value = nil
      loop do
        if bEncrypted
          value = _ask_encrypted(sDesc, default)
        else
          value = ask(format('Enter %s:', sDesc)) do |q|
            q.default = default unless default.nil?
            q.validate = rValidate unless rValidate.nil?
          end
        end
        break unless bRequired && value == ''
        say ANSI.bold('This information is required!')
      end
      value.to_s
    end
  end
end
