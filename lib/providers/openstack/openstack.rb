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

# This class describes how to process some actions, and will do everything prior
# this task to make it to work.
require 'fog'
require 'uri'

hpcloud_path = File.expand_path(File.dirname(__FILE__))

require File.join(hpcloud_path, 'openstack_query.rb')
require File.join(hpcloud_path, 'openstack_get.rb')
require File.join(hpcloud_path, 'openstack_delete.rb')
require File.join(hpcloud_path, 'openstack_create.rb')

# Defines Meta Openstack object
class Openstack
  define_obj :compute_connection
  # Defines Data used by compute.

  obj_needs :data, :account_id,  :mapping => :openstack_username
  obj_needs :data, :account_key, :mapping => :openstack_api_key,
                                 :decrypt => true
  obj_needs :data, :auth_uri,    :mapping => :openstack_auth_url
  obj_needs :data, :tenant,      :mapping => :openstack_tenant

  obj_needs_optional
  # Required for HPHelion
  obj_needs :data, :compute,     :mapping => :openstack_region

  define_obj :network_connection
  obj_needs :data, :account_id,  :mapping => :openstack_username
  obj_needs :data, :account_key, :mapping => :openstack_api_key,
                                 :decrypt => true
  obj_needs :data, :auth_uri,    :mapping => :openstack_auth_url
  obj_needs :data, :tenant,      :mapping => :openstack_tenant

  obj_needs_optional
  # Required for HPHelion
  obj_needs :data, :network,     :mapping => :openstack_region

  define_obj :network
  query_mapping :external, :router_external

  define_obj :keypairs

  undefine_attribute :id    # Do not return any predefined ID

  define_obj :server_log

  # Excon::Response object type
  def_attr_mapping :output, 'output'

  define_obj :rule
  obj_needs :data, :dir,        :mapping => :direction
  attr_value_mapping :IN,  'ingress'
  attr_value_mapping :OUT, 'egress'

  obj_needs :data, :proto,      :mapping => :protocol
  obj_needs :data, :port_min,   :mapping => :port_range_min
  obj_needs :data, :port_max,   :mapping => :port_range_max
  obj_needs :data, :addr_map,   :mapping => :remote_ip_prefix
  obj_needs :data, :sg_id,      :mapping => :security_group_id

  def_attr_mapping :dir,      :direction
  def_attr_mapping :proto,    :protocol
  def_attr_mapping :port_min, :port_range_min
  def_attr_mapping :port_max, :port_range_max
  def_attr_mapping :addr_map, :remote_ip_prefix
  def_attr_mapping :sg_id,    :security_group_id

  define_data(:account_id,
              :account => true,
              :desc => 'Openstack Username',
              :validate => /^.+/
  )

  define_data(:account_key,
              :account => true,
              :desc => 'Openstack Password',
              :validate => /^.+/
  )
  define_data(:auth_uri,
              :account => true,
              :explanation => "The authentication service is identified as '"\
                "identity' under your horizon UI - Project/Compute then "\
                'Access & security.',
              :desc => 'Openstack Authentication service URL. '\
                'Ex: https://mycloud:5000/v2.0/tokens',
              :validate => %r{^http(s)?:\/\/.*\/tokens$}
  )
  define_data(:tenant,
              :account => true,
              :explanation => 'The Project name is shown from your horizon UI'\
                ', on top left, close to the logo',
              :desc => 'Openstack Tenant Name',
              :validate => /^.+/
  )

  define_data(:compute,
              :account => true,
              :explanation => 'Depending on your installation, you may need to'\
                ' provide a Region name. This information shown under your '\
                'horizon UI - close right to the project name (top left).'\
                "\nIf there is no region shown, you can ignore it.",
              :desc => 'Openstack Compute Region (Ex: regionOne)'
  )

  define_data(:network,
              :account => true,
              :desc => 'Openstack Network Region (Ex: regionOne)',
              :explanation => 'Depending on your installation, you may need to'\
                ' provide a Region name. This information shown under your '\
                'horizon UI - close right to the project name (top left).'\
                "\nIf there is no region shown, you can ignore it."
  )

  define_obj :server
  def_attr_mapping :status, :state
  attr_value_mapping :create, 'BUILD'
  attr_value_mapping :boot,   :boot
  attr_value_mapping :active, 'ACTIVE'
  attr_value_mapping :active, 'ACTIVE'

  def_attr_mapping :private_ip_address, :accessIPv4
  def_attr_mapping :public_ip_address, :accessIPv4
  def_attr_mapping :image_id, [:image, 'id']

  define_obj :router
  obj_needs_optional
  obj_needs :data, :router_name, :mapping => :name

  # The FORJ gateway_network_id is extracted
  # from Fog::HP::Network::Router[:external_gateway_info][:network_id]

  obj_needs :data,
            :external_gateway_id,
            :mapping => [:external_gateway_info, 'network_id']

  def_attr_mapping :gateway_network_id,
                   [:external_gateway_info, 'network_id']

  define_obj :public_ip
  def_attr_mapping :server_id, :instance_id
  def_attr_mapping :public_ip, :ip

  define_obj :image
  def_attr_mapping :image_name, :name
end

# Following class describe how FORJ should handle Openstack Cloud objects.
class OpenstackController
  def self.def_cruds(*crud_types)
    crud_types.each do |crud_type|
      case crud_type
      when :create, :delete
        define_method(crud_type) do |sObjectType, hParams|
          method_name = "#{crud_type}_#{sObjectType}"
          if self.class.method_defined? method_name
            send(method_name, hParams)
          else
            controller_error "'%s' is not a valid object for '%s'",
                             sObjectType, crud_type
          end
        end
      when :query, :get
        define_method(crud_type) do |sObjectType, sCondition, hParams|
          method_name = "#{crud_type}_#{sObjectType}"
          if self.class.method_defined? method_name
            send(method_name, hParams, sCondition)
          else
            controller_error "'%s' is not a valid object for '%s'",
                             sObjectType, crud_type
          end
        end
      end
    end
  end

  def connect(sObjectType, hParams)
    case sObjectType
    when :compute_connection
      Fog::Compute.new(
        hParams[:hdata].merge(:provider => :openstack)
      )
    when :network_connection
      Fog::Network::OpenStack.new(hParams[:hdata])
    else
      controller_error "'%s' is not a valid object for 'connect'", sObjectType
    end
  end

  def_cruds :create, :delete, :get, :query

  def set_attr(oControlerObject, key, value)
    if oControlerObject.is_a?(Excon::Response)
      controller_error "No set feature for '%s'", oControlerObject.class
    end

    attributes = oControlerObject.attributes

    controller_error "attribute '%s' is unknown in '%s'. Valid one are : '%s'",
                     key[0],
                     oControlerObject.class,
                     oControlerObject.class.attributes unless
                     oControlerObject.class.attributes.include?(key[0])

    attributes.rh_set(value, key)
  rescue => e
    controller_error "Unable to map '%s' on '%s'. %s",
                     key, oControlerObject, e.message
  end

  def get_attr(oControlerObject, key)
    if oControlerObject.is_a?(Excon::Response)
      oControlerObject.data.rh_get(:body, key)
    else
      attributes = oControlerObject.attributes
      controller_error "attribute '%s' is unknown in '%s'."\
                       " Valid one are : '%s'",
                       key[0],
                       oControlerObject.class,
                       oControlerObject.class.attributes unless
                       oControlerObject.class.attributes.include?(key[0])
      attributes.rh_get(key)
    end
  rescue => e
    controller_error "==>Unable to map '%s'. %s", key, e.message
  end
end
