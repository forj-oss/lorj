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

class SSLErrorMgt
  def initialize(iMaxRetry = 5)
    @iRetry = 0
    @iMaxRetry = iMaxRetry
  end

  def ErrorDetected(message, backtrace, e)
    if message.match('SSLv2/v3 read server hello A: unknown protocol')
      if @iRetry < @iMaxRetry
        sleep(2)
        @iRetry += 1
        print "%s/%s try... 'unknown protocol' SSL Error\r" % [@iRetry, @iMaxRetry] if PrcLib.level == 0
        return false
      else
        PrcLib.error('Too many retry. %s' % message)
        return true
      end
    elsif e.is_a?(Excon::Errors::InternalServerError)
      if @iRetry < @iMaxRetry
        sleep(2)
        @iRetry += 1
        print "%s/%s try... %s\n" % [@iRetry, @iMaxRetry, ANSI.red(e.class)] if PrcLib.level == 0
        return false
      else
        PrcLib.error('Too many retry. %s' % message)
        return true
      end
    else
      PrcLib.error("Exception %s: %s\n%s" % [e.class, message, backtrace.join("\n")])
      return true
    end
  end
end

class CloudProcess
  def connect(sCloudObj, hParams)
    oSSLError = SSLErrorMgt.new # Retry object
    PrcLib.debug("%s:%s Connecting to '%s' - Project '%s'" % [self.class, sCloudObj, config.get(:provider), hParams[:tenant]])
    begin
      controller_connect(sCloudObj)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
     PrcLib.error('%s:%s: Unable to connect.\n%s' % [self.class, sCloudObj, e.message])
     nil
    end
  end
end

# ---------------------------------------------------------------------------
# Keypair management
# ---------------------------------------------------------------------------
class CloudProcess
  # KeyPair Create Process Handler
  # The process implemented is:
  # * Check local SSH keypairs
  # * Check remote keypair existence
  # * Compare and warn if needed.
  # * Import public key found if missing remotely and name it.
  #
  # Return:
  # - keypair : Lorj::Data keypair object. Following additional data should be found in the keypair attributes
  #   - :coherent        : Boolean. True, if the local keypair (public AND private) is coherent with remote keypair found in the cloud
  #   - :private_key_file: String. Path to local private key file
  #   - :public_key_file : String. Path to local public key file
  #   - :public_key      : String. Public key content. (config[:public_key] is also set - Used to import it)
  #
  def forj_get_or_create_keypair(sCloudObj, hParams)
    sKeypair_name = hParams[:keypair_name]
    # setup has configured and copied the appropriate key to forj keypairs.

    hLocalKeypair = keypair_detect(sKeypair_name, File.expand_path(hParams[:keypair_path]))

    private_key_file = File.join(hLocalKeypair[:keypair_path], hLocalKeypair[:private_key_name])
    public_key_file = File.join(hLocalKeypair[:keypair_path], hLocalKeypair[:private_key_name])

    PrcLib.info("Found openssh private key file '%s'." % private_key_file) if hLocalKeypair[:private_key_exist?]
    PrcLib.info("Found openssh public key file '%s'."  % public_key_file)  if hLocalKeypair[:public_key_exist?]

    PrcLib.state("Searching for keypair '%s'" % [sKeypair_name])

    keypairs = forj_query_keypair(sCloudObj, { name: sKeypair_name }, hParams)

    if keypairs.length == 0
      PrcLib.fatal(1, "Unable to import keypair '%s'. Public key file is not found. Please run 'forj setup %s'" % [sKeypair_name, config[:account_name]]) unless hLocalKeypair[:public_key_exist?]
      begin
        config[:public_key] = File.read(hLocalKeypair[:public_key_file])
     rescue => e
       PrcLib.error("Unable to import keypair '%s'. '%s' is unreadable.\n%s", [hLocalKeypair[:public_key_file], e.message])
      end
      keypair = create_keypair(sCloudObj, hParams)
      if !hLocalKeypair[:private_key_exist?]
        keypair[:coherent] = false
      else
        keypair[:coherent] = true
      end
    else
      keypair = keypairs[0]
      keypair[:coherent] = coherent_keypair?(hLocalKeypair, keypair)
      # Adding information about key files.
    end
    if keypair[:coherent]
      keypair[:private_key_file] = hLocalKeypair[:private_key_file]
      keypair[:public_key_file] = hLocalKeypair[:public_key_file]
    end
    keypair
  end

  def forj_query_keypair(sCloudObj, sQuery, hParams)
    key_name = hParams[:keypair_name]
    oSSLError = SSLErrorMgt.new
    begin
      oList = controller_query(sCloudObj, sQuery)
      query_single(sCloudObj, oList, sQuery, key_name)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
  end

  # Internal process function: Create keypair
  def create_keypair(sCloudObj, hParams)
    key_name = hParams[:keypair_name]
    PrcLib.state("Importing keypair '%s'" % [key_name])
    oSSLError = SSLErrorMgt.new
    begin
      keypair = controller_create(sCloudObj)
      PrcLib.info("Keypair '%s' imported." % [keypair[:name]])
   rescue StandardError => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
     PrcLib.error "error importing keypair '%s'" % [key_name]
    end
    keypair
  end

  # Build keypair data information structure with files found in local filesystem.
  # Take care of priv with or without .pem and pubkey with pub.
  def keypair_detect(keypair_name, key_fullpath)
    key_basename = File.basename(key_fullpath)
    key_path = File.expand_path(File.dirname(key_fullpath))

    mObj = key_basename.match(/^(.*?)(\.pem|\.pub)?$/)
    key_basename = mObj[1]

    private_key_ext = nil
    temp_file1 = File.join(key_path, key_basename)
    private_key_ext = '' if File.exist?(temp_file1) && !File.directory?(temp_file1)
    temp_file2 = File.join(key_path, key_basename + '.pem')
    private_key_ext = '.pem' if File.exist?(temp_file2) && !File.directory?(temp_file2)

    if private_key_ext
      private_key_exist = true
      private_key_name = key_basename + private_key_ext
    else
      [temp_file1, temp_file2].each do | temp_file |
        PrcLib.warning("keypair_detect: Private key file name detection has detected '%s' as a directory. Usually, it should be a private key file. Please check." % temp_file) if File.directory?(temp_file)
      end
      private_key_exist = false
      private_key_name = key_basename
    end

    public_key_exist = File.exist?(File.join(key_path, key_basename + '.pub'))
    public_key_name = key_basename + '.pub'

    # keypair basic structure
    { :keypair_name     => keypair_name,
      :keypair_path     => key_path,         :key_basename       => key_basename,
      :private_key_name => private_key_name, :private_key_exist? => private_key_exist,
      :public_key_name  => public_key_name,  :public_key_exist?  => public_key_exist
    }
  end

  def forj_get_keypair(sCloudObj, sName, _hParams)
    oSSLError = SSLErrorMgt.new
    begin
      controller_get(sCloudObj, sName)
    rescue => e
      unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
        retry
      end
    end
  end

  def get_keypairs_path(hParams, hKeys)
    sKeypair_name = hParams[:keypair_name]

    if hKeys[:private_key_exist?]
      hParams[:private_key_file] = File.join(hKeys[:keypair_path], hKeys[:private_key_name])
      PrcLib.info("Openssh private key file '%s' exists." % hParams[:private_key_file])
    end
    if hKeys[:public_key_exist?]
      hParams[:public_key_file] = File.join(hKeys[:keypair_path], hKeys[:public_key_name])
    else
      PrcLib.fatal(1, "Public key file is not found. Please run 'forj setup %s'" % config[:account_name])
    end

    PrcLib.state("Searching for keypair '%s'" % [sKeypair_name])

    hParams
  end

  # Check if 2 keypair objects are coherent (Same public key)
  # Parameters:
  # - +hLocalKeypair+ : Keypair structure representing local files existence. see keypair_detect
  # - +keypair+       : Keypair object to check.
  #
  # return:
  # - coherent : Boolean. True if same public key.
  def coherent_keypair?(hLocalKeypair, keypair)
    # send keypairs by parameter

    sKeypair_name = hLocalKeypair[:keypair_name]
    bCoherent = false

    # Check the public key with the one found here, locally.
    if !keypair[:public_key].nil? && keypair[:public_key] != ''
      begin
        local_pub_key = File.read(File.join(hLocalKeypair[:keypair_path], hLocalKeypair[:public_key_name]))
     rescue => e
       PrcLib.error("Unable to read '%s'.\n%s" % [hLocalKeypair[:public_key_file], e.message])
      else
        if local_pub_key.split(' ')[1].strip == keypair[:public_key].split(' ')[1].strip
          PrcLib.info("keypair '%s' local files are coherent with keypair in your cloud service. You will be able to connect to your box over SSH." % sKeypair_name)
          bCoherent = true
        else
          PrcLib.warning("Your local keypair file '%s' are incoherent with public key '%s' found in your cloud. You won't be able to access your box with this keypair.\nPublic key found in the cloud:\n%s" % [hLocalKeypair[:public_key_file], sKeypair_name, keypair[:public_key]])
        end
      end
    else
      PrcLib.warning('Unable to verify keypair coherence with your local SSH keys. No public key (:public_key) provided.')
    end
    bCoherent
  end
end

# ---------------------------------------------------------------------------
# flavor management
# ---------------------------------------------------------------------------
class CloudProcess
  # Depending on clouds/rights, we can create flavor or not.
  # Usually, flavor records already exists, and the controller may map them
  # CloudProcess predefines some values. Consult CloudProcess.rb for details
  def forj_get_or_create_flavor(sCloudObj, hParams)
    sFlavor_name = hParams[:flavor_name]
    PrcLib.state("Searching for flavor '%s'" % [sFlavor_name])

    flavors = query_flavor(sCloudObj, { name: sFlavor_name }, hParams)
    if flavors.length == 0
      if !hParams[:create]
        PrcLib.error("Unable to create %s '%s'. Creation is not supported." % [sCloudObj, sFlavor_name])
        ForjLib::Data.new.set(nil, sCloudObj)
      else
        create_flavor(sCloudObj, hParams)
      end
    else
      flavors[0]
    end
  end

  # Should return 1 or 0 flavor.
  def query_flavor(sCloudObj, sQuery, hParams)
    sFlavor_name = hParams[:flavor_name]
    oList = forj_query_flavor(sCloudObj, sQuery, hParams)
    query_single(sCloudObj, oList, sQuery, sFlavor_name)
  end

  # Should return 1 or 0 flavor.
  def forj_query_flavor(sCloudObj, sQuery, hParams)
    sFlavor_name = hParams[:flavor_name]
    oSSLError = SSLErrorMgt.new
    begin
      oList = controller_query(sCloudObj, sQuery)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
    oList
  end
end

# ---------------------------------------------------------------------------
# Image management
# ---------------------------------------------------------------------------
class CloudProcess
  def forj_get_or_create_image(sCloudObj, hParams)
    sImage_name = hParams[:image_name]
    PrcLib.state("Searching for image '%s'" % [sImage_name])

    search_the_image(sCloudObj, { name: sImage_name }, hParams)
    # No creation possible.
  end

  def search_the_image(sCloudObj, sQuery, hParams)
    image_name = hParams[:image_name]
    images = forj_query_image(sCloudObj, sQuery, hParams)
    case images.length
      when 0
        PrcLib.info("No image '%s' found" % [image_name])
        nil
      when 1
        PrcLib.info("Found image '%s'." % [image_name])
        images[0, :ssh_user] = ssh_user(images[0, :name])
        images[0]
      else
        PrcLib.info("Found several images '%s'. Selecting the first one '%s'" % [image_name, images[0, :name]])
        images[0, :ssh_user] = ssh_user(images[0, :name])
        images[0]
    end
  end

  def forj_query_image(sCloudObj, sQuery, _hParams)
    oSSLError = SSLErrorMgt.new
    begin
      images = controller_query(sCloudObj, sQuery)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
    images.each do |image|
      image[:ssh_user] = ssh_user(image[:name])
    end
    images
  end

  def ssh_user(image_name)
    return 'fedora' if image_name =~ /fedora/i
    return 'centos' if image_name =~ /centos/i
    'ubuntu'
  end
end

# ---------------------------------------------------------------------------
# Server management
# ---------------------------------------------------------------------------
class CloudProcess
  # Process Handler functions
  def forj_get_or_create_server(sCloudObj, hParams)
    sServer_name = hParams[:server_name]
    PrcLib.state("Searching for server '%s'" % [sServer_name])
    servers = forj_query_server(sCloudObj, { name: sServer_name }, hParams)
    if servers.length > 0
      # Get server details
      forj_get_server(sCloudObj, servers[0][:attrs][:id], hParams)
    else
      create_server(sCloudObj, hParams)
    end
  end

  def forj_delete_server(sCloudObj, hParams)
    oSSLError = SSLErrorMgt.new
    begin
      controller_delete(sCloudObj)
      PrcLib.info('Server %s was destroyed ' % hParams[:server][:name])
    rescue => e
      unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
        retry
      end
    end
  end

  def forj_query_server(sCloudObj, sQuery, _hParams)
    oSSLError = SSLErrorMgt.new
    begin
      controller_query(sCloudObj, sQuery)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
  end

  def forj_get_server(sCloudObj, sId, _hParams)
    oSSLError = SSLErrorMgt.new
    begin
      controller_get(sCloudObj, sId)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
  end

  # Internal Process function
  def create_server(sCloudObj, hParams)
    name = hParams[:server_name]
    begin
      PrcLib.info('boot: meta-data provided.') if hParams[:meta_data]
      PrcLib.info('boot: user-data provided.') if hParams[:user_data]
      PrcLib.state('creating server %s' % [name])
      server = controller_create(sCloudObj)
      PrcLib.info("%s '%s' created." % [sCloudObj, name])
   rescue => e
     PrcLib.fatal(1, "Unable to create server '%s'" % name, e)
    end
    server
  end

  def forj_get_server_log(sCloudObj, sId, _hParams)
    oSSLError = SSLErrorMgt.new
    begin
      controller_get(sCloudObj, sId)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
  end
end
# ---------------------------------------------------------------------------
# Addresses management
# ---------------------------------------------------------------------------
class CloudProcess
  # Process Handler functions
  def forj_get_or_assign_public_address(sCloudObj, hParams)
    # Function which to assign a public IP address to a server.
    sServer_name = hParams[:server, :name]

    PrcLib.state("Searching public IP for server '%s'" % [sServer_name])
    addresses = controller_query(sCloudObj, server_id: hParams[:server, :id])
    if addresses.length == 0
      assign_address(sCloudObj, hParams)
    else
      addresses[0]
    end
  end

  def forj_query_public_address(sCloudObj, sQuery, hParams)
    server_name = hParams[:server, :name]
    oSSLError = SSLErrorMgt.new
    begin
      sInfo = {
        notfound: "No %s for '%s' found",
        checkmatch: "Found 1 %s. checking exact match for server '%s'.",
        nomatch: "No %s for '%s' match",
        found: "Found %s '%s' for #{server_name}.",
        more: "Found several %s. Searching for '%s'.",
        items: :public_ip
      }
      oList = controller_query(sCloudObj, sQuery)
      query_single(sCloudObj, oList, sQuery, server_name, sInfo)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
  end

  def forj_get_public_address(sCloudObj, sId, _hParams)
    oSSLError = SSLErrorMgt.new
    begin
      controller_get(sCloudObj, sId)
   rescue => e
     unless oSSLError.ErrorDetected(e.message, e.backtrace, e)
       retry
     end
    end
  end

  # Internal Process function
  def assign_address(sCloudObj, hParams)
    name = hParams[:server, :name]
    begin
      PrcLib.state('Getting public IP for server %s' % [name])
      ip_address = controller_create(sCloudObj)
      PrcLib.info("Public IP '%s' for server '%s' assigned." % [ip_address[:public_ip], name])
   rescue => e
     PrcLib.fatal(1, "Unable to assign a public IP to server '%s'" % name, e)
    end
    ip_address
  end
end
