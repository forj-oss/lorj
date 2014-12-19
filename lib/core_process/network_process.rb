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
#
# This file describe generic process to create/query/get/delete Cloud objects.
# forj_* function are handler, predefined by cloud_data_pref.rb
# The process functions communicates with config, object or controler(provider controler)
#
# 'config' is the configuration system which implements:
# - get(key):        Get the value to the associated key
#   [key]            is the 'set' equivalent
# - set(key, value): Set a value to a key.
#   [key] = value    Is the 'set' equivalent
#
# 'object' contains Object definition, Object manipulation. It implements:
# - query_map(sCloudObj, sQuery): transform Forj Object query request to
#                                 a Provider controler query request
#                                 The result of this function is usually sent to
#                                 the controler query function.
#
# - get_attr(oObject, key): Read the object key from the object.
#
# Providers can redefine any kind of handler if needed.

# ---------------------------------------------------------------------------
# Network/Subnetwork Management
# ---------------------------------------------------------------------------
class CloudProcess
  # Process Query handler
  def forj_query_network(_sCloudObj, _sQuery, _hParams)
    # Call Provider query function
    controller_query(sObjectType, sControlerQuery)
  end

  # Process Create handler
  def forj_get_or_create_network(sCloudObj, hParams)
    PrcLib.state("Searching for network '%s'" % [hParams[:network_name]])
    networks = find_network(sCloudObj, hParams)
    if networks.length == 0
      network = create_network(sCloudObj, hParams)
    else
      network = networks[0]
    end
    register(network)

    # Attaching if missing the subnet.
    # Creates an object subnet, attached to the network.
    unless hParams[:subnetwork_name]
      hParams[:subnetwork_name] = 'sub-' + hParams[:network_name]
      config[:subnetwork_name] = hParams[:subnetwork_name]
    end

    # object.Create(:subnetwork)
    Create(:subnetwork)

    network
  end

  # Process Delete handler
  def forj_delete_network(sCloudObj, hParams)
    oProvider.delete(sCloudObj, hParams)
 rescue => e
   PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
  end

  def forj_get_network(sCloudObj, sID, hParams)
    oProvider.get(sCloudObj, sID, hParams)
 rescue => e
   PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
  end

  # Network Process internal functions #
  #------------------------------------#

  # Network creation
  # It returns:
  # nil or Provider Object
  def create_network(sCloudObj, hParams)
    name = hParams[:network_name]
    begin
      PrcLib.state("Creating network '%s'" % [name])
      network = controller_create(sCloudObj)
      PrcLib.info("Network '%s' created" % [network[:name]])
   rescue => e
     PrcLib.fatal(1, "Unable to create network '%s'" % [name, e])
    end
    network
  end

  # Search for a network from his name.
  # Name may be unique in project context, but not in the cloud system
  # It returns:
  # nil or Provider Object
  def find_network(sCloudObj, hParams)
    sQuery = { name: hParams[:network_name] }
    oList = controller_query(sCloudObj, sQuery)
    query_single(sCloudObj, oList, sQuery, hParams[:network_name])
 rescue => e
   PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
  end

  def forj_get_or_create_subnetwork(sCloudObj, hParams)
    PrcLib.state("Searching for sub-network attached to network '%s'" % [hParams[:network, :name]])
    #######################
    begin
      sQuery = { network_id: hParams[:network, :id] }
      subnets = controller_query(:subnetwork, sQuery)
   rescue => e
     PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
    if subnets
      case subnets.length
         when 0
           PrcLib.info("No subnet found from '%s' network" % [hParams[:network, :name]])
           subnet = ForjLib::Data.new
         when 1
           PrcLib.info("Found '%s' subnet from '%s' network" % [subnets[0, :name], hParams[:network, :name]])
           subnet = subnets[0]
         else
           PrcLib.warning("Several subnet was found on '%s'. Choosing the first one = '%s'" % [hParams[:network, :name], subnets[0, :name]])
           subnet = subnets[0]
      end
    end
    if !subnet || subnets.length == 0
      # Create the subnet
      begin
        subnet = create_subnet(sCloudObj, hParams)
     rescue => e
       PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
      end
    end
    register(subnet)
    subnet
  end

  def create_subnet(sCloudObj, hParams)
    name = hParams[:subnetwork_name]
    PrcLib.state("Creating subnet '%s'" % [name])
    begin
      subnet = controller_create(sCloudObj)
      PrcLib.info("Subnet '%s' created." % [subnet[:name]])
   rescue => e
     PrcLib.fatal(1, "Unable to create '%s' subnet." % name, e)
    end
    subnet
  end

  def delete_subnet
    oNetworkConnect = get_cloudObj(:network_connection)
    oSubNetwork = get_cloudObj(:subnetwork)

    PrcLib.state("Deleting subnet '%s'" % [oSubNetwork.name])
    begin
      provider_delete_subnetwork(oNetworkConnect, oSubNetwork)
      oNetworkConnect.subnets.get(oSubNetwork.id).destroy
   rescue => e
     PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
  end
end

# ---------------------------------------------------------------------------
# Router management
# ---------------------------------------------------------------------------
class CloudProcess
  # Process Create handler
  def forj_get_or_create_router(_sCloudObj, hParams)
    oSubNetwork = hParams[:subnetwork]

    unless hParams[:router_name]
      config[:router_name] = 'router-%s' % hParams[:network, :name]
      hParams[:router_name] = config[:router_name]
    end

    router_name = hParams[:router_name]
    router_port = get_router_interface_attached(:port, hParams)

    if !router_port || router_port.empty?
      # Trying to get router
      router = get_router(router_name)
      router = create_router(router_name) if !router || router.empty?
      create_router_interface(oSubNetwork, router) if router && !router.empty?
    else
      sQuery = { id: router_port[:device_id] }
      routers = controller_query(:router, sQuery)
      case routers.length
        when 1
          PrcLib.info("Found router '%s' attached to the network '%s'." % [
            routers[0, :name],
            hParams[:network, :name]
          ])
          router = routers[0]
        else
          PrcLib.warning("Unable to find the router id '%s'" % [router_port[:device_id]])
          router = ForjLib::Data.new

      end
    end
    router
  end

  def forj_update_router(sCloudObj, _hParams)
    controller_update(sCloudObj)
    ################################
    # routers[0].external_gateway_info = { 'network_id' => external_network.id }
    # routers[0].save
  end

  # Router Process internal functions  #
  #------------------------------------#

  def get_router(name)
    PrcLib.state("Searching for router '%s'" % [name])
    begin
      routers = controller_query(:router, name: name)
      case routers.length
         when 1
           routers[0]
         else
           PrcLib.info("Router '%s' not found." % [name])
           ForjLib::Data.new
      end
   rescue => e
     PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
  end

  def create_router(router_name, oExternalNetwork = nil)
    begin
      if oExternalNetwork
        sExtNet = get_data(oExternalNetwork, :name)
        PrcLib.state("Creating router '%s' attached to the external Network '%s'" % [router_name, sExtNet])
        config[:external_gateway_id] = get_data(oExternalNetwork, :id)
      else
        PrcLib.state("Creating router '%s' without external Network" % [router_name])
      end

      router = controller_create(:router)
      if oExternalNetwork
        PrcLib.info("Router '%s' created and attached to the external Network '%s'." % [router_name, sExtNet])
      else
        PrcLib.info("Router '%s' created without external Network." % [router_name])
      end
   rescue => e
     raise ForjError.new, "Unable to create '%s' router\n%s" % [router_name, e.message]
    end
    router
  end

  def delete_router(oNetworkConnect, oRouter)
    PrcLib.state("Deleting router '%s'" % [router.name])
    begin
      #################
      provider_delete_router(oNetworkConnect, oRouter)
   # oNetworkConnect.routers.get(router.id).destroy
   rescue => e
     PrcLib.error("Unable to delete '%s' router ID" % router_id, e)
    end
  end

  # TODO: Move router interface management to hpcloud controller.
  # Router interface to connect to the network
  def create_router_interface(oSubnet, oRouter)
    PrcLib.state("Attaching subnet '%s' to router '%s'" % [oSubnet[:name], oRouter[:name]])
    begin
      controller_create(:router_interface)

   #################
   # provider_add_interface()
   # oRouter.add_interface(oSubnet.id, nil)
   rescue => e
     PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
  end

  def delete_router_interface(oSubnet, oRouter)
    PrcLib.state("Removing subnet '%s' from router '%s'" % [oSubnet.name, oRouter.name])
    subnet_id = oSubnet.id
    begin
      #################
      oRouter.remove_interface(subnet_id)
    rescue => e
      PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
  end

  def get_router_interface_attached(sCloudObj, hParams)
    oNetwork = hParams[:network]
    PrcLib.state("Searching for router port attached to the network '%s'" % [hParams[:network, :name]])
    begin
      # Searching for router port attached
      #################
      sQuery = { network_id: hParams[:network, :id], device_owner: 'network:router_interface' }

      ports = controller_query(sCloudObj, sQuery)
      case ports.length
         when 0
           PrcLib.info("No router port attached to the network '%s'" % [hParams[:network, :name]])
           ForjLib::Data.new
         else
           PrcLib.info("Found a router port attached to the network '%s' " % [hParams[:network, :name]])
           ports[0]
      end
   rescue => e
     PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
  end

  # Gateway management
  def get_gateway(oNetworkConnect, name)
    return nil if !name || !oNetworkConnect

    PrcLib.state("Getting gateway '%s'" % [name])
    networks = oNetworkConnect
    begin
      netty = networks.get(name)
   rescue => e
     PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
    PrcLib.state("Found gateway '%s'" % [name]) if netty
    PrcLib.state("Unable to find gateway '%s'" % [name]) unless netty
    netty
  end

  def query_external_network(_hParams)
    PrcLib.state('Identifying External gateway')
    begin
      # Searching for router port attached
      #################
      sQuery = { router_external: true }
      networks = controller_query(:network, sQuery)
      case networks.length
        when 0
          PrcLib.info('No external network')
          ForjLib::Data.new
        when 1
          PrcLib.info("Found external network '%s'." % [networks[0, :name]])
          networks[0]
        else
          PrcLib.warn("Found several external networks. Selecting the first one '%s'" % [networks[0, :name]])
          networks[0]
      end
    rescue => e
      PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
  end
end

# ---------------------------------------------------------------------------
# SecurityGroups management
# ---------------------------------------------------------------------------

class CloudProcess
  # Process Create handler
  def forj_get_or_create_sg(sCloudObj, hParams)
    sSGName = hParams[:security_group]
    PrcLib.state("Searching for security group '%s'" % [sSGName])

    security_group = forj_query_sg(sCloudObj, { name: sSGName }, hParams)
    security_group = create_security_group(sCloudObj, hParams) unless security_group
    register(security_group)

    PrcLib.info('Configuring Security Group \'%s\'' % [sSGName])
    ports = config.get(:ports)

    ports.each do |port|
      port = port.to_s if port.class != String
      if !(/^\d+(-\d+)?$/ =~ port)
        PrcLib.error("Port '%s' is not valid. Must be <Port> or <PortMin>-<PortMax>" % [port])
      else
        mPortFound = /^(\d+)(-(\d+))?$/.match(port)
        portmin = mPortFound[1]
        portmax = (mPortFound[3]) ? (mPortFound[3]) : (portmin)
        # Need to set runtime data to get or if missing create the required rule.
        config[:dir]        = :IN
        config[:proto] = 'tcp'
        config[:port_min]   = portmin.to_i
        config[:port_max]   = portmax.to_i
        config[:addr_map]   = '0.0.0.0/0'

        # object.Create(:rule)
        Create(:rule)
      end
    end
    security_group
  end

  # Process Delete handler
  def forj_delete_sg(oFC, security_group)
    oSSLError = SSLErrorMgt.new
    begin
      sec_group = get_security_group(oFC, security_group)
      oFC.oNetwork.security_groups.get(sec_group.id).destroy
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
  end

  # Process Query handler
  def forj_query_sg(sCloudObj, sQuery, hParams)
    oSSLError = SSLErrorMgt.new

    begin
      sgroups = controller_query(sCloudObj, sQuery)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
     PrcLib.fatal(1, 'Unable to get list of security groups.', e)
    end
    case sgroups.length
       when 0
         PrcLib.info("No security group '%s' found" % [hParams[:security_group]])
         nil
       when 1
         PrcLib.info("Found security group '%s'" % [sgroups[0, :name]])
         sgroups[0]
    end
  end

  # SecurityGroups Process internal functions #
  #-------------------------------------------#
  def create_security_group(sCloudObj, hParams)
    PrcLib.state("Creating security group '%s'" % hParams[:security_group])
    begin
      sg = controller_create(sCloudObj)
      PrcLib.info("Security group '%s' created." % sg[:name])
    rescue => e
      PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
    sg
  end

  # Rules handler #
  #---------------#

  # Process Delete handler
  def forj_delete_security_group_rule(sCloudObj, _hParams)
    oSSLError = SSLErrorMgt.new
    begin
      controller_delete(sCloudObj)
    rescue => e
      unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
        retry
      end
    end
  end

  # Process Query handler
  def forj_query_rule(sCloudObj, sQuery, hParams)
    sRule = '%s %s:%s - %s to %s' % [hParams[:dir], hParams[:rule_proto], hParams[:port_min], hParams[:port_max], hParams[:addr_map]]
    PrcLib.state("Searching for rule '%s'" % [sRule])
    oSSLError = SSLErrorMgt.new
    begin
      sInfo = {
        items: [:dir, :rule_proto, :port_min, :port_max, :addr_map],
        items_form: '%s %s:%s - %s to %s'
      }
      oList = controller_query(sCloudObj, sQuery)
      query_single(sCloudObj, oList, sQuery, sRule, sInfo)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
   end

  # Process Create handler
  def forj_get_or_create_rule(sCloudObj, hParams)
    sQuery = {
      dir: hParams[:dir],
      proto: hParams[:proto],
      port_min: hParams[:port_min],
      port_max: hParams[:port_max],
      addr_map: hParams[:addr_map],
      sg_id: hParams[:sg_id]
    }

    rules = forj_query_rule(sCloudObj, sQuery, hParams)
    if rules.length == 0
      create_rule(sCloudObj, hParams)
    else
      rules[0]
    end
  end

  # Rules internal #
  #----------------#
  def create_rule(sCloudObj, hParams)
    sRule = '%s %s:%s - %s to %s' % [hParams[:dir], hParams[:rule_proto], hParams[:port_min], hParams[:port_max], hParams[:addr_map]]
    PrcLib.state("Creating rule '%s'" % [sRule])
    oSSLError = SSLErrorMgt.new
    begin
      rule = controller_create(sCloudObj)
      PrcLib.info("Rule '%s' created." % [sRule])
   rescue StandardError => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
     PrcLib.error 'error creating the rule for port %s' % [sRule]
    end
    rule
  end
end

# ---------------------------------------------------------------------------
# External network process attached to a network
# ---------------------------------------------------------------------------
class CloudProcess
  def forj_get_or_create_ext_net(sCloudObj, hParams)
    PrcLib.state("Checking router '%s' gateway" % hParams[:router, :name])

    oRouter = hParams[:router]
    sRouterName = hParams[:router, :name]
    sNetworkId = hParams[:router, :gateway_network_id]
    if sNetworkId
      external_network = forj_query_external_network(sCloudObj, { id: sNetworkId }, hParams)
      PrcLib.info("Router '%s' is attached to the external gateway '%s'." % [sRouterName, external_network[:name]])
    else
      PrcLib.info("Router '%s' needs to be attached to an external gateway." % [sRouterName])
      PrcLib.state('Attaching')
      external_network = forj_query_external_network(:network, {}, hParams)
      if !external_network.empty?
        oRouter[:gateway_network_id] = external_network[:id]
        forj_update_router(:router, hParams)
        PrcLib.info("Router '%s' attached to the external network '%s'." % [sRouterName, external_network[:name]])
      else
        PrcLib.fatal(1, "Unable to attach router '%s' to an external gateway. Required for boxes to get internet access. " % [get_data(:router, :name)])
      end
    end

    # Need to keep the :network object as :external_network object type.
    external_network.type = sCloudObj
    external_network
  end

  def forj_query_external_network(_sCloudObj, sQuery, _hParams)
    PrcLib.state('Identifying External gateway')
    begin
      # Searching for external network
      networks = controller_query(:network, sQuery.merge(external: true))

      case networks.length
      when 0
        PrcLib.info('No external network')
        nil
      when 1
        PrcLib.info("Found external network '%s'." % [networks[0, :name]])
        networks[0]
      else
        PrcLib.warning("Found several external networks. Selecting the first one '%s'" % [networks[0, :name]])
        networks[0]
      end
   rescue => e
     PrcLib.error("%s\n%s" % [e.message, e.backtrace.join("\n")])
    end
  end
end

# ---------------------------------------------------------------------------
# Internet network process
# ---------------------------------------------------------------------------
class CloudProcess
end
