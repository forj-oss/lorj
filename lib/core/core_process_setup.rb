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
    # Setup process.
    # The setup process is used to ask the end user to provide some data.
    # You can call it before you run an action, or during a configution setting
    # of your application.
    #
    # setup will be exposed to the end user per several steps, and config data
    # to ask in a specific order, with optionnally some explanations, possible
    # values (hard coded list of values or queried from the model) and default
    # value.
    #
    # Ex:
    # Step 1 description : *Provider configuration*:
    # explanation        : You are going to setup your account information
    #   ask a config data: Enter my account name:  |myuser|
    #   ask others data  : Enter ...
    # Step 2 description : *Another configuration to setup*:
    #   ask several data : Enter ...
    # etc...
    #
    # Steps are predefined in the application defaults.yaml from
    # /:setup/:ask_step
    # Commonly, each step can define the following options:
    # - :desc:            Required. Define the step description.
    #                     ERB template enable. To get config data,
    #                     type <%= config[...] %>
    # - :explanation:  |- Optional. Define a multiline explanation. This is
    #                     printed out in brown color.
    #                     ERB template enable. To get config data, type
    #                     <%= config[...] %>
    #
    # For details or more options, see core_model.rb
    #
    # config data are initially identified by the Object model dependency.
    # (See obj_needs model declaration.)
    #
    # The 'object_type' passed as parameter is the top level object in object
    # dependency.
    # each config data are sorted by object dependencies and additionnal options
    # defined in the application defaults.yaml at:
    # /:section/<section name>/<data>/ See lib/core/code_model.rb
    #
    # setup will ask only data which are configured with :account => true
    # /:section/<section name>/<data>/:account => true
    #
    # Additional config data can added to the list thanks to:
    # /:setup/:ask_step/*:add/*
    #
    # Commonly, each data can define the following options:
    # - :account:           Optional. default: False
    #                       => setup will ask the data only if :account is true
    # - :desc:              Required if :account is true. String. default: nil
    #                       => Description
    # - :explanation:  |-   Print a multiline explanation before asking the data
    #                       ERB template enable. To get config data,
    #                       type <%= config[...] %>
    # - :ask_sort:          Number sort position.
    # - :after:             Name of the previous <Data> to ask before the
    #                       current one.
    # - :depends_on:        Additional data dependency.
    # - :default_value:     Default value at setup time.
    # - :validate:          Regular expression to validate end user input
    #                       during setup.
    # - :list_values:       Additional options to get a list of possible values.
    # - :post_step_function Function to call after data asked to the user.
    #   This function must return a boolean:
    #   - true : The data is accepted and setup will go further.
    #   - false: The data is NOT accepted and setup will ask the data again.
    #     setup will loop until the function is happy with (return true)
    # - :pre_step_function  Function to call before data is asked to the user.
    #   This function must return a boolean:
    #   - true : setup will ask the data.
    #   - false: setup will skip asking the data.
    #
    # For details or more options, see core_model.rb
    #
    # Setup is based on a config object which requires to have at least
    # following functions:
    # - value = get(key, default)
    # - set(key, value)
    # You can create you own config class, derived from Lorj::Config.
    #
    # When setup has done to ask data to the user, the config object is updated.
    # It is up to you and your application to decide what you want to do with
    # those data.
    # Usually, if your application uses setup to setup an account settings
    # Lorj::Account or some local application defaults Lorj::Config, you may
    # want to save them to a configuration file.
    # If you are using Lorj::Account, use function ac_save
    # If you are using Lorj::Config, use function config_save
    #
    # * *Args* :
    #   - +ObjectType+   : Top object type to ask.
    #
    # * *Returns* :
    #   - nothing.
    #
    # * *Raises* :
    #
    def process_setup(sObjectType)
      unless PrcLib.model.meta_obj.rh_exist?(sObjectType)
        PrcLib.runtime_fail "Setup: '%s' not a valid object type."
      end

      Lorj.debug(2, "Setup is identifying account data to ask for '%s'",
                 sObjectType)
      # Loop in dependencies to get list of data object to setup
      setup_steps = _setup_identify(sObjectType, _setup_load)

      Lorj.debug(2, 'Setup check if needs to add unrelated data in the process')
      _setup_check_additional(setup_steps)

      Lorj.debug(2, "Setup will ask for :\n %s", setup_steps.to_yaml)

      _setup_ask(setup_steps)

      PrcLib.info("Configuring account : '#{config[:name]}',"\
                  " provider '#{config[:provider]}'")
    end

    private

    # Internal function to insert the data after several data to ask.
    #
    # * *Args* :
    #   - step          : step structure to update.
    #   - data_to_add   : data to add
    #   - order_index   : last order index of the current step analyzed.
    #
    # * *Returns*:
    #
    # * *Raises* :
    #
    def _setup_data_insert(step, data_to_add)
      order_index = _setup_data_where?(step[:order], data_to_add)

      if order_index.nil?
        level_index = step[:order].keys.max
        step[:order][level_index] << data_to_add
        Lorj.debug(3, "%s/L%s/O%s: '%s' added in setup list at position.",
                   step[:name], level_index,
                   step[:order][level_index].length - 1,
                   data_to_add)
        return
      end
      step[:order][order_index[0]].insert(order_index[1], data_to_add)
      Lorj.debug(3, "%s/L%s/O%s: '%s' added in setup list at position.",
                 step[:name], order_index[0], order_index[1], data_to_add)
    end

    # Internal function to get :after list of data to ask.
    #
    # * *Args* :
    #   - data_to_check : setup data structure to update.
    #
    # * *Returns*:
    #   - Array : List of datas which requires to be ask before.
    #             Empty if not defined.
    #
    # * *Raises* :
    #
    def _setup_data_where?(order, data_to_check)
      res = _setup_data_position?(order, data_to_check)

      return nil if res.nil?

      after_index, before_index, after, before = res

      if after_index.nil? || before_index.nil?
        return before_index if after_index.nil?
        return after_index
      end

      if after_index[0] > before_index[0] ||
         (after_index[0] == before_index[0] && after_index[1] > before_index[1])
        PrcLib.warning("Unable to insert '%s' attribute before '%s' (pos %s)"\
                       " and after '%s' (pos %s). "\
                       "'%s' will be added at the end.",
                       data_to_check, before, before_index, after, after_index,
                       data_to_check)
        return nil
      end

      after_index
    end

    def _setup_data_position?(order, data_to_check)
      meta = _get_meta_data(data_to_check)
      return nil if meta.nil?
      return nil unless meta.rh_exist?(:after) || meta.rh_exist?(:before)

      after = meta.rh_get(:after)
      before = meta.rh_get(:before)
      after_index = nil
      before_index = nil

      order.each do |k, attrs|
        attrs.each do |attr_name|
          after_index = [k, attrs.index(attr_name) + 1] if after == attr_name
          before_index = [k, attrs.index(attr_name)] if before == attr_name
        end
      end

      return nil if after_index.nil? && before_index.nil?

      [after_index, before_index, after, before]
    end

    # check if a config data is already listed in the setup list at a specific
    # step.
    #
    # * *Args* :
    #   - +order_array+   : Array of data classified per level/order
    #   - +data_to_check+ : data to check
    #
    # * *returns* :
    #   - true if found. false otherwise.
    def _setup_attr_already_added?(order_array, data_to_check)
      order_array.each_key do |order_index|
        attributes = order_array[order_index]
        return true unless attributes.index(data_to_check).nil?
      end
      false
    end
  end
end
