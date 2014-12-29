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

# Subnetwork Management
class CloudProcess
  def forj_get_or_create_subnetwork(sCloudObj, hParams)
    subnet = query_subnet_one(sCloudObj, hParams)
    return nil if subnet.nil?

    # Create the subnet
    subnet = create_subnet(sCloudObj, hParams)

    return nil if subnet.nil?
    register(subnet)
    subnet
  end
end

# ************************************ SubNetwork Object model
# Define framework object on BaseDefinition
module Lorj
  # Identify subnetwork as part of network.
  class BaseDefinition
    define_obj(:subnetwork,
               :create_e => :forj_get_or_create_subnetwork
              )

    obj_needs :CloudObject,  :network_connection
    obj_needs :CloudObject,  :network
    obj_needs :data,         :subnetwork_name

    def_query_attribute :network_id
  end
end

# Subnetwork Management - internal functions
class CloudProcess
  def create_subnet(sCloudObj, hParams)
    name = hParams[:subnetwork_name]
    PrcLib.state("Creating subnet '%s'", name)
    begin
      subnet = controller_create(sCloudObj)
      PrcLib.info("Subnet '%s' created.", subnet[:name])
   rescue => e
     PrcLib.fatal(1, "Unable to create '%s' subnet.", name, e)
    end
    subnet
  end

  def delete_subnet
    net_conn_obj = get_cloudObj(:network_connection)
    sub_net_obj = get_cloudObj(:subnetwork)

    PrcLib.state("Deleting subnet '%s'", sub_net_obj.name)
    begin
      provider_delete_subnetwork(net_conn_obj, sub_net_obj)
      net_conn_obj.subnets.get(sub_net_obj.id).destroy
   rescue => e
     PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
  end

  def query_subnet_one(_sCloudObj, hParams)
    PrcLib.state('Searching for sub-network attached to '\
                 "network '%s'", hParams[:network, :name])
    #######################
    begin
      query = { :network_id => hParams[:network, :id] }
      subnets = controller_query(:subnetwork, query)
   rescue => e
     PrcLib.error("%s\n%s", e.message, e.backtrace.join("\n"))
    end
    return nil if subnets.nil?

    case subnets.length
    when 0
      PrcLib.info('No subnet found from '\
                  "'%s' network", hParams[:network, :name])
      ForjLib::Data.new
    when 1
      PrcLib.info("Found '%s' subnet from "\
                  "'%s' network", subnets[0, :name],
                  hParams[:network, :name])
      subnets[0]
    else
      PrcLib.warning('Several subnet was found on '\
                     "'%s'. Choosing the first one "\
                     "= '%s'", hParams[:network, :name],
                     subnets[0, :name])
      subnets[0]
    end
  end
end
