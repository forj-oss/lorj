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
  class BaseDefinition # rubocop: disable ClassLength
    # Load /:setup/:ask_step section of the data.yaml
    #
    # See lib/core/core_model.rb
    #
    # * *Returns*:
    #   - hash : setup data structure.
    #
    # * *Raises* :
    #
    def _setup_load
      setup_steps = {}

      steps = Lorj.data.setup_data(:steps)
      return setup_steps if steps.nil?

      steps.each do |name, value|
        setup_steps[name] = _setup_load_init(value)
      end

      ask_steps = Lorj.data.setup_data(:ask_step)
      return setup_steps if ask_steps.nil?

      ask_steps.each do |value|
        name = value[:name]
        name = ask_steps.index(value).to_s if name.nil?
        if setup_steps.key?(name)
          setup_steps[name].rh_merge(_setup_load_init(value))
          next
        end
        setup_steps[name] = _setup_load_init(value)
      end

      setup_steps
    end

    def _setup_load_init(value)
      value = {} if value.nil?

      {
        :desc => value[:desc],
        :explanation => value[:explanation],
        :pre_step_handler => value[:pre_step_function],
        :order => [[]], # attributes in array of level/order
        :post_step_handler => value[:post_step_function]
      }
    end

    def _setup_step_definition
      setup_steps = {}
      steps = Lorj.data.setup_data(:steps)
      return setup_steps if steps.nil?

      steps.each do |name, value|
        setup_steps[name] = value
      end

      ask_steps = Lorj.data.setup_data(:ask_step)
      return setup_steps if ask_steps.nil?

      ask_steps.each do |value|
        name = value[:name]
        name = ask_steps.index(value).to_s if name.nil?
        if setup_steps.key?(name)
          setup_steps[name].rh_merge(value)
          next
        end
        setup_steps[name] = value
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
      setup_steps.each do |step|
        step_name = step[:name]
        value = _setup_step_definition
        next unless value.is_a?(Hash) && value.rh_exist?(step_name, :add)

        datas_to_add = value.rh_get(step_name, :add)
        datas_to_add.each do |data_to_add|
          order_array = step[:order]
          next if _setup_attr_already_added?(order_array, data_to_add)

          _setup_data_insert(step, data_to_add)
        end
      end
    end

    # Function to build a step/order structure of Attributes.
    # step/order is an array of array.
    # the first array represents the steps
    # the second array represents the list of attributes in a specific order.
    #
    # This structure is used by setup to ask the list of attributes in a
    # specific order.
    #
    # It loops on object dependencies, then data definition to determine the
    # list of attributes and their required order.
    #
    # A new step is created when an attribute, during setup time requires
    # to query an object, which may requires some additional attributes,
    # considered as dependent attributes.
    # The previous step must contains at least the dependent attributes.
    #
    # Process data definition can influence those detected steps, by assigning
    # an :ask_step to the attribute.
    # Then the default attribute step may be splitted to more steps.
    #
    # You cannot set an attribute step lower then the detected step.
    # Process data definition can influence the attributes order, by assigning
    # an :ask_order to the attribute.
    #
    # :setup section of the process data definition (data.yaml) can set the step
    # description or add some extra attributes (not detected by default)
    #
    # * *Args* :
    #   - sObjectType : Symbol/String. Object type to analyze for list of
    #     attributes to setup
    #   - setup_steps : Hash. setup data structure to update.
    #                   It will update setup_steps:/:order 2 dimensions array
    #
    # * *Returns*:
    #   - setup_steps: Hash updated
    #
    # * *Raises* :
    #
    def _setup_identify(sObjectType, setup_steps)
      # There is 3 sources of data used by setup to build the list of data to
      # setup:
      # - Lorj.data (Lorj::MetaConfig): Process data definition.
      # - config (Lorj::Account)      : Configuration files/runtime data.
      # - PrcLib.model.meta_obj(Hash) : Object definition / mapping

      dependencies = { :objects => {}, :attributes => {} }
      _setup_identify_dep_init(dependencies, sObjectType)

      # Build list of attributes which will be needed for an object and
      # its dependencies

      Lorj.debug(2, '- Checking objects dependencies -')
      _setup_identify_deps(dependencies, sObjectType)

      # Build list of additional attributes and build
      # attribute dependencies thanks to attribute queries.
      Lorj.debug(2, '- Checking attributes dependencies -')
      orders = _setup_build_steps_from(dependencies)

      # Reorganize each required steps thanks to :ask_order
      Lorj.debug(2, '- Re-organizing attributes steps/order -')
      attrs = _setup_reorganize_steps_order(dependencies[:attributes], orders)

      # Apply additionnal steps as described by Lorj.data
      Lorj.debug(2, '- Add extra steps -')
      _setup_reorganize_steps(attrs, orders, setup_steps)
    end

    # Internal setup function to parse objects/attributes dependency list
    # and build objects list and required attributes list.
    def _setup_identify_deps(dependencies, object_type, path = [])
      model_object = dependencies.rh_get(:objects, object_type)
      objects_list = PrcLib.model.meta_obj.rh_get(object_type, :params, :keys)
      if objects_list.nil?
        PrcLib.warning("'%s' as object type is not valid. Not declared.")
        return [[], [], []]
      end

      objects = []
      attrs = []
      deps_attrs = []
      deps_objects = []
      new_path = path + [object_type]

      objects_list.each do |attr_path, attr_params|
        a, d_a, o, d_o = _setup_id_each(dependencies, model_object, new_path,
                                        attr_path, attr_params)
        attrs += a
        deps_attrs += d_a
        objects += o
        deps_objects += d_o
      end
      attrs.uniq!
      deps_attrs.uniq!
      objects.uniq!
      deps_objects.uniq!

      _sid_show_debug(3, format("'%s' has ", object_type) + '%s',
                      attrs, objects)
      _sid_show_debug(4, format("'%s' has ", object_type) + 'also indirect %s',
                      deps_attrs, deps_objects)

      [(objects + deps_objects).uniq, attrs, deps_attrs]
    end

    def _setup_id_each(dependencies, model_object, new_path,
                       attr_path, attr_params)
      objects = []
      attrs = []
      deps_attrs = []
      deps_objects = []

      attr_name = KeyPath.new(attr_path).key_tree
      attr_type = attr_params[:type]

      case attr_type
      when :data
        attr_to_add = _setup_id_init_data_deps(dependencies, attr_name)
        if attr_to_add
          model_object[:attrs] << attr_to_add
          attrs << attr_to_add
        end
      when :CloudObject
        if _setup_identify_dep_init(dependencies, attr_name, new_path)
          found_obj,
            found_attrs,
            found_deps_attrs = _setup_identify_deps(dependencies,
                                                    attr_name, new_path)
        else
          found_obj = dependencies.rh_get(:objects, attr_name, :objects)
          found_attrs = dependencies.rh_get(:objects, attr_name, :attrs)
          found_deps_attrs = []
        end
        deps_objects = (deps_objects + found_obj).uniq
        deps_attrs = (deps_attrs + found_attrs + found_deps_attrs).uniq
        model_object[:objects] << attr_name
        objects << attr_name
      end
      [attrs, deps_attrs, objects, deps_objects]
    end

    def _setup_id_init_data_deps(dependencies, attr_name)
      return if dependencies[:attributes].key?(attr_name)

      dependencies.rh_set({}, :attributes, attr_name)
      attr_name
    end

    # Internal setup function to display debug info related to
    # _setup_identify_deps
    def _sid_show_debug(level, str, attrs, objects)
      data = []
      data << format("'%s' attributes", attrs.join(', ')) if attrs.length > 0

      data << format("'%s' objects", objects.join(', ')) if objects.length > 0

      Lorj.debug(level, str, data.join(' and ')) if data.length > 0
    end

    # Internal setup function to build Attribute dependency array
    # based on :depends_on
    #
    # def _setup_identify_attr_depends_on(_attr_name)
    #   attrs_dep = []
    #   num = 0

    #   dependencies[:attributes].each do |attr_name, dep|
    #     next unless dep.nil?
    #     attr_def = Lorj.data.auto_section_data(attr_name)

    #     dependency = []
    #     if attr_def && attr_def[:depends_on].is_a?(Array)
    #       dependency = attr_def[:depends_on].clone
    #     end
    #     attrs_dep[num] = dependency
    #     num += 1
    #   end

    #   attrs_dep
    # end

    # Internal setup function to Reorganize attributes order thanks following
    # data definition:
    #
    # - :sections/<Section>/<Attribute>/:ask_sort: (FixNum)
    #   Defines the list of attributes that needs to be setup before.
    #
    # This function will first of all determine the order thanks
    # to :ask_sort in the current step group.
    def _setup_reorganize_steps_order(attrs, attr_groups)
      attr_groups.collect do |attr_group|
        index = attr_groups.index(attr_group)
        Lorj.debug(3, "Step '%s' analyzing re-organisation", index)
        res = _setup_reorganize_so_sort(attr_group)
        res = _setup_reorganize_so_befaft(res)

        old = attr_group.map { |attr| attr.keys[0] }
        new = res.map { |attr| attr.keys[0] }
        Lorj.debug(3, "Step '%s' reorganized from '%s' to '%s'",
                   index, old, new) unless old == new
        attr_groups[index] = res
      end

      attrs_list = []
      attrs.each do |k, v|
        attrs_list << { k => v }
      end
      res = _setup_reorganize_so_sort(attrs_list)
      res = _setup_reorganize_so_befaft(res)

      old = attrs_list.map { |attr| attr.keys[0] }
      new = res.map { |attr| attr.keys[0] }
      Lorj.debug(3, "unordered reorganized from '%s' to '%s'",
                 old, new) unless old == new
      res
    end

    # Internal setup function to re-organize thanks to :before and :after.
    def _setup_reorganize_so_befaft(attr_group)
      attrs = attr_group.map { |a| a.keys[0] }

      attrs.clone.each do |attr_name|
        meta = _get_meta_data(attr_name)
        next if meta.nil?
        next unless meta.rh_exist?(:after) || meta.rh_exist?(:before)

        if _setup_reorganize_so_befaft_move?(:after, meta, attrs, attr_name)
          _setup_reorganize_so_befaft_move(:after, meta, attrs, attr_group,
                                           attr_name)
        end

        next unless _setup_reorganize_so_befaft_move?(:before, meta, attrs,
                                                      attr_name)

        _setup_reorganize_so_befaft_move(:before, meta, attrs, attr_group,
                                         attr_name)
      end
      attr_group
    end

    # return true if there is a need to move the element before/after
    def _setup_reorganize_so_befaft_move?(where, meta, attrs, attr_name)
      element = meta[where]
      element = nil unless (attrs - [attr_name]).include?(element)

      cur = attrs.index(attr_name)
      return (element && cur < attrs.index(element)) if where == :after
      (element && cur > attrs.index(element))
    end

    # Do the move
    def _setup_reorganize_so_befaft_move(where, meta, attrs, attr_group,
                                         attr_name)
      old = attrs.index(attr_name)
      ref = meta[where]
      new = attrs.index(ref)

      # Must be inserted after the attribute => + 1
      new += 1 if where == :after

      Lorj.debug(5, ":%s: Move '%s' %s '%s'"\
                        " - pos '%s' => pos '%s'",
                 where, attr_name, where, ref, old, new)

      attrs.insert(new, attrs.delete(attr_name))
      attr_group.insert(new, attr_group.delete(attr_group[old]))
    end

    # Internal setup function to re-organize thanks to :ask_sort
    def _setup_reorganize_so_sort(attr_group)
      attr_subgroups = []
      attr_noorder = []

      attr_group.each do |attr|
        attr_def = attr[attr.keys[0]]
        if attr_def[:ask_sort].is_a?(Fixnum)
          Lorj.debug(4, "'%s' position requested is '%s'",
                     attr.key(attr_def), attr_def[:ask_sort])
          if attr_subgroups[attr_def[:ask_sort]].nil?
            attr_subgroups[attr_def[:ask_sort]] = [attr]
          else
            attr_subgroups[attr_def[:ask_sort]] << attr
          end
        else
          attr_noorder << attr
        end
      end

      attr_subgroups.flatten!

      attr_subgroups + attr_noorder
    end

    # Internal setup function to re-organize steps as described by
    # :setup/:steps section and data property :step
    #
    def _setup_reorganize_steps(steps_unordered, steps, setup_steps)
      steps << steps_unordered

      # build the steps attributes
      build_steps = [{ :order => {} }]
      build_step = 0
      step_name = nil
      #  cur_step = build_steps[build_step]
      Lorj.debug(3, "Building setup step position '%s'", build_step)

      steps.each_index do |step_index|
        steps[step_index].each do |attr|
          attr_name = attr.keys[0]
          attr_def = attr[attr_name]

          unless attr_def[:setup]
            Lorj.debug(2, "'%s' is ignored. configured with :account = '%s'",
                       attr_name, attr_def[:setup])
            next
          end

          step_name = _setup_ros_get_step_name(attr_def)

          next if _setup_ros_same_step_name(build_steps[build_step],
                                            step_index, step_name, attr_name)

          build_step = _setup_ros_set_step(:build_steps => build_steps,
                                           :build_step => build_step,
                                           :setup_steps => setup_steps,
                                           :step_index => step_index,
                                           :step_name => step_name,
                                           :attr_name => attr_name)

          _setup_ros_add_attribute(build_steps[build_step][:order],
                                   step_index, attr_name)
        end
      end

      if build_steps.last[:name].nil?
        _setup_ros_set_step(:build_steps => build_steps,
                            :setup_steps => setup_steps,
                            :step_index => steps.length - 1,
                            :attr_name => :default)
      end

      build_steps
    end

    # Internal function to get the step name to use
    def _setup_ros_get_step_name(attr_def)
      return nil if attr_def[:ask_step].nil?

      step_name = attr_def[:ask_step]
      step_name = step_name.to_s if step_name.is_a?(Fixnum)
      step_name
    end

    # Internal function checking if the step is already assigned
    def _setup_ros_same_step_name(build_step, stepo_index, step_name, attr_name)
      return false unless step_name.nil? || build_step[:name] == step_name

      _setup_ros_add_attribute(build_step[:order], stepo_index, attr_name)
      true
    end

    # Internal function to add an attribute to the step_order structure.
    def _setup_ros_add_attribute(step_order, stepo_index, attr_name)
      step_order[stepo_index] = [] if step_order[stepo_index].nil?
      step_order[stepo_index] << attr_name
    end

    #  attr_steps.reject! { |group| group.length == 0 }

    # Set the step data to the current order built.
    #
    # If the step has already been set, a warning is printed.
    #
    # * *returns*:
    #   - +Return the
    #
    def _setup_ros_set_step(params)
      build_steps = params[:build_steps]
      build_step = params[:build_step]
      step_index = params[:step_index]
      step_name = params[:step_name]
      attr_name = 'of latest step'
      attr_name = params[:attr_name] unless params[:attr_name].nil?

      setup_step = params[:setup_steps][step_name]
      if setup_step.nil?
        PrcLib.warning("Attribute '%s': Setup step '%s' is not defined.",
                       attr_name, step_name)
        return build_step
      end

      step_found = _setup_ros_find_buildstep(build_steps, step_index,
                                             step_name)

      return build_step if step_found.nil?

      if step_found == build_steps.length
        step = { :order => { step_index => [] } }
        Lorj.debug(3, "Building setup step position '%s'", step_found)
        build_steps << step
      end

      build_step = step_found
      step = build_steps[build_step]

      return build_step if step[:name] == step_name

      step[:name] = step_name

      step[:desc] = setup_step[:desc]
      step[:explanation] = setup_step[:explanation]
      step[:pre_step_handler] = setup_step[:pre_step_function]
      step[:post_step_handler] = setup_step[:post_step_function]

      Lorj.debug(3, "Requested by '%s' attribute, setup step position '%s'"\
                    " is assigned to '%s'", attr_name,
                 build_steps.length - 1, step_name)
      build_step
    end

    # Internal Function searching in build_steps a step_name.
    # If found, the index is kept.
    #
    # If found, it compares the index with the current step_index
    # It will be considered valid if the step index has a
    # step_index in :orders or if the step_index - 1 is the found
    # in the last known step.
    #
    # If the step is not found, the index returned will be a new index
    # to create in build_steps.
    #
    # * *args*:
    #   - +build_steps+      : List of build_steps already identified.
    #   - +step_order_index+ : current step order index to add an attribute to.
    #   - +step_name+        : Step name to search.
    #
    # * *return*:
    #   - +index+ : It returns a correct build_step to use.
    #   - *nil*   : nil if there is no valid index to return.
    #
    def _setup_ros_find_buildstep(build_steps, step_order_index,
                                    searched_step_name)
      return 0 if step_order_index == 0

      step_found = nil
      last_step_order_found = nil

      build_steps.each_index do |i|
        step_found = i if build_steps[i][:name] == searched_step_name
        if build_steps[i][:order].include?(step_order_index - 1)
          last_step_order_found = i
        end
      end

      return build_steps.length if step_found.nil?

      if step_found
        if build_steps[step_found][:order].include?(step_order_index)
          return step_found
        end

        return step_found if step_found >= last_step_order_found
      end

      PrcLib.warning("Unable to set step '%s' at position %s. "\
                     "This step is already at position '%s'. "\
                     "Due to attribute dependencies, attribute '%' cannot be"\
                     ' asked at that step. Please correct the process'\
                     ' definition. ',
                     step_name, build_steps.index(e),
                     build_steps.length - 1, attr_name)
      nil
    end
    # Internal setup function to complete the list of attributes
    # and organize attributes by step as requested by attr dependencies
    # It loops on a list of unanalyzed attributes to determine
    # new objects/attributes
    #
    # The analyze is based on attributes having setup obj (and group of deps)
    # required
    #
    # A new level is added:
    # - when a new group of deps is found.
    #   Then each attributes required decrease the level by 1.
    # - when a group already exist, nothing is done
    #
    # In case of depends_on, the attribute level is set to 0
    # and depends_on attributes level are decreased.
    # each attributes parsed get a level 0 if requires a group is requires
    # otherwise level is set to nil.
    def _setup_build_steps_from(dependencies)
      count = dependencies[:attributes].length
      attrs_done = {}
      level = 0
      loop do
        attrs = dependencies[:attributes].clone
        attrs.each_key do |attr_name|
          next if attrs_done.key?(attr_name)

          element = _setup_bs_objs(attrs_done, dependencies, attr_name)

          attrs_done[attr_name] = element
          dependencies.rh_set(element, :attributes, attr_name)

          if element.rh_exist?(:group, :level)
            level = [level, element[:group][:level]].min
          end

          list_attrs = (element[:attrs] + element.rh_get(:group, :attrs)).uniq

          next if list_attrs.length == 0
          Lorj.debug(2, "setup: '%s' attribute dependency found '%s'",
                     attr_name, list_attrs.join(', '))
        end
        break if dependencies[:attributes].length == count
        count = dependencies[:attributes].length
      end

      # Thanks to attributes/group deps, set levels
      attrs = dependencies[:attributes]
      _setup_bs_levels(attrs, level)
    end

    # Uses attributes level detected to initialize the list of steps/orders.
    def _setup_bs_levels(attrs, level)
      steps = [[]]
      pos = 0

      loop do
        attrs.clone.each do |k, v|
          cur_level = v.rh_get(:group, :level)
          next unless cur_level == level

          attrs_to_add = v[:attrs] + v.rh_get(:group, :attrs).uniq
          attrs.reject! do |attr, _|
            res = attrs_to_add.include?(attr)
            steps[pos] << { attr => attrs[attr] } if res
            res
          end

          steps[pos + 1] = [] if steps[pos + 1].nil?

          steps[pos + 1] << { k => attrs[k] }
          attrs.reject! { |attr, _| attr == k }
        end
        level += 1
        break if level == 0
        pos += 1
      end
      steps
    end

    # Internal setup function to build the list of attribute deps
    #
    def _setup_bs_objs(attrs_done, dependencies, attr_name)
      # Check if this attr requires an object query.
      Lorj.debug(2, "-- Checking '%s' attribute --", attr_name)
      data = Lorj.data.auto_section_data(attr_name)

      element = _setup_bs_objs_init(data)

      return element if data.nil?

      return element unless data.rh_exist?(:list_values, :object) ||
                            data[:depends_on].is_a?(Array)

      _setup_bs_list_query(dependencies, attr_name, data, element)

      # ensure attribute dependency is dynamically added to the list of
      # object deps.
      _setup_bs_objs_new_dep(dependencies, attr_name, element)

      element[:depends_on] = []
      element[:depends_on] = data[:depends_on] if data[:depends_on].is_a?(Array)

      group = element[:group]
      if group[:objs].length > 0
        _setup_set_group_level(dependencies, attrs_done, attr_name,
                               group, group[:objs].sort)
      else
        _setup_set_group_level(dependencies, attrs_done, attr_name,
                               group, [element[:obj]])
      end

      _setup_attrs_depends_on(dependencies, attr_name,
                              element[:depends_on])

      element
    end

    # Initialize attribute element.
    def _setup_bs_objs_init(data)
      element = { :obj => nil, :setup => false, :ask_sort => nil,
                  :group => { :objs => [], :attrs => [] },
                  :attrs => [], :ask_step => nil }

      return element if data.nil?

      element[:setup] = data[:account] if data.rh_get(:account).boolean?
      if data.rh_get(:ask_sort).is_a?(Fixnum)
        element[:ask_sort] = data[:ask_sort]
      end

      element[:ask_step] = data[:ask_step]

      element
    end

    # Internal function to verify if any attributes adds an object dependency
    #
    def _setup_bs_objs_new_dep(dependencies, parent_attr_name, element)
      attrs = (element[:attrs] + element[:group][:attrs]).uniq
      return if attrs.length == 0

      found = false

      attrs.each do |attr_name|
        obj_found = dependencies.rh_get(:attributes, attr_name, :obj)
        next if obj_found.nil?

        objs = element.rh_get(:group, :objs)
        next if objs.include?(obj_found)

        dep = dependencies.rh_get(:attributes, attr_name)
        # Updating list of deps objs
        objs << obj_found
        objs = (objs + dep[:group][:objs]).uniq
        element.rh_set(objs, :group, :objs)

        # Undating list of deps attributes
        attrs = element.rh_get(:group, :attrs)
        attrs_found = (attrs + dep[:attrs] + dep[:group][:attrs]).uniq
        element.rh_set(attrs_found, :group, :attrs)

        Lorj.debug(4, "attr setup '%s': '%s' dependent attribute adds a new"\
                      " object dependency '%s'",
                   parent_attr_name, attr_name, obj_found)
        found = true
      end
      return unless found

      Lorj.debug(5, "attr setup '%s': query '%s' (+ %s) and "\
                    "requires '%s' (+ %s)", parent_attr_name,
                 element[:obj], element[:group][:objs],
                 element[:attrs], element[:group][:attrs] - element[:attrs])
    end

    def _setup_bs_list_query(dependencies, attr_name, data, element)
      return unless data.rh_exist?(:list_values, :object)

      element[:obj] = data.rh_get(:list_values, :object)
      element[:group] = _setup_bs_objs_deps(dependencies, element[:obj])

      _object_params_event(element[:obj], :query_e, :data).each do |attr_obj|
        element[:attrs] << attr_obj.key_tree
      end
      Lorj.debug(5, "attr setup '%s': query '%s' (+ %s) and "\
                    "requires '%s' (+ %s)", attr_name,
                 element[:obj], element[:group][:objs],
                 element[:attrs], element[:group][:attrs] - element[:attrs])
    end

    # Function to initialize the level to 0 for the current attribute.
    # def _setup_set_level(dependencies, attr_name)
    #   level = dependencies.rh_get(:attributes, attr_name, :level)
    #   if level.nil?
    #     level = 0
    #   else
    #     level += -1
    #   end
    #   level
    # end

    # Function to increase level (-1) for the list of attributes.
    # def _setup_increase_level(dependencies, attrs)
    #   attrs.each do |a|
    #     unless dependencies.rh_exist?(:attributes, a, :level)
    #       dependencies.rh_set(0, :attributes, a, :level)
    #     end
    #     dependencies[:attributes][a][:level] += -1
    #   end
    # end

    # Function parsing the attrs_done to found equivalent group or subgroup.
    #
    # - 1. search for equivalent group
    #   copy the equivalent group level to the group tested.
    #   return if updated
    #
    # - 2. search for any subgroup already treated.
    #   The group will get the highest level
    #   each subgroup (part of the new group) will be decreased.
    #   return if updated
    #
    # - 3. loop in groups if the tested group is a subgroup of an existing group
    #   The group tested will get the lowest group level - 1
    #   return if updated
    #
    # - 4. the group level is set with -1
    #
    def _setup_set_group_level(dependencies, attrs_done, attr_name, group, objs)
      return unless _setup_set_group_case1(attrs_done, attr_name, group, objs)
      return unless _setup_set_group_case2(dependencies, attrs_done,
                                           attr_name, group, objs)

      _setup_set_group_case34(attrs_done, attr_name, group, objs)
    end

    # Case 1 - equivalent group?
    def _setup_set_group_case1(attrs_done, attr_name, group, objs)
      attrs_done.each do |k, v|
        next unless v.rh_get(:group, :objs) == objs ||
                    (v.rh_get(:group, :objs).length == 0 && v[:obj] == objs[0])

        group[:level] = v.rh_get(:group, :level)
        Lorj.debug(5, "attr setup '%s': Equivalent: '%s' group level set to %s",
                   attr_name, k, group[:level])
        return false
      end
      true
    end

    # case 2 - existing group found as subgroup?
    def _setup_set_group_case2(dependencies, attrs_done, attr_name, group, objs)
      attr_subgroups = []
      level = nil
      attrs_done.each do |k, v|
        group_to_check = v.rh_get(:group, :objs)
        next if objs - [v[:obj]] == objs && objs - group_to_check == objs

        attr_subgroups << k
        if level.nil?
          level = v.rh_get(:group, :level)
        else
          level = [v.rh_get(:group, :level), level].max
        end
      end

      if level
        group[:level] = level
        Lorj.debug(5, "attr setup '%s': group level set to %s",
                   attr_name, group[:level])

        attr_subgroups.each do |v|
          group = dependencies.rh_get(:attributes, v, :group)
          group[:level] += -1
          Lorj.debug(5, "attr setup '%s': attribute subgroup '%s' level"\
                        ' decreased: group level set to %s',
                     attr_name, v, group[:level])
        end
        return false
      end
      true
    end

    # case 3 - Is a subgroup of existing group?
    def _setup_set_group_case34(attrs_done, attr_name, group, objs)
      group[:level] = -1 # default is case 4 - new group!

      attrs_done.each_value do |v|
        group_to_check = v.rh_get(:group, :objs)
        next if group_to_check - objs == group_to_check

        group[:level] = [group[:level], v.rh_get(:group, :level) - 1].min
      end
      Lorj.debug(5, "attr setup '%s': group level set to '%s'",
                 attr_name, group[:level])
    end

    # Internal setup function - Extract object data information.
    def _setup_bs_objs_deps(dependencies, object_type)
      group = { :objs => nil, :attrs => nil }
      if dependencies.rh_exist?(:objects, object_type)
        group[:objs], group[:attrs] = _setup_objects_attr_needs(dependencies,
                                                                object_type)
        return group
      end
      _setup_identify_dep_init(dependencies, object_type)
      group[:objs], _, group[:attrs] = _setup_identify_deps(dependencies,
                                                            object_type)
      group
    end

    # Internal setup function - Build list of ALL attributes required for an
    # object
    #
    # It navigates on loaded dependencies to build the list of attributes.
    def _setup_objects_attr_needs(dependencies, object_type)
      attrs = []

      objects = dependencies.rh_get(:objects, object_type, :objects)
      deps_objects = []
      objects.each do |o|
        attrs += dependencies.rh_get(:objects, o, :attrs)
        found_obj, deps_attrs = _setup_objects_attr_needs(dependencies, o)
        attrs += deps_attrs
        deps_objects += found_obj
      end
      [(objects + deps_objects).uniq, attrs.uniq]
    end

    # Internal setup function - Identify a list of attributes from depends_on
    #
    # If the attribute has a object dependency, attributes attached are added.
    # If the object has depends_on
    def _setup_attrs_depends_on(dependencies, attr_name, attrs)
      return [] unless attrs.is_a?(Array) && attrs.length > 0

      result = []

      Lorj.debug(3, "%s: depends on added '%s'", attr_name, attrs.join(', '))

      attrs.each do |a|
        data = Lorj.data.auto_section_data(a)

        if data.rh_exist?(:list_values, :object)
          element = _setup_bs_objs_deps(dependencies,
                                        data.rh_get(:list_values, :object))
          element[:attrs] += dependencies.rh_get(:object, element[:obj], :attrs)
        else
          element = { :attrs => [] }
        end

        if data[:depends_on].is_a?(Array)
          element[:depends_on] = _setup_attrs_depends_on(dependencies, a,
                                                         data[:depends_on])
        else
          element[:depends_on] = []
        end

        attrs_list = element[:attrs] + element[:depends_on]
        attrs_list.uniq!
        result += attrs_list
      end
      result.uniq
    end
    # rubocop: enable Metrics/CyclomaticComplexity

    # Internal setup function - set/get dep level for an object
    # def _setup_build_so_obj_level(obj_data_level, name, order_index)
    #   return 0 if name.nil?

    #   return obj_data_level[name] if obj_data_level.key?(name)

    #   obj_data_level[name] = order_index
    # end

    # Internal setup function initializing a model object
    #
    def _setup_identify_dep_init(dependencies, object_type, path = [])
      if path.include?(object_type)
        PrcLib.warning('Loop detection: Be careful! a loop is detected with'\
                       " the dependency from '%s' to '%s'. "\
                       'Dependency ignored.', path.join('/'), object_type)
        return false
      end

      return false if dependencies.rh_exist?(:objects, object_type)

      model_object = { :objects => [], :objects_attrs => [], :attrs => [] }

      dependencies.rh_set(model_object, :objects, object_type)
      true
    end

    # Internal setup function to identify data to ask
    # Navigate through objects dependencies to determine the need.
    # def _setup_identify_obj_params(setup_steps,
    #                                inspected_objects, objs_to_inspect,
    #                                attr_name, attr_params)

    #   attr_type = attr_params[:type]

    #   case attr_type
    #   when :data
    #     return unless _setup_obj_param_is_data(setup_steps,
    #                                            inspected_objects, attr_name)
    #     inspected_objects << attr_name
    #     return
    #   when :CloudObject
    #     return if objs_to_inspect.include?(attr_name) ||
    #               inspected_objects.include?(attr_name)
    #     # New object to inspect
    #     objs_to_inspect << attr_name
    #   end
    # end

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

        order_array.each_key do |iIndex|
          Lorj.debug(2, 'Ask order %s:', iIndex)
          order_array[iIndex].each do |data|
            options = _get_meta_data(data)
            options = {} if options.nil?

            Lorj.data.layer_add(:name => :setup)

            if options[:pre_step_function]
              proc = options[:pre_step_function]
              next unless @process.method(proc).call(data)
              # Get any update from pre_step_function
              options = _get_meta_data(data)
            end

            data_desc = _setup_display_data(data, options)

            _setup_ask_data(data_desc, data, options)

            Lorj.data.layer_remove(:name => :setup)
          end
        end
      end
    end
  end
end
