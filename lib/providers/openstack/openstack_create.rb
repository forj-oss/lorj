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

# Defined Openstack object create.
class OpenstackController
  def create_security_groups(hParams)
    required?(hParams, :network_connection)
    required?(hParams, :tenants)
    required?(hParams, :security_group)

    service = hParams[:network_connection]

    service.security_groups.create(:name => hParams[:security_group],
                                   :tenant_id => hParams[:tenants].id)
  end

  def create_rule(hParams)
    required?(hParams, :network_connection)
    required?(hParams, :security_groups)
    hParams[:network_connection].security_group_rules.create(hParams[:hdata])
  end

  def create_keypairs(hParams)
    required?(hParams, :compute_connection)
    required?(hParams, :keypair_name)
    required?(hParams, :public_key)

    # API:
    # https://github.com/fog/fog/blob/master/lib/fog/openstack/docs/compute.md
    service = hParams[:compute_connection]
    service.key_pairs.create(:name => hParams[:keypair_name],
                             :public_key => hParams[:public_key])
  end

  def create_server(hParams)
    [:compute_connection, :image,
     :network, :flavor, :keypairs,
     :security_groups, :server_name].each do |required_param|
      required?(hParams, required_param)
    end

    options = {
      :name             => hParams[:server_name],
      :flavor_ref       => hParams[:flavor].id,
      :image_ref        => hParams[:image].id,
      :key_name         => hParams[:keypairs].name,
      :security_groups  => [hParams[:security_groups].name],
      :nics             => [{ :net_id => hParams[:network].id }]
    }

    if hParams[:user_data]
      options[:user_data_encoded] =
        Base64.strict_encode64(hParams[:user_data])
    end
    options[:metadata] = hParams[:meta_data] if hParams[:meta_data]

    compute_connect = hParams[:compute_connection]

    server = compute_connect.servers.create(options)
    compute_connect.servers.get(server.id) if server
  end

  def create_public_ip(hParams)
    required?(hParams, :compute_connection)
    required?(hParams, :server)

    compute_connect = hParams[:compute_connection]
    server = hParams[:server]

    while server.state != 'ACTIVE'
      sleep(5)
      server = compute_connect.servers.get(server.id)
    end

    addresses = compute_connect.addresses.all
    address = nil
    # Search for an available IP
    addresses.each do |elem|
      if elem.fixed_ip.nil?
        address = elem
        break
      end
    end

    if address.nil?
      # Create a new public IP to add in the pool.
      address = compute_connect.addresses.create
    end
    if address.nil?
      controller_error("No Public IP to assign to server '%s'", server.name)
    end

    address.server = server # associate the server
    address.reload
    # This function needs to returns a list of object.
    # This list must support the each function.
    address
  end
end
