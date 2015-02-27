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

# - process functions: Process functions called by Core or BaseProcess.
module Lorj
  # Adding process core functions.
  class BaseDefinition
    # Capitalized function are called to start a process. It is done by Core
    # class.

    # Call meta lorj object creation process.
    # The creation process can implement any logic like:
    # - create an object in the DB.
    # - check object existence in the DB. If not exists, create it.
    #
    # * *Args* :
    #   - +ObjectType+ : Meta object type to create.
    #   - +Config+     : Optional. Hash containing list of data to use for
    # creation.
    #
    # * *Returns* :
    # - +Object+ : Lorj::Data object of type +ObjectType+ created.
    # OR
    # - Lorj::Data empty.
    #
    # * *Raises* :
    #   - Warning if the create_e process handler did not return any data. (nil)
    #   - Warning if the Config data passed are not required by the meta object
    #     (or dependencies) at creation time.
    #   - Error if ObjectType has never been declared.
    #   - Error if the dependencies create_e process handler did not return any
    #     data. (nil) - Loop detection.
    #   - Error if the create_e process handler raise an error.
    #
    def process_create(object_type, hConfig = nil)
      return nil unless object_type

      _add_instant_config(hConfig)

      unless PrcLib.model.meta_obj.rh_exist?(object_type)
        PrcLib.runtime_fail "%s.%s: '%s' is not a known object type.",
                            self.class, __callee__, object_type
      end
      proc = PrcLib.model.meta_obj.rh_get(object_type, :lambdas, :create_e)

      # Check required parameters
      _process_load_dependencies(object_type, proc, :create_e, __callee__)

      # Context: Default object used
      @runtime_context[:oCurrentObj] = object_type

      if proc.nil?
        # This object is a meta object, without any data.
        # Used to build other kind of objects.
        object = Lorj::Data.new
        object.set({}, object_type) {}
      else
        # build Function params to pass to the event handler.
        params = _get_process_params(object_type, :create_e, proc)
        Lorj.debug(2, "Create Object '%s' - Running '%s'", object_type, proc)

        # Call the process function.
        # At some point, the process will call the controller, via the framework
        # This controller call via the framework has the role to
        # create an ObjectData well formatted, with _return_map function
        # See Definition.connect/create/update/query/get functions (lowercase)
        object = @process.method(proc).call(object_type, params)
        # return usually is the main object that the process called should
        # provide.
        # Save Object if the object has been created by the process, without
        # controller
      end

      _remove_instant_config(hConfig)

      if object.nil?
        PrcLib.warning("'%s' has returned no data for object Lorj::Data '%s'!",
                       proc, object_type)
        Lorj::Data.new
      else
        query_cleanup(object_type)
        @object_data.add(object)
      end
    end

    # Call meta lorj object deletion process
    # There is no implementation of cascade deletion. It is up to the process to
    # do it or not.
    #
    # * *Args* :
    #   - +ObjectType+ : Meta object type to create.
    #   - +Config+     : Optional. Hash containing list of data to use for
    # creation.
    #
    # * *Returns* :
    #   - +Deleted+    : true if deleted or false otherwise.
    #
    # * *Raises* :
    #   - Warning if the create_e process handler did not return any data. (nil)
    #   - Warning if the Config data passed are not required by the meta object
    #     (or dependencies) at creation time.
    #   - Error if ObjectType has never been declared.
    #   - Error if the dependencies query_e process handler did not return any
    #     data. (nil) - Loop detection.
    #   - Error if the query_e process handler raise an error.
    #
    def process_delete(object_type, hConfig = nil)
      return nil unless object_type

      _add_instant_config(hConfig)

      unless PrcLib.model.meta_obj.rh_exist?(object_type)
        PrcLib.runtime_fail "%s.%s: '%s' is not a known object type.",
                            self.class, __callee__, object_type
      end

      proc = PrcLib.model.meta_obj.rh_get(object_type, :lambdas, :delete_e)

      return nil if proc.nil?

      # Check required parameters
      _process_load_dependencies(object_type, proc, :delete_e, __callee__)

      # Context: Default object used.
      @runtime_context[:oCurrentObj] = object_type

      # build Function params to pass to the event handler.
      params = _get_process_params(object_type, :delete_e, proc)

      state = @process.method(proc).call(object_type, params)
      # return usually is the main object that the process called should provide

      _remove_instant_config(hConfig)

      @object_data.delete(object_type) if state
    end

    # Function to clean the cache for a specific meta lorj object queried.
    #
    # * *Args* :
    #   - +ObjectType+ : Meta object type to cleanup.
    #
    # * *Returns* :
    #   no data
    #
    # * *Raises* :
    #
    def query_cleanup(object_type)
      list = @object_data[:query, object_type]
      return if list.nil?

      @object_data.delete(list)
      Lorj.debug(2, "Query cache for object '%s' cleaned.", object_type)
    end

    # Function to clean the cache for a specific meta lorj object.
    #
    # * *Args* :
    #   - +ObjectType+ : Meta object type to cleanup.
    #
    # * *Returns* :
    #   no data
    #
    # * *Raises* :
    #
    def object_cleanup(object_type)
      object = @object_data[object_type, :ObjectData]

      @object_data.delete(object) unless object.nil?
    end

    # Function to execute a query process. This function returns a Lorj::Data of
    # type :list.
    #
    # * *Args* :
    #   - +ObjectType+ : Meta object type to query.
    #   - +Query+      : Hash. Represent the query to execute.
    #   - +Config+     : Optional. Hash containing list of data to use for query
    #
    # * *Returns* :
    #   Lorj::Data of type :list
    # OR
    # - Lorj::Data empty.
    #
    # * *Raises* :
    #
    #
    def process_query(object_type, hQuery, hConfig = nil)
      return nil unless object_type

      _add_instant_config(hConfig)

      unless PrcLib.model.meta_obj.rh_exist?(object_type)
        PrcLib.runtime_fail "%s.%s: '%s' is not a known object type.",
                            self.class, __callee__, object_type
      end

      # Check if we can re-use a previous query
      list = query_cache(object_type, hQuery)
      return list unless list.nil?

      proc = PrcLib.model.meta_obj.rh_get(object_type, :lambdas, :query_e)

      return nil if proc.nil?

      # Check required parameters
      _process_load_dependencies(object_type, proc, :query_e, __callee__)

      # Context: Default object used.
      @runtime_context[:oCurrentObj] = object_type

      # build Function params to pass to the Process Event handler.
      params = _get_process_params(object_type, :query_e, proc)

      # Call the process function.
      # At some point, the process will call the controller, via the framework.
      # This controller call via the framework has the role to
      # create an ObjectData well formatted, with _return_map function
      # See Definition.connect/create/update/query/get functions (lowercase)
      object = @process.method(proc).call(object_type, hQuery, params)

      _remove_instant_config(hConfig)

      # return usually is the main object that the process called should provide
      if object.nil?
        PrcLib.warning("'%s' returned no collection of objects Lorj::Data "\
                       "for '%s'", proc, object_type)
        Lorj::Data.new
      else
        # Save Object if the object has been created by the process, without
        # controller
        @object_data.add(object)
      end
    end

    def query_cache(object_type, hQuery)
      # Check if we can re-use a previous query
      list = @object_data[:query, object_type]

      return if list.nil?

      if list[:query] == hQuery
        Lorj.debug(3, "Using Object '%s' query cache : %s",
                   object_type, hQuery)
        return list
      end

      nil
    end

    # Function to execute a get process. This function returns a Lorj::Data of
    # type :object.
    #
    # * *Args* :
    #   - +ObjectType+ : Meta object type to query.
    #   - +UniqId+     : Uniq ID.
    #   - +Config+     : Optional. Hash containing list of data to use for
    #                    getting.
    #
    # * *Returns* :
    # - Lorj::Data of type :object
    # OR
    # - Lorj::Data empty.
    #
    # * *Raises* :
    #   - Warning if the Config data passed are not required by the meta object
    #     (or dependencies) at creation time.
    #   - Error if ObjectType has never been declared.
    #   - Error if the dependencies get_e process handler did not return any
    #     data. (nil) - Loop detection.
    #   - Error if the get_e process handler raise an error.
    #
    def process_get(object_type, sUniqId, hConfig = nil)
      return nil unless object_type

      _add_instant_config(hConfig)

      unless PrcLib.model.meta_obj.rh_exist?(object_type)
        PrcLib.runtime_fail "$s.: '%s' is not a known object type.",
                            self.class, __callee__, object_type
      end

      proc = PrcLib.model.meta_obj.rh_get(object_type, :lambdas, :get_e)

      return nil if proc.nil?

      # Check required parameters
      _process_load_dependencies(object_type, proc, :get_e, __callee__)

      # Context: Default object used
      @runtime_context[:oCurrentObj] = object_type

      # build Function params to pass to the Process Event handler.
      params = _get_process_params(object_type, :get_e, proc)

      # Call the process function.
      # At some point, the process will call the controller, via the framework.
      # This controller call via the framework has the role to
      # create an ObjectData well formatted, with _return_map function
      # See Definition.connect/create/update/query/get functions (lowercase)
      object = @process.method(proc).call(object_type, sUniqId, params)
      # return usually is the main object that the process called should provide

      _remove_instant_config(hConfig)

      if object.nil?
        PrcLib.warning("'%s' has returned no data for object Lorj::Data '%s'!",
                       proc, object_type)
        Lorj::Data.new
      else
        @object_data.add(object)
      end
    end

    # Function to execute a update process. This function returns a Lorj::Data
    # of type :object.
    #
    # * *Args* :
    #   - +object_type+ : Meta object type to query.
    #   - +config+      : Optional. Hash containing list of data to use for
    # updating.
    #
    # * *Returns* :
    # - Lorj::Data of type :object
    # OR
    # - Lorj::Data empty.
    #
    # * *Raises* :
    #   - Warning if the Config data passed are not required by the meta object
    #     (or dependencies) at creation time.
    #   - Error if ObjectType has never been declared.
    #   - Error if the dependencies get_e process handler did not return any
    #     data. (nil) - Loop detection.
    #   - Error if the get_e process handler raise an error.
    #
    def process_update(object_type, hConfig = nil)
      return nil unless object_type

      _add_instant_config(hConfig)

      unless PrcLib.model.meta_obj.rh_exist?(object_type)
        PrcLib.runtime_fail "$s.%s: '%s' is not a known object type.",
                            self.class, __callee__, object_type
      end

      proc = PrcLib.model.meta_obj.rh_get(object_type, :lambdas, :update_e)

      return nil if proc.nil?

      _process_load_dependencies(object_type, proc, :update_e, __callee__)

      # Context: Default object used.
      @runtime_context[:oCurrentObj] = object_type

      # build Function params to pass to the event handler.
      params = _get_process_params(object_type, :update_e, proc)

      object = @process.method(proc).call(object_type, params)
      # return usually is the main object that the process called should provide

      _remove_instant_config(hConfig)

      if object.nil?
        PrcLib.warning("'%s' has returned no data for object Lorj::Data '%s'!",
                       proc, object_type)
        Lorj::Data.new
      else
        @object_data.add(object)
      end
    end
  end

  # Adding private process core functions.
  class BaseDefinition
    private

    def _add_instant_config(hConfig)
      return unless hConfig.is_a?(Hash)

      config = PRC::BaseConfig.new hConfig
      options = { :name => hConfig.object_id.to_s, :config => config,
                  :set => false }

      @config.layer_add PRC::CoreConfig.define_layer(options)
    end

    def _remove_instant_config(hConfig)
      return unless hConfig.is_a?(Hash)

      @config.layer_remove :name => hConfig.object_id.to_s
    end

    def _process_load_dependencies(object_type, proc, handler_name,
                                   function_name)
      missing_obj = _check_required(object_type, handler_name, proc).reverse

      while missing_obj.length > 0
        elem = missing_obj.pop

        if elem == object_type && function_name == :process_delete
          debug(2, "'%s' object is not previously loaded or created.",
                object_type)
          next
        end

        unless process_create(elem)
          PrcLib.runtime_fail "Unable to create Object '%s'", elem
        end

        missing_obj = _check_required(object_type, handler_name, proc).reverse
        PrcLib.runtime_fail "loop detection: '%s' is required but"\
                     " #{function_name}(%s) did not loaded it.",
                            elem, elem if missing_obj.include?(elem)
      end
    end
  end
end
