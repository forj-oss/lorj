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

module Lorj
  # Specific ALL Ruby functions, but incompatible with some other version.
  module ObjectDataRubySpec
    # Public functions
    module Public
      # Functions used to set simple data/Object for controller/process function
      # call.
      # TODO: to revisit this function, as we may consider simple data, as
      # Lorj::Data object
      def []=(*key, value)
        return nil if [:object, :query].include?(key[0])
        @params.rh_set(value, key)
      end
    end
  end
end
