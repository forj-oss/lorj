#!/usr/bin/env ruby

# require 'byebug'

app_path = File.dirname(__FILE__)
lib_path = File.expand_path(File.join(File.dirname(app_path), 'lib'))

load_path << lib_path

require 'lorj.rb'

# Load global Config
oconfig = ForjConfig.new

processes = []

# Defines how to manage Maestro and forges
# create a maestro box. Identify a forge instance, delete it,...
processes << File.join(lib_path, 'forj', 'ForjCore.rb')

# Defines how cli will control FORJ features
# boot/down/ssh/...
processes << File.join(lib_path, 'forj', 'ForjCli.rb')

ocloud = ForjCloud.new(oconfig, 'hpcloud', processes)

oconfig.set(:box_name, '183')
oconfig.set(:box, 'maestro')
ocloud.Create(:ssh)
