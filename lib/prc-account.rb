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

require 'rubygems'

module Lorj

   class Accounts
      # Class to query FORJ Accounts list.
      def initialize()
      end

      def dump()
         aAccounts=[]
         Dir.foreach($FORJ_ACCOUNTS_PATH) { |x| aAccounts << x if not x.match(/^\..?$/) }
         aAccounts
      end
   end

   # Lorj::Account manage a list of key/value grouped by section.
   # The intent of Lorj::Account is to attach some keys/values to
   # an account to help end users to switch between each of them.
   #
   # Lorj::Account based on ForjConfig (see forj-config.rb)
   # ensure ForjConfig and Lorj::Account defines following common functions
   # - set (key, value)
   # - get (key)
   #
   # This means that key HAVE to be unique across sections
   # By default, keys maps with the same key name in ForjConfig.
   # But we can redefine the ForjConfig mapping of any key on need.
   #
   # ForjConfig, loads Account meta structure from defaults.yaml, sections
   #
   # defaults.yaml structure is:
   # sections:
   #   default: => defines key/values recognized by Lorj::Account to be only managed by ForjConfig.
   #     <key> :
   #       :desc : <value> => defines the ForjConfig key description.
   #   <section>: Define a section name. For each keys on this section, the account file will kept those data under this section.
   #     <key>:
   #       :desc:              defines the key description.
   #       :readonly:          true if this key cannot be updated by Lorj::Account.set
   #       :account_exclusive: true if this key cannot be predefined on ForjConfig keys list
   #       :default:           <ForjConfig real key name> Used to map the Lorj::Account key to a different ForjConfig key name.

   class Account

      attr_reader :sAccountName
      attr_reader :hAccountData
      attr_reader :oConfig

      # This object manage data located in oConfig[:hpc_accounts/AccountName]

      def initialize(oConfig = nil)
         # Initialize object
         if oConfig.nil?
            @oConfig = Lorj::Config.new()
         elsif oConfig.is_a?(String)
            @oConfig = Lorj::Config.new()
            @oConfig[:account_name] = oConfig
         else
            @oConfig = oConfig
         end

         if @oConfig.exist?(:account_name)
            @sAccountName = @oConfig[:account_name]
         else
            @sAccountName = 'lorj'
         end
         @sAccountFile = File.join(PrcLib.data_path, 'accounts', @sAccountName)

         sProvider = 'lorj'
         sProvider = @oConfig.get(:provider) if @oConfig.get(:provider)

         @hAccountData = {}
         _set(:account, :name, @sAccountName) if exist?(:name) != 'hash'
         _set(:account, :provider, sProvider)  if exist?(:provider) != 'hash'

         PrcLib.ensure_dir_exists(File.join(PrcLib.data_path, 'accounts'))
      end

      # oForjAccount data get at several levels:
      # - runtime    : get the data from runtime (runtimeSet/runtimeGet)
      # - Account    : otherwise, get data from account file under section described in defaults.yaml (:account_section_mapping), as soon as this mapping exists.
      # - local      : otherwise, get the data from the local configuration file. Usually ~/.forj/config.yaml
      # - application: otherwise, get the data from defaults.yaml (class Default)
      # - default    : otherwise, use the get default parameter as value. Default is nil.
      #
      # * *Args*    :
      #   - +key+     : key name. It do not support it to be a key tree (Arrays of keys).
      #   - +default+ : default value, if not found.
      # * *Returns* :
      #   - key value.
      # * *Raises* :
      #   Nothing
      def get(key, default = nil)
         return nil if not key

         key = key.to_sym if key.class == String

         return @oConfig.runtimeGet(key) if @oConfig.runtimeExist?(key)

         section = Lorj::Default.get_meta_section(key)
         default_key = key

         if not section
            PrcLib.debug("Lorj::Account.get: Unable to get account data '%s'. No section found. check defaults.yaml." % [key])
         else
            return Lorj::rhGet(@hAccountData, section, key) if Lorj::rhExist?(@hAccountData, section, key) == 2

            hMeta = @oConfig.getAppDefault(:sections)
            if Lorj::rhExist?(hMeta, section, key, :default) == 3
               default_key = Lorj::rhGet(hMeta, section, key, :default)
               PrcLib.debug("Lorj::Account.get: Reading default key '%s' instead of '%s'" % [default_key, key])
            end
            return default if Lorj::rhExist?(hMeta, section, key, :account_exclusive) == 3
         end

         @oConfig.get(default_key , default )
      end

      def [](key, default = nil)
         get(key, default)
      end

      # check key/value existence in the following order:
      # - runtime    : get the data from runtime (runtimeSet/runtimeGet)
      # - Account    : otherwise, get data from account file under section described in defaults.yaml (:account_section_mapping), as soon as this mapping exists.
      # - local      : otherwise, get the data from the local configuration file. Usually ~/.forj/config.yaml
      # - application: otherwise, get the data from defaults.yaml (class Default)
      #
      # * *Args*    :
      #   - +key+     : key name. It do not support it to be a key tree (Arrays of keys).
      #   - +default+ : default value, if not found.
      # * *Returns* :
      #   - 'runtime'       : if found in runtime.
      #   - '<AccountName>' : if found in the Account data structure.
      #   - 'local'         : if found in the local configuration file. Usually ~/.forj/config.yaml
      #   - 'default'       : if found in the Application default (File 'defaults.yaml') (class Default)
      # * *Raises* :
      #   Nothing

      def exist?(key)
         return nil if not key

         key = key.to_sym if key.class == String
         section = Lorj::Default.get_meta_section(key)
         if not section
            PrcLib.debug("Lorj::Account.exist?: No section found for key '%s'." % [key])
            return nil
         end

         return 'runtime' if @oConfig.runtimeExist?(key)

         return @sAccountName if Lorj::rhExist?(@hAccountData, section, key) == 2

         hMeta = @oConfig.getAppDefault(:sections)
         if Lorj::rhExist?(hMeta, section, key, :default) == 3
            default_key = Lorj::rhGet(hMeta, section, key, :default)
            PrcLib.debug("Lorj::Account.exist?: Reading default key '%s' instead of '%s'" % [default_key, key])
         else
            default_key = key
         end
         return nil if Lorj::rhExist?(hMeta, section, key, :account_exclusive) == 3

         @oConfig.exist?(default_key)

      end

      # Return true if readonly. set won't be able to update this value.
      # Only _set (private function) is able.
      #
      # * *Args*    :
      #   - +key+     : key name. It can support it to be a key tree (Arrays of keys).
      # * *Returns* :
      def readonly?(key)
         return nil if not key

         key = key.to_sym if key.class == String
         section = Lorj::Default.get_meta_section(key)

         Lorj::rhGet(@oConfig.getAppDefault(:sections, section), key, :readonly)

      end

      def meta_set(key, hMeta)
         key = key.to_sym if key.class == String
         section = Lorj::Default.get_meta_section(key)
         hCurMeta = Lorj::rhGet(@oConfig.getAppDefault(:sections, section), key)
         hMeta.each { | mykey, myvalue |
            Lorj::rhSet(hCurMeta, myvalue, mykey)
            }
      end

      def meta_exist?(key)
         return nil if not key

         key = key.to_sym if key.class == String
         section = Lorj::Default.get_meta_section(key)
         Lorj::rhExist?(@oConfig.getAppDefault(:sections, section), key) == 1
      end

      def get_meta_section(key)
         key = key.to_sym if key.class == String
         Lorj::rhGet(@account_section_mapping, key)
      end

      def meta_type?(key)
         return nil if not key

         section = Lorj::Default.get_meta_section(key)

         return section if section == :default
         @sAccountName
      end

      # Loop on account metadata
      def metadata_each
         Lorj::rhGet(Lorj::Default.dump(), :sections).each { | section, hValue |
            next if section == :default
            hValue.each { | key, value |
               yield section, key, value
               }
            }
      end

      # Return true if exclusive
      def exclusive?(key)
         return nil if not key

         key = key.to_sym if key.class == String
         section = Lorj::Default.get_meta_section(key)

         Lorj::rhGet(@oConfig.getAppDefault(:sections, section), key, :account_exclusive)
      end

      # This function update a section/key=value if the account structure is defined.
      # If no section is defined, set it in runtime config.
      def set(key, value)
         return nil if not key

         key = key.to_sym if key.class == String
         section = Lorj::Default.get_meta_section(key)

         return @oConfig.set(key, value) if not section
         return nil if readonly?(key)
         _set(section, key, value)
      end

      def []=(key, value)
         set(key, value)
      end

      def del(key)
         return nil if not key

         key = key.to_sym if key.class == String
         section = Lorj::Default.get_meta_section(key)
         return nil if not section
         Lorj::rhSet(@hAccountData, nil, section, key)
      end

      def getAccountData(section, key, default=nil)
         return Lorj::rhGet(@hAccountData, section, key) if Lorj::rhExist?(@hAccountData, section, key) == 2
         default
      end

      def ac_new(sAccountName)
         return nil if sAccountName.nil?
         @sAccountName = sAccountName
         @sAccountFile = File.join($FORJ_ACCOUNTS_PATH, @sAccountName)

         @hAccountData = {:account => {:name => sAccountName, :provider => @oConfig.get(:provider_name)}}
      end

      # Load Account Information
      def ac_load(sAccountName = @sAccountName)

         if sAccountName != @sAccountName
            ac_new(sAccountName)
         end

         if File.exists?(@sAccountFile)
            @hAccountData = @oConfig.extraLoad(@sAccountFile, :forj_accounts, @sAccountName)
            # Check if hAccountData are using symbol or needs to be updated.
            sProvider = @oConfig.get(:provider, 'hpcloud')
            Lorj::rhSet(@hAccountData, @sAccountName, :account, :name) if Lorj::rhExist?(@hAccountData, :account, :name) != 2
            Lorj::rhSet(@hAccountData, sProvider, :account, :provider) if Lorj::rhExist?(@hAccountData, :account, :provider) != 2

            if Lorj::rhKeyToSymbol?(@hAccountData, 2)
               @hAccountData = Lorj::rhKeyToSymbol(@hAccountData, 2)
               self.ac_save()
            end
            return @hAccountData
         end
         nil
      end

      def dump()
         { :forj_account => @hAccountData }
      end

      # Account save function.
      # Use set/get to manage those data that you will be able to save in an account file.
      def ac_save()
         @oConfig.extraSet(:forj_accounts, @sAccountName, nil, @hAccountData)
         @oConfig.extraSave(@sAccountFile, :forj_accounts, @sAccountName)

         if not @oConfig.localDefaultExist?('account_name')
            @oConfig.localSet('account_name',@sAccountName)
            @oConfig.saveConfig
         end
      end

      # private functions
      private
      def _set(section, key, value)
         return nil if not key or not section

         Lorj::rhSet(@hAccountData, value, section, key)
      end

   end
end
