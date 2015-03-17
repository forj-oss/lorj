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

# rubocop: disable Style/ClassAndModuleChildren

# Keypair management
class CloudProcess
  # KeyPair Create Process Handler
  # The process implemented is:
  # * Check local SSH keypairs
  # * Check remote keypair existence
  # * Compare and warn if needed.
  # * Import public key found if missing remotely and name it.
  #
  # Return:
  # - keypair : Lorj::Data keypair object. Following additional data should be
  #             found in the keypair attributes
  #   - :coherent        : Boolean. True, if the local keypair (public AND
  #                        private) is coherent with remote keypair found in
  #                        the cloud
  #   - :private_key_file: String. Path to local private key file
  #   - :public_key_file : String. Path to local public key file
  #   - :public_key      : String. Public key content. (config[:public_key] is
  #                        also set - Used to import it)
  #
  def forj_get_or_create_keypair(sCloudObj, hParams)
    keypair_name = hParams[:keypair_name]
    # setup has configured and copied the appropriate key to forj keypairs.

    loc_kpair = keypair_detect(keypair_name,
                               File.expand_path(hParams[:keypair_path]))

    private_key_file = File.join(loc_kpair[:keypair_path],
                                 loc_kpair[:private_key_name])
    public_key_file = File.join(loc_kpair[:keypair_path],
                                loc_kpair[:public_key_name])

    PrcLib.info("Found openssh private key file '%s'.",
                private_key_file) if loc_kpair[:private_key_exist?]
    PrcLib.info("Found openssh public key file '%s'.",
                public_key_file) if loc_kpair[:public_key_exist?]

    PrcLib.state("Searching for keypair '%s'", keypair_name)

    keypairs = forj_query_keypair(sCloudObj,
                                  { :name => keypair_name }, hParams)

    if keypairs.length == 0
      keypair = keypair_import(hParams, loc_kpair)
    else
      keypair = keypairs[0]
      keypair[:coherent] = coherent_keypair?(loc_kpair, keypair)
      # Adding information about key files.
    end
    if keypair[:coherent]
      keypair[:private_key_name] = loc_kpair[:private_key_name]
      keypair[:public_key_name] = loc_kpair[:public_key_name]
      keypair[:keypair_path] = loc_kpair[:keypair_path]
    end
    keypair
  end

  def forj_query_keypair(sCloudObj, sQuery, hParams)
    key_name = hParams[:keypair_name]
    ssl_error_obj = SSLErrorMgt.new
    begin
      #  list = controller_query(sCloudObj, sQuery)
      #  query_single(sCloudObj, list, sQuery, key_name)
      query_single(sCloudObj, sQuery, key_name)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end
end

# Keypair management: Internal process functions
class CloudProcess
  def keypair_import(hParams, loc_kpair)
    PrcLib.fatal(1, "Unable to import keypair '%s'. "\
                    'Public key file is not found. '\
                    "Please run 'forj setup %s'",
                 hParams[:keypair_name],
                 config[:account_name]) unless loc_kpair[:public_key_exist?]
    public_key_file = File.join(loc_kpair[:keypair_path],
                                loc_kpair[:public_key_name])

    begin
      config[:public_key] = File.read(public_key_file)
    rescue => e
      PrcLib.fatal(1, "Unable to import keypair '%s'. '%s' is "\
                      "unreadable.\n%s", hParams[:keypair_name],
                   loc_kpair[:public_key_file],
                   e.message)
    end
    keypair = create_keypair(:keypairs, hParams)

    return nil if keypair.nil?

    if !loc_kpair[:private_key_exist?]
      keypair[:coherent] = false
    else
      keypair[:coherent] = true
    end
    keypair
  end

  def create_keypair(sCloudObj, hParams)
    key_name = hParams[:keypair_name]
    PrcLib.state("Importing keypair '%s'", key_name)
    ssl_error_obj = SSLErrorMgt.new
    begin
      keypair = controller_create(sCloudObj)
      PrcLib.info("Keypair '%s' imported.", keypair[:name])
    rescue StandardError => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
      PrcLib.error "error importing keypair '%s'", key_name
    end
    keypair
  end

  # Build keypair data information structure with files found in
  # local filesystem. Take care of priv with or without .pem
  # and pubkey with pub.
  def keypair_detect(keypair_name, key_fullpath)
    key_basename = File.basename(key_fullpath)
    key_path = File.expand_path(File.dirname(key_fullpath))

    obj_match = key_basename.match(/^(.*?)(\.pem|\.pub)?$/)
    key_basename = obj_match[1]

    private_key_ext, files = _check_key_file(key_path, key_basename,
                                             ['', '.pem'])

    if private_key_ext
      priv_key_exist = true
      priv_key_name = key_basename + private_key_ext
    else
      files.each do |temp_file|
        PrcLib.warning('keypair_detect: Private key file name detection has '\
                       "detected '%s' as a directory. Usually, it should be a "\
                       'private key file. Please check.',
                       temp_file) if File.directory?(temp_file)
      end
      priv_key_exist = false
      priv_key_name = key_basename
    end

    pub_key_exist = File.exist?(File.join(key_path, key_basename + '.pub'))
    pub_key_name = key_basename + '.pub'

    # keypair basic structure
    { :keypair_name     => keypair_name,
      :keypair_path     => key_path,      :key_basename       => key_basename,
      :private_key_name => priv_key_name, :private_key_exist? => priv_key_exist,
      :public_key_name  => pub_key_name,  :public_key_exist?  => pub_key_exist
    }
  end

  def _check_key_file(key_path, key_basename, extensions)
    found_ext = nil
    files = []
    extensions.each do |ext|
      temp_file = File.join(key_path, key_basename + ext)
      if File.exist?(temp_file) && !File.directory?(temp_file)
        found_ext = ext
        files << temp_file
      end
    end
    [found_ext, files]
  end

  def forj_get_keypair(sCloudObj, sName, _hParams)
    ssl_error_obj = SSLErrorMgt.new
    begin
      controller_get(sCloudObj, sName)
    rescue => e
      retry unless ssl_error_obj.error_detected(e.message, e.backtrace, e)
    end
  end

  def get_keypairs_path(hParams, hKeys)
    keypair_name = hParams[:keypair_name]

    if hKeys[:private_key_exist?]
      hParams[:private_key_file] = File.join(hKeys[:keypair_path],
                                             hKeys[:private_key_name])
      PrcLib.info("Openssh private key file '%s' exists.",
                  hParams[:private_key_file])
    end
    if hKeys[:public_key_exist?]
      hParams[:public_key_file] = File.join(hKeys[:keypair_path],
                                            hKeys[:public_key_name])
    else
      PrcLib.fatal(1, 'Public key file is not found. Please run'\
                      " 'forj setup %s'", config[:account_name])
    end

    PrcLib.state("Searching for keypair '%s'", keypair_name)

    hParams
  end

  # Check if 2 keypair objects are coherent (Same public key)
  # Parameters:
  # - +loc_kpair+ : Keypair structure representing local files existence.
  #                     see keypair_detect
  # - +keypair+       : Keypair object to check.
  #
  # return:
  # - coherent : Boolean. True if same public key.
  def coherent_keypair?(loc_kpair, keypair)
    # send keypairs by parameter

    keypair_name = loc_kpair[:keypair_name]
    is_coherent = false

    pub_keypair = keypair[:public_key]

    # Check the public key with the one found here, locally.
    if !pub_keypair.nil? && pub_keypair != ''
      begin
        loc_pubkey = File.read(File.join(loc_kpair[:keypair_path],
                                         loc_kpair[:public_key_name]))
     rescue => e
       PrcLib.error("Unable to read '%s'.\n%s",
                    loc_kpair[:public_key_file], e.message)
      else
        if loc_pubkey.split(' ')[1].strip == pub_keypair.split(' ')[1].strip
          PrcLib.info("keypair '%s' local files are coherent with keypair in "\
                      'your cloud service. You will be able to connect to '\
                      'your box over SSH.', keypair_name)
          is_coherent = true
        else
          PrcLib.warning("Your local keypair file '%s' are incoherent with "\
                         "public key '%s' found in your cloud. You won't be "\
                         "able to access your box with this keypair.\nPublic "\
                         "key found in the cloud:\n%s",
                         loc_kpair[:public_key_file], keypair_name,
                         keypair[:public_key])
        end
      end
    else
      PrcLib.warning('Unable to verify keypair coherence with your local '\
                     'SSH keys. No public key (:public_key) provided.')
    end
    is_coherent
  end
end

# ************************************ keypairs Object
# Identify keypairs
class Lorj::BaseDefinition
  define_obj(:keypairs,

             :create_e => :forj_get_or_create_keypair,
             :query_e => :forj_query_keypair,
             :get_e => :forj_get_keypair
             #         :delete_e   => :forj_delete_keypair
             )

  obj_needs :CloudObject,  :compute_connection
  obj_needs :data,         :keypair_name,        :for => [:create_e]
  obj_needs :data,         :keypair_path,        :for => [:create_e]

  obj_needs_optional
  obj_needs :data,         :public_key,          :for => [:create_e]

  def_attribute :public_key
end
