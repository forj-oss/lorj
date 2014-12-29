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

# It requires Core objects to be defined + default ForjProcess functions.

# Define framework object on BaseDefinition
module Lorj
  # ************************************ Internet SERVER Object
  # internet server is a server connected to the internet network.
  class BaseDefinition
    define_obj(:internet_server,    :nohandler => true)

    obj_needs :CloudObject,  :internet_network
    obj_needs :CloudObject,  :server
    obj_needs :CloudObject,  :public_ip
  end
end
