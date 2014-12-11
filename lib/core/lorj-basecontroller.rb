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
# - controler (BaseControler) : If a provider is defined, define how will do object creation/etc...
# - definition(BaseDefinition): Functions to declare objects, query/data mapping and setup
# this task to make it to work.

module Lorj

   class BaseController
      # Default handlers which needs to be defined by the controller,
      # called by BaseDefinition Create functions.
      def connect(sObjectType, hParams)
         raise Lorj::PrcError.new(), "connect has not been redefined by the controller '%s'" % self.class
      end

      # Default handlers which needs to be defined by the controller,
      # called by BaseDefinition Create functions.
      def create(sObjectType, hParams)
         raise Lorj::PrcError.new(), "create_object has not been redefined by the controller '%s'" % self.class
      end

      # Default handlers which needs to be defined by the controller,
      # called by BaseDefinition Delete functions.
      def delete(sObjectType, hParams)
         raise Lorj::PrcError.new(), "delete_object has not been redefined by the controller '%s'" % self.class
      end

      # Default handlers which needs to be defined by the controller,
      # called by BaseDefinition Get functions.
      def get(sObjectType, sUniqId, hParams)
         raise Lorj::PrcError.new(), "get_object has not been redefined by the controller '%s'" % self.class
      end

      # Default handlers which needs to be defined by the controller,
      # called by BaseDefinition Query functions.
      def query(sObjectType, sQuery, hParams)
         raise Lorj::PrcError.new(), "query_object has not been redefined by the controller '%s'" % self.class
      end

      # Default handlers which needs to be defined by the controller,
      # called by BaseDefinition Update functions.
      def update(sObjectType, oObject, hParams)
         raise Lorj::PrcError.new(), "update_object has not been redefined by the controller '%s'" % self.class
      end

      # Simply raise an error
      #
      # * *Args*    :
      #   - +Msg+ : Error message to print out.
      # * *Returns* :
      #   - nil
      # * *Raises* :
      #  - Lorj::PrcError
      def Error(msg)
         raise Lorj::PrcError.new(), "%s: %s" % [self.class, msg]
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
         raise Lorj::PrcError.new(), "%s: %s is not set." % [self.class, key] if not oParams.exist?(key)
      end
   end
end