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
    # Internal setup function to build the list from a controller call.
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
    def _setup_list_from_controller_call(obj_to_load, list_options, default)
      PrcLib.message("Loading :object #{obj_to_load}.")
      Lorj.debug(3, ':query_type = :controller_call')

      object = @object_data[obj_to_load, :ObjectData]
      object = process_create(obj_to_load) if object.nil?
      return nil if object.nil?

      params = ObjectData.new
      params.add(object)
      params << list_options[:query_params]

      PrcLib.runtime_fail '%s: query_type => :controller_call '\
                   'requires missing :query_call declaration'\
                   ' (Controller function)',
                          data if list_options[:query_call].nil?

      proc = list_options[:query_call]
      begin
        list = @controller.method(proc).call(obj_to_load, params)
      rescue => e
        PrcLib.runtime_fail "Error during call of '%s':\n%s", proc, e.message
      end
      { :list => list, :default_value => default }
    end

    # Internal setup function to build the list from a query call.
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
    def _setup_list_from_query_call(obj_to_load, list_options, default)
      PrcLib.message("Querying :object #{obj_to_load}.")
      Lorj.debug(3, ':query_type = :query_call - ')

      query_hash = list_options[:query_params]
      query_hash = {} if query_hash.nil?

      object_list = process_query(obj_to_load, query_hash)

      list = []
      object_list.each { |oElem| list << oElem[list_options[:value]] }

      { :list => list.sort!, :default_value => default }
    end

    def _setup_build_process_params(option_params, params)
      return if option_params.nil?

      option_params.each do |key, value|
        next if value.nil?
        begin
          value = erb(value)
        rescue => e
          Prclib.warning("ERB:process parameter failed to set '%s' with '%s'."\
                         "\n%s", key, value, e.message)
        end
        params << { key => value }
      end
    end

    # Internal setup function to build the list from a process call.
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
    def _setup_list_from_process_call(obj_to_load, list_options, default)
      PrcLib.runtime_fail '%s: query_type => :process_call'\
                   ' requires missing :query_call declaration'\
                   ' (Provider function)',
                          data if list_options[:query_call].nil?
      proc = list_options[:query_call]
      obj_to_load = list_options[:object]
      PrcLib.message("Running process '#{proc}' on :object '#{obj_to_load}'.")
      Lorj.debug(3, ':query_type = :process_call')

      # Building Process function attr_params parameter
      params = ObjectData.new

      params << { :default_value => default }

      _setup_build_process_params(list_options[:query_params], params)

      begin
        proc_method = @process.method(proc)
        result = proc_method.call(obj_to_load, params)
      rescue => e
        PrcLib.runtime_fail "Error during call of '%s':\n%s",
                            proc, e.message
      end

      if result.is_a?(Hash)
        if result[:list].nil? ||
           !result[:list].is_a?(Array)
          PrcLib.debug("Process function '%s' did not return an"\
                       ' :list => Array of list_options.',
                       list_options[:query_call])
        end
      else
        PrcLib.debug("Process function '%s' did not return an"\
                     ' Hash with :list and :default_value')
        result = { :list => [], :default_value => nil }
      end
      result
    end
  end
end
