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
require 'encryptor'
require 'base64'

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
  # SSL Encryption feature for Lorj.
  module SSLCrypt
    # internal runtime function to create a new key
    # *parameters*:
    #   - +new+       : true to create a new key.
    #
    # *return*:
    #   - entropy: Hash. Entropy data used as key to encrypt values.
    #     Details from encryptor's gem.
    #     - :key: password
    #     - :salt : String current time number
    #     - :iv: Base64 random iv
    def self.new_encrypt_key(key = rand(36**10).to_s(36))
      random_iv = OpenSSL::Cipher::Cipher.new('aes-256-cbc').random_iv
      {
        :key => key,
        :salt => Time.now.to_i.to_s,
        :iv => Base64.strict_encode64(random_iv)
      }
    end

    # internal runtime function for process call #_build_hdata and
    # #_get_encrypted_value_hidden
    # Get encrypted value
    #
    # *parameters*:
    #   - +default+     : encrypted default value
    #   - +entropy+     : Entropy Hash
    #   - +sDesc+       : data description
    #
    # *return*:
    # - value : decrypted value.
    #
    # *raise*:
    #
    def self.get_encrypted_value(enc_value, entr, sDesc)
      return '' if enc_value.nil?
      begin
        Encryptor.decrypt(
          :value => Base64.strict_decode64(enc_value),
          :key => entr[:key],
          :iv => Base64.strict_decode64(entr[:iv]),
          :salt => entr[:salt]
        )
      rescue => e
        PrcLib.error("Unable to decrypt your %s.\n"\
                     "%s\n"\
                     ' You will need to re-enter it.',
                     sDesc, e)
      end
    end

    # Function to encrypt a data with a entr key.
    #
    # *return*:
    # - value : encrypted value in Base64 encoded data.
    def self.encrypt_value(value, entr)
      Base64.strict_encode64(
        Encryptor.encrypt(
          :value => value,
          :key => entr[:key],
          :iv => Base64.strict_decode64(entr[:iv]),
          :salt => entr[:salt]
        )
      )
    end
  end

  # Adding encrypt core functions.
  class BaseDefinition
    private

    # internal runtime function for process call
    # Get encrypted value hidden by *
    #
    # Use PrcLib.pdata_path to store/read a '.key' file
    #
    # *parameters*:
    #   - +new+       : true to create a new key.
    #
    # *return*:
    # - value : encrypted key value.
    #
    # *raise*:
    #
    def _get_encrypt_key
      # Checking key file used to encrypt/decrypt passwords
      key_file = File.join(PrcLib.pdata_path, '.key')
      if !File.exist?(key_file)
        # Need to create a random key.
        entr = Lorj::SSLCrypt.new_encrypt_key

        Lorj.debug(2, "Writing '%s' key file", key_file)
        unless PrcLib.dir_exists?(PrcLib.pdata_path)
          PrcLib.ensure_dir_exists(PrcLib.pdata_path)
        end
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
        value_hidden = '*' * Lorj::SSLCrypt.get_encrypted_value(enc_value, entr,
                                                                sDesc).length
      rescue => e
        PrcLib.error('Unable to decrypt your %s. You will need to re-enter it.'\
                     '\n%s', sDesc, e.message)
      else
        PrcLib.message("'%s' is already set. If you want to keep it,"\
                       ' just press Enter', sDesc)
      end
      value_hidden
    end

    # internal runtime function for process call
    # Ask encrypted function executed by _ask
    #
    # *parameters*:
    #   - +sDesc+       : data description
    #   - +default+     : encrypted default value
    #
    # *return*:
    # - value : encrypted value in Base64.
    #
    # *raise*:
    #
    def _ask_encrypted(sDesc, default)
      entr = _get_encrypt_key

      enc_value = default unless default == ''

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
      Lorj::SSLCrypt.encrypt_value(value_free, entr)
    end
  end
end
