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

# - controler functions: controller functions called by Lorj::BaseProcess.
module Lorj
  # Adding controller core functions.
  class BaseDefinition
    # a Process can execute any kind of predefined controler task.
    # Those function build controller_params with Provider compliant data
    # (mapped)
    # Results are formatted as usual framework Data object and stored.

    # controller_connect call lorj framework to execute a
    # controller connection task
    #
    # parameters:
    # - +object_type+: Lorj object type to use for the connection.
    # - +params+     : Parameters to use for connection.
    def controller_connect(sObjectType, params = nil)
      _add_instant_config(params)

      controller_params = _get_controller_params(sObjectType,
                                                 :create_e, :connect)
      controller_obj = @controller.connect(sObjectType, controller_params)
      data_obj = Lorj::Data.new
      data_obj.base = self
      data_obj.set(controller_obj, sObjectType) do |sObjType, oObject|
        begin
          _return_map(sObjType, oObject)
       rescue => e
         PrcLib.runtime_fail 'connect %s.%s : %s',
                             @process.class, sObjectType, e.message
        end
      end
      @object_data.add data_obj
      data_obj
    end
    # controller_create call lorj framework to execute a
    # controller creation task
    #
    # parameters:
    # - +object_type+: Lorj object type to use for the creation.
    # - +params+     : Parameters to use for creation.
    def controller_create(sObjectType, params = nil)
      _add_instant_config(params)

      # The process ask the controller to create the object.
      # controller_params have to be fully readable by the controller.
      controller_params = _get_controller_params(sObjectType,
                                                 :create_e, :create)
      controller_obj = @controller.create(sObjectType, controller_params)
      data_obj = Lorj::Data.new
      data_obj.base = self
      data_obj.set(controller_obj, sObjectType) do |sObjType, oObject|
        begin
          _return_map(sObjType, oObject)
       rescue => e
         PrcLib.runtime_fail 'create %s.%s : %s',
                             @process.class, sObjectType, e.message
        end
      end
      @object_data.add data_obj

      _remove_instant_config(params)

      data_obj
    end

    # controller_delete call lorj framework to execute a
    # controller deletion task
    #
    # parameters:
    # - +object_type+: Lorj object type to use for the deletion.
    # - +params+     : Parameters to use for deletion.
    #
    # returns:
    # - The controller must return true to inform about the real deletion
    def controller_delete(sObjectType, params = nil)
      _add_instant_config(params)

      controller_params = _get_controller_params(sObjectType,
                                                 :delete_e, :delete)
      PrcLib.runtime_fail "delete Controller - %s: Object '%s' is not loaded.",
                          @controller.class,
                          key unless controller_params.exist?(sObjectType)
      state = @controller.delete(sObjectType, controller_params)
      @object_data.delete(sObjectType) if state

      _remove_instant_config(params)

      state
    end

    # controller_get call lorj framework to execute a controller get task
    #
    # parameters:
    # - +object_type+: Lorj object type to use for the get.
    # - +params+     : Parameters to use for get.
    #
    # returns:
    # - Return a Lorj::Data representing the data retrieved by the controller.
    def controller_get(sObjectType, sUniqId, params = nil)
      _add_instant_config(params)

      controller_params = _get_controller_params(sObjectType,
                                                 :get_e, :get)

      controller_obj = @controller.get(sObjectType, sUniqId, controller_params)
      data_obj = Lorj::Data.new
      data_obj.base = self
      data_obj.set(controller_obj, sObjectType) do |sObjType, oObject|
        begin
          _return_map(sObjType, oObject)
       rescue => e
         PrcLib.runtime_fail 'get %s.%s : %s',
                             @process.class, sObjectType, e.message
        end
      end
      @object_data.add data_obj

      _remove_instant_config(params)

      data_obj
    end

    # controller_query call lorj framework to execute a controller query task
    #
    # parameters:
    # - +object_type+: Lorj object type to use for the query.
    # - +params+     : Parameters to use for query.
    #
    # returns:
    # - Returns a Lorj::Data object, containing a list of Lorj::Data element.
    def controller_query(sObjectType, hQuery, params = nil)
      _add_instant_config(params)

      # Check if we can re-use a previous query
      list = @object_data[:query, sObjectType]
      unless list.nil?
        if list[:query] == hQuery
          Lorj.debug(3, "Using Object '%s' query cache : %s",
                     sObjectType, hQuery)
          return list
        end
      end

      controller_params = _get_controller_params(sObjectType,
                                                 :query_e, :query)
      controller_query = _query_map(sObjectType, hQuery)

      controller_obj = @controller.query(sObjectType, controller_query,
                                         controller_params)

      data_obj = Lorj::Data.new :list
      data_obj.base = self
      data_obj.set(controller_obj,
                   sObjectType, hQuery) do |sObjType, key|
        begin
          _return_map(sObjType, key)
       rescue => e
         PrcLib.runtime_fail 'query %s.%s : %s',
                             @process.class, sObjectType, e.message
        end
      end

      Lorj.debug(2, 'Object %s - queried. Found %s object(s).',
                 sObjectType, data_obj.length)

      @object_data.add data_obj

      _remove_instant_config(params)

      data_obj
    end

    # controller_update call lorj framework to execute a controller update task
    #
    # parameters:
    # - +object_type+: Lorj object type to use for the update.
    # - +params+     : Parameters to use for update.
    #
    # returns:
    # - The controller must return true to inform about the real deletion
    def controller_update(sObjectType, params = nil)
      _add_instant_config(params)

      # Need to detect data updated and update the Controler object with the
      # controler

      controller_params = _get_controller_params(sObjectType,
                                                 :update_e, :update)

      data_obj = @object_data[sObjectType, :ObjectData]
      controller_obj = data_obj[:object]

      is_updated = false
      attributes = data_obj[:attrs]
      attributes.each do |key, value|
        attribute_obj = KeyPath.new(key)

        attribute_map = PrcLib.model.meta_obj.rh_get(sObjectType, :returns,
                                                     attribute_obj.fpath)
        attr_map_obj = KeyPath.new(attribute_map)
        old_value = @controller.get_attr(controller_obj, attr_map_obj.tree)

        next if value == old_value

        is_updated = true
        @controller.set_attr(controller_obj, attr_map_obj.tree, value)
        Lorj.debug(2, '%s.%s - Updating: %s = %s (old : %s)',
                   @process.class, sObjectType, key, value, old_value)
      end

      is_done = @controller.update(sObjectType, data_obj,
                                   controller_params) if is_updated

      PrcLib.runtime_fail "Controller function 'update' must return True or "\
                          "False. Class returned: '%s'",
                          is_done.class unless is_done.boolean?

      Lorj.debug(1, '%s.%s - updated.',
                 @process.class, sObjectType) if is_done
      data_obj.set(controller_obj, sObjectType) do |sObjType, an_object|
        begin
          _return_map(sObjType, an_object)
       rescue => e
         PrcLib.runtime_fail 'update %s.%s : %s',
                             @process.class, sObjectType, e.message
        end
      end

      _remove_instant_config(params)

      is_done
    end

    # controller_refresh call lorj framework to execute a controller refresh
    # task
    #
    # The controller must respect the following rule:
    # - If the refresh was unsuccessful, due to errors, the original object
    #   should be kept intact.
    # - A boolean should be return to inform that therefresh was executed
    #   successfully or not.
    #
    # * *parameters:*
    #   - +object_type+: Lorj object type to use for the refresh.
    #   - +object+     : object to refresh.
    #
    # * *returns*:
    #   - boolean: true if refresh was executed successfully.
    #     false otherwise.
    #
    def controller_refresh(sObjectType, data_obj)
      return false unless data_obj.is_a?(Lorj::Data) && !data_obj.empty?

      controller_obj = data_obj[:object]

      is_refreshed = @controller.refresh(sObjectType, controller_obj)

      PrcLib.runtime_fail "Controller function 'refresh' must return true or "\
                          "false. Class returned: '%s'",
                          is_refreshed.class unless is_refreshed.boolean?

      Lorj.debug(1, '%s.%s - refreshed.',
                 @process.class, sObjectType) if is_refreshed

      data_obj.set(controller_obj, sObjectType) do |sObjType, an_object|
        begin
          _return_map(sObjType, an_object)
       rescue => e
         PrcLib.runtime_fail 'update %s.%s : %s',
                             @process.class, sObjectType, e.message
        end
      end

      is_refreshed
    end
  end
end
