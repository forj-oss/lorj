#!/usr/bin/env ruby
# encoding: UTF-8

#--
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
#++

require 'lorj/version'

# This is the lorj base library.

# To use it, add require 'lorj'

require 'prc.rb'           # Load PrcLib Base module
require 'prc-logging.rb'   # Load class PrcLib::Logging
require 'prc-config.rb'    # Load class Lorj::Config
require 'prc-account.rb'   # Load class Lorj::Account

require 'core/core'                 # Lorj Core classes
require 'core/lorj-data'            # Lorj Lorj::Data object
require 'core/lorj-basedefinition'  # Lorj Lorj::BaseDefinition object
require 'core/lorj-baseprocess'     # Lorj Lorj::BaseProcess object
require 'core/lorj-basecontroller'  # Lorj Lorj::BaseController object
require 'core/lorj-keypath'         # Lorj Lorj::BaseDefinition object
require 'core/definition'           # Lorj Process definition
require 'core/definition_internal'  # Lorj internal functions

module Lorj
  slib_forj = File.dirname(__FILE__)

  PrcLib.lib_path = File.expand_path(File.join(File.dirname(slib_forj), 'lib'))

  PrcLib.core_level = 0
end
