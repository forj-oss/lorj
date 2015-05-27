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
  module DataRubySpec
    # Public functions
    module Public
      # Set Lorj::data attribute value for an :object
      #
      # * *Args* :
      #   - +keys+ : attribute keys
      #   - +value+: Value to set
      #
      # * *Returns* :
      #   true
      #
      # * *Raises* :
      #   No exceptions
      #
      def []=(*key, value)
        return false if @type == :list
        @data.rh_set(value, :attrs, key)
        true
      end
    end
  end
end
