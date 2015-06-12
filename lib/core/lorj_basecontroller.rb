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
  # Defining basic Controller functions
  class BaseController
    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Create functions.
    def connect(_sObjectType, _hParams)
      controller_error 'connect has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Create functions.
    def create(_sObjectType, _hParams)
      controller_error 'create_object has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Delete functions.
    def delete(_sObjectType, _hParams)
      controller_error 'delete_object has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Get functions.
    def get(_sObjectType, _sUniqId, _hParams)
      controller_error 'get_object has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Query functions.
    def query(_sObjectType, _sQuery, _hParams)
      controller_error 'query_object has not been redefined by the controller.'
    end

    # Default handlers which needs to be defined by the controller,
    # called by BaseDefinition Update functions.
    def update(_sObjectType, _oObject, _hParams)
      controller_error 'update_object has not been redefined by the controller.'
    end

    # Simply raise an error
    #
    # * *Args*    :
    #   - +Msg+ : Error message to print out.
    # * *Returns* :
    #   - nil
    # * *Raises* :
    #  - Lorj::PrcError
    def controller_error(msg, *p)
      msg = format(msg, *p)
      fail Lorj::PrcError.new, format('%s: %s', self.class, msg)
    end

    # check if required data is loaded. raise an error if not
    #
    # * *Args*    :
    #   - +Params+ : Lorj::ObjectData object for controller.
    #   - +key+    : Key to check.
    # * *Returns* :
    #   - nil
    # * *Raises* :
    #   - +Error+ if the key do not exist.
    def required?(oParams, *key)
      if oParams.exist?(key)
        if RUBY_VERSION =~ /1\.8/
          #  debugger # rubocop: disable Lint/Debugger
          if oParams.otype?(*key) == :DataObject &&
             oParams[key, :ObjectData].empty?
            controller_error '%s is empty.', key
          end
        else
          if oParams.type?(*key) == :DataObject &&
             oParams[key, :ObjectData].empty?
            controller_error '%s is empty.', key
          end
        end
        return
      end
      controller_error '%s is not set.', key
    end
  end
end
