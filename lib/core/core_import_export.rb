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
  # Implements account_import and account_export
  # exposed by core.
  class BaseDefinition
    # Function to import an encrypted Hash as a Lorj Account.
    #
    # The encrypted Hash will be decrypted by the key provided.
    # The content of the hash will be stored in the 'account' layer
    # of config.
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
    # will call ac_update except if name is an empty string.
    #
    # The location used comes from PrcLib.data_path
    # Passwords will be encrypted by the internal .key file stored in
    # PrcLib.pdata_path
    #
    # The imported Hash will follow the process data model. But it won't
    # verify if some data are missed for any object action (create/delete/...)
    #
    # * *Args* :
    #   - +key+        : key to use to decrypt the 'enc_hash'.
    #   - +enc_hash+   : Encrypted Hash.
    #   - +name+       : Optional. Name of the account.
    #   - +controller+ : Optional. Name of the controller.
    #
    # * *Raises* :
    #   No exceptions
    def account_import(key, enc_hash, name = nil, controller = nil)
      hash = _get_encrypted_value(enc_hash, key, 'Encrypted account data')

      data = YAML.load(hash)

      _update_account_meta(data, name, controller)

      entr = _get_encrypt_key

      data.each do |s, sh|
        sh.each do |k, v|
          key = "#{s}##{k}"
          data_def = Lorj.data.auto_section_data(key)
          if data_def && data_def[:encrypted].is_a?(TrueClass)
            v = _encrypt_value(v, entr)
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
          data = _get_encrypted_value(data, entr, data_def[:desc])
        end
        rhash.rh_set(data, *rhash_tree)
      end

      entr = _new_encrypt_key
      [entr, _encrypt_value(rhash.to_yaml, entr)]
    end

    private

    def _update_account_meta(data, name, controller)
      if name.nil? && data.rh_exist?(:account, :name)
        name = data.rh_get(:account, :name)
      end
      if controller.nil? && data.rh_exist?(:account, :provider)
        controller = data.rh_get(:account, :provider)
      end

      name = nil if name == ''

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
