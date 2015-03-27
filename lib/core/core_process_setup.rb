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
    #   - +sAccountName+ : Optional. Account Name to load if you are using a
    #                      Lorj::Account Object.
    #
    # * *Returns* :
    #   - nothing.
    #
    # * *Raises* :
    #
    def process_setup(sObjectType, sAccountName = nil)
      unless PrcLib.model.meta_obj.rh_exist?(sObjectType)
        PrcLib.runtime_fail "Setup: '%s' not a valid object type."
      end

      setup_steps = _setup_load

      return nil unless _process_setup_init(sAccountName)

      Lorj.debug(2, "Setup is identifying account data to ask for '%s'",
                 sObjectType)
      # Loop in dependencies to get list of data object to setup
      _setup_identify(sObjectType, setup_steps)

      Lorj.debug(2, 'Setup check if needs to add unrelated data in the process')
      _setup_check_additional(setup_steps)

      Lorj.debug(2, "Setup will ask for :\n %s", setup_steps.to_yaml)

      _setup_ask(setup_steps)

      PrcLib.info("Configuring account : '#{sAccountName}',"\
                  " provider '#{config[:provider_name]}'")
    end

    private

    # Internal function to initialize the account.
    #
    # return true if initialized, false otherwise.
    def _process_setup_init(sAccountName)
      return false unless sAccountName

      if @config.ac_load(sAccountName)
        if @config[:provider] != @config[:provider_name]
          s_ask = format("Account '%s' was configured with a different "\
                         "provider '%s'.\nAre you sure to re-initialize this "\
                         "account with '%s' provider instead? "\
                         'All data will be lost',
                         sAccountName, @config[:provider],
                         @config[:provider_name])
          PrcLib.fatal(0, 'Exited by user request.') unless agree(s_ask)
          @config.ac_new(sAccountName, config[:provider_name])
        end
      else
        @config.ac_new(sAccountName, config[:provider_name])
      end
      true
    end

    # Internal function to insert the data after several data to ask.
    #
    # * *Args* :
    #   - data_to_check : setup data structure to update.
    #   - data_to_add   : data to add
    #   - step          : current step analyzed.
    #   - order_index   : last order index of the current step analyzed.
    #
    # * *Returns*:
    #
    # * *Raises* :
    #
    def _setup_data_insert(setup_steps, data_to_add, step, order_index)
      level_index = 0

      _setup_data_after(data_to_add).each do |sAfterKey|
        setup_steps.each_index do |iStepToCheck|
          order_array = setup_steps[iStepToCheck][:order]

          order_array.each_index do |iLevelToCheck|
            data_to_ask = order_array[iLevelToCheck]
            order_to_check = data_to_ask.index(sAfterKey)

            next if order_to_check.nil?

            step = iStepToCheck if iStepToCheck > step
            level_index = iLevelToCheck if iLevelToCheck > level_index
            order_index = order_to_check + 1 if order_to_check + 1 > order_index
            break
          end
        end
      end

      setup_steps[step][:order][level_index].insert(order_index, data_to_add)
      Lorj.debug(3, "S%s/L%s/O%s: '%s' added in setup list at position.",
                 step, level_index, order_index, data_to_add)
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
    def _setup_data_after(data_to_check)
      meta = _get_meta_data(data_to_check)
      return [] unless meta.rh_exist?(:after)

      datas_after = meta[:after]
      datas_after = [datas_after] unless datas_after.is_a?(Array)
      datas_after
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
      order_array.each_index do |order_index|
        attributes = order_array[order_index]
        return true unless attributes.index(data_to_check).nil?
      end
      false
    end

    # Add the attribute parameter to setup list
    # at the right position, determined by it dependencies.
    #
    # The attribute can be added only if :account is true. Data set in
    # the application defaults.yaml:
    # :sections/<Section>/<Attribute>/:account: true
    #
    # Attributes dependency is first loaded by the lorj object model
    # Each attributes can add more dependency thanks to the application
    # defaults.yaml:
    # :sections/<Section>/<Attribute>/:depends_on (Array of attributes)
    #
    # The attribute step can be set from defaults.yaml as well:
    # :sections/<Section>/<Attribute>/:ask_step (FixNum)
    #
    # The attribute can be asked at a determined index, set in
    # the application defaults.yaml:
    # :sections/<Section>/<Attribute>/:ask_sort: (FixNum)
    #
    # parameters :
    # - +setup_steps+ : setup steps
    # - +attr_name+   : Attribute to add
    def _setup_obj_param_is_data(setup_steps, inspected_objects, attr_name)
      if inspected_objects.include?(attr_name)
        Lorj.debug(2, "#{attr_name} is already asked. Ignored.")
        return false
      end

      meta = _get_meta_data(attr_name)
      return false unless meta.is_a?(Hash)

      ask_step = 0
      ask_step = meta[:ask_step] if meta[:ask_step].is_a?(Fixnum)

      Lorj.debug(3, "#{attr_name} is part of setup step #{ask_step}")
      order_array = setup_steps[ask_step][:order]

      unless meta[:account].is_a?(TrueClass)
        Lorj.debug(2, "'%s' won't be asked during setup."\
                   ' :account = true not set.', attr_name)
        return false
      end

      level_index = _setup_level_index(order_array, attr_name,
                                       meta[:depends_on])

      return true if order_array[level_index].include?(attr_name)

      level = _setup_attr_add(order_array[level_index], attr_name, meta,
                              level_index)
      Lorj.debug(3, "S%s/L%s/%s: '%s' added in setup list. ",
                 ask_step, level, level_index, attr_name)

      true
    end

    # Function to identify level index for an attribute.
    #
    # parameters:
    # - +order_array+ : array of levels of attributes ordered.
    # - +attr_name+   : attribute name
    # - +depends_on+  : Dependency Array.
    #
    # return:
    # - level_index to use.
    def _setup_level_index(order_array, attr_name, depends_on)
      if !depends_on.is_a?(Array)
        PrcLib.warning("'%s' depends_on definition have to be"\
                       ' an array.',
                       attr_name) unless depends_on.nil?
        0
      else
        _setup_find_dep_level(order_array, depends_on)
      end
    end

    # Function to add an attribute to the level layer of the setup array .
    #
    # parameters:
    # - +level_array+ : array of attributes ordered.
    # - +attr_name+   : attribute name
    # - +order_index+ : order index where to insert the attribute.
    #
    def _setup_attr_add(level_array, attr_name, meta, level_index)
      if meta[:ask_sort].is_a?(Fixnum)
        order_index = meta[:ask_sort]
        _setup_attr_add_at(level_array, attr_name, order_index)
        Lorj.debug(3, "S%s/L%s/O%s: '%s' added in setup list. ",
                   meta[:ask_step], level_index, order_index, attr_name)
        "O#{level_index}"
      else
        level_array << attr_name
        Lorj.debug(3, "S%s/L%s/Last: '%s' added in setup list.",
                   meta[:ask_step], level_index, attr_name)
        'Last'
      end
    end

    # Function to insert an attribute at a specific order.
    # It will shift other attributes if needed.
    #
    # parameters:
    # - +level_array+ : array of attributes ordered.
    # - +attr_name+   : attribute name
    # - +order_index+ : order index where to insert the attribute.
    #
    def _setup_attr_add_at(level_array, attr_name, order_index)
      if level_array[order_index].nil?
        level_array[order_index] = attr_name
      else
        level_array.insert(order_index, attr_name)
      end
    end

    # Search for the lowest step to ask an attribute, thanks to dependencies.
    #
    # parameters:
    # - +order_array+ : Array of attributes, at 2 dimensions [step then order]
    # - +attr_dep+    : Array of attributes/objects needed before this
    #                   attribute.
    #
    # returns:
    # - the lowest step index where the attribute can be added.
    def _setup_find_dep_level(order_array, attr_dep)
      level_index = 0

      attr_dep.each do |depend_key|
        order_array.each_index do |iCurLevel|
          if order_array[iCurLevel].include?(depend_key)
            level_index = [level_index, iCurLevel + 1].max
          end
        end
        order_array[level_index] = [] if order_array[level_index].nil?
      end

      level_index
    end
  end
end
