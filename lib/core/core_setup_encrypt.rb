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

require 'highline/import'

# Module Lorj which contains several classes.
#
# Those classes describes :
# - processes (BaseProcess)   : How to create/delete/edit/query object.
# - controler (BaseControler) : If a provider is defined, define how will do
#                               object creation/etc...
# - definition(BaseDefinition): Functions to declare objects, query/data mapping
#                               and setup
# this task to make it to work.
module Lorj
  # Adding encrypt core functions.
  class BaseDefinition
    # internal runtime function for process call
    # Get encrypted value hidden by *
    #
    # *parameters*:
    #   - +sDesc+       : data description
    #   - +default+     : encrypted default value
    #   - +entropy+     : Entropy Hash
    #
    # *return*:
    # - value : encrypted value.
    #
    # *raise*:
    #
    def _get_encrypt_key
      # Checking key file used to encrypt/decrypt passwords
      key_file = File.join(PrcLib.pdata_path, '.key')
      if !File.exist?(key_file)
        # Need to create a random key.
        random_iv = OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
        entr = {
          :key => rand(36**10).to_s(36),
          :salt => Time.now.to_i.to_s,
          :iv => Base64.strict_encode64(random_iv)
        }

        Lorj.debug(2, "Writing '%s' key file", key_file)
        PrcLib.ensure_dir_exists(
          PrcLib.pdata_path
        ) unless PrcLib.dir_exists?(PrcLib.pdata_path)
        File.open(key_file, 'w+') do |out|
          out.write(Base64.encode64(entr.to_yaml))
        end
      else
        Lorj.debug(2, "Loading '%s' key file", key_file)
        encoded_key = IO.read(key_file)
        entr = YAML.load(Base64.decode64(encoded_key))
      end
      entr
    end

    # internal runtime function for process call
    # Get encrypted value hidden by *
    #
    # *parameters*:
    #   - +sDesc+       : data description
    #   - +default+     : encrypted default value
    #   - +entropy+     : Entropy Hash
    #
    # *return*:
    # - value : encrypted value.
    #
    # *raise*:
    #
    def _get_encrypted_value_hidden(sDesc, enc_value, entr)
      return '' if enc_value.nil?
      value_hidden = ''
      begin
        value_hidden = '*' * _get_encrypted_value(enc_value, entr).length
      rescue
        PrcLib.error('Unable to decrypt your %s. You will need to re-enter it.',
                     sDesc)
      else
        PrcLib.message("'%s' is already set. If you want to keep it,"\
                       ' just press Enter', sDesc)
      end
      value_hidden
    end

    # internal runtime function for process call #_build_hdata and
    # #_get_encrypted_value_hidden
    # Get encrypted value
    #
    # *parameters*:
    #   - +default+     : encrypted default value
    #   - +entropy+     : Entropy Hash
    #
    # *return*:
    # - value : decrypted value.
    #
    # *raise*:
    #
    def _get_encrypted_value(enc_value, entr)
      return '' if enc_value.nil?
      begin
        Encryptor.decrypt(
          :value => Base64.strict_decode64(enc_value),
          :key => entr[:key],
          :iv => Base64.strict_decode64(entr[:iv]),
          :salt => entr[:salt]
        )
      rescue
        PrcLib.error('Unable to decrypt your %s. You will need to re-enter it.',
                     sDesc)
      end
    end

    # internal runtime function for process call
    # Ask encrypted function executed by _ask
    #
    # *parameters*:
    #   - +sDesc+       : data description
    #   - +default+     : encrypted default value
    #
    # *return*:
    # - value : encrypted value.
    #
    # *raise*:
    #
    def _ask_encrypted(sDesc, default)
      entr = _get_encrypt_key

      enc_value = default

      value_hidden = _get_encrypted_value_hidden(sDesc, default, entr)

      value_free = ''
      while value_free == ''
        # ask for encrypted data.
        value_free = ask(format('Enter %s: |%s|', sDesc, value_hidden)) do |q|
          q.echo = '*'
        end
        if value_free == '' && enc_value
          value_free = Encryptor.decrypt(
            :value => Base64.strict_decode64(enc_value),
            :key => entr[:key],
            :iv => Base64.strict_decode64(entr[:iv]),
            :salt => entr[:salt]
          )
        else
          PrcLib.message('%s cannot be empty.', sDesc) if value_free == ''
        end
      end
      Base64.strict_encode64(
        Encryptor.encrypt(
          :value => value_free,
          :key => entr[:key],
          :iv => Base64.strict_decode64(entr[:iv]),
          :salt => entr[:salt]
        )
      )
    end
  end
end
