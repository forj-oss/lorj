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

#
module Lorj
  # Function to import an encrypted Hash as a Lorj Account.
  #
  # The encrypted Hash will be decrypted by the key provided.
  # The content of the hash will be stored in the 'account' layer
  # of config.
  #
  # For details on how import work, look in #account_data_import
  #
  # * *Args* :
  #   - +key+         : key to use to decrypt the 'enc_hash'.
  #   - +import_data+ : import data. This data is structured as follow:
  #     - :enc_data : The encrypted account data.
  #     - :processes: Array or models + controllers to load.
  #   - +name+        : Optional. Name of the account.
  #
  # * *returns*:
  #   - +core+ : Core object, with loaded model, created during the import.
  #
  # * *Raises* :
  #   No exceptions
  def self.account_import(key, import_data, name = nil)
    hash = Lorj::SSLCrypt.get_encrypted_value(import_data[:enc_data], key,
                                              'Encrypted account data')

    data = YAML.load(hash)

    processes = import_data[:processes]

    processes.each do |p|
      next unless p.key?(:process_module)

      PrcLib.debug("Loading module '#{p[:process_module]}' from GEM lib '%s'",
                   p[:lib_name])
      begin
        require "#{p[:lib_name]}"
      rescue => e
        PrcLib.error("Unable to load module '#{p[:process_module]}'\n%s", e)
      end
    end

    core = Lorj::Core.new(Lorj::Account.new, processes)
    core.account_import(data, name)

    core
  end

  # Implements account_import and account_export
  # exposed by core.
  class BaseDefinition
    # Function to import an account data in Lorj::Account.
    #
    # The 'account' layer is not cleaned before. If you need to
    # clean it up, do:
    #     config.ac_new(account_name, controller_name)
    #
    # or if the Hash data contains :name and :provider
    #     config.ac_erase
    #
    # To save it in a file, you will need to call
    #     config.ac_save(filename)
    #
    # If you pass 'name' and 'controller', ac_update will be used to update the
    # account data
    # If the imported data contains name and controller data, by default, it
    # will call ac_update.
    #
    # The location used comes from PrcLib.data_path
    # Passwords will be encrypted by the internal .key file stored in
    # PrcLib.pdata_path
    #
    # The imported Hash will follow the process data model. But it won't
    # verify if some data are missed for any object action (create/delete/...)
    #
    # * *Args* :
    #   - +data+       : Account data to import.
    #   - +name+       : Optional. Name of the account.
    #
    # * *Raises* :
    #   No exceptions
    def account_data_import(data, name = nil)
      _update_account_meta(data, name)

      entr = _get_encrypt_key

      data.each do |s, sh|
        sh.each do |k, v|
          key = "#{s}##{k}"
          data_def = Lorj.data.auto_section_data(key)
          if data_def && data_def[:encrypted].is_a?(TrueClass)
            v = Lorj::SSLCrypt.encrypt_value(v, entr)
          end
          config.set(key, v, :name => 'account')
        end
      end
    end

    # Function to export a Lorj Account in an encrypted Hash.
    #
    # The encrypted Hash will be encrypted by a new key returned.
    # The content of the hash will built thanks to a Hash mapping
    # or the list of data list in the config 'account' layer.
    #
    # * *Args* :
    #   - +map+          : Hash map of fields to extract. if map is nil, the
    #     export function will loop in the list of keys in the 'account' layer.
    #     if map is provided, following data are expected:
    #     - <key> : Data key to extract from config.
    #       - :keys: Array. SubHash tree of keys to create. If :keys is missing,
    #         the Data key will define the SubHash tree to use.
    #
    #         Ex:
    #             map = {
    #               # like :keys => [credentials, auth_uri]
    #               'credentials#auth_uri' => {},
    #               # extract from maestro but export under :server
    #               'maestro#image_name' => {:keys => [:server, image_name]}
    #               }
    #   - +with_name+    : True to extract :name and :provider as well.
    #     True by default.
    #   - +account_only+ : True data extracted must come exclusively from the
    #     config 'account' layer.
    #
    # * *returns* :
    #   - key: String. Key used to encrypt.
    #   - env_hash: String. Base64 encrypted Hash.
    #   OR
    #   - nil if issues.
    def account_export(map = nil, with_name = true, account_only = true)
      map = _account_map if map.nil?

      map.merge!('account#name' => {}, 'account#provider' => {}) if with_name

      entr = _get_encrypt_key
      rhash = {}
      map.each do |k, v|
        data_def = Lorj.data.auto_section_data(k)

        if account_only
          data = config.get(k, nil, :name => 'account')
        else
          data = config[k]
        end

        rhash_tree = Lorj.data.first_section(k)
        rhash_tree = v[:keys] if v.key?(:keys)
        if !data_def.nil? && data_def[:encrypted].is_a?(TrueClass)
          data = Lorj::SSLCrypt.get_encrypted_value(data, entr, data_def[:desc])
        end
        rhash.rh_set(data, *rhash_tree)
      end

      entr = Lorj::SSLCrypt.new_encrypt_key
      export_data = { :enc_data => Lorj::SSLCrypt.encrypt_value(rhash.to_yaml,
                                                                entr) }
      export_data[:processes] = _export_processes
      [entr, export_data]
    end

    private

    def _export_processes
      export_data = []
      PrcLib.processes.each do |p|
        next unless p.key?(:process_name) && p.key?(:lib_name)

        process = {}
        process[:process_module] = p[:process_name]
        process[:lib_name] = p[:lib_name]
        process[:controller] = p[:controller_name] if p.key?(:controller_name)
        export_data << process if process.length > 0
      end
      export_data
    end

    def _update_account_meta(data, name)
      if name.nil? && data.rh_exist?(:account, :name)
        name = data.rh_get(:account, :name)
      end
      controller = data.rh_get(:account, :provider)

      name = nil if name == ''
      controller = nil if controller == ''

      config.ac_update(name, controller) unless name.nil? || controller.nil?
    end

    def _account_map
      map = {}

      config.each(:name => 'account') do |s, v|
        next unless v.is_a?(Hash)
        v.keys.each do |k|
          unless s == :account && [:name, :provider].include?(k)
            map["#{s}##{k}"] = {}
          end
        end
      end
      map
    end
  end
end
