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
require 'lorj/compat' # Code introduced to support Ruby 1.8

# This is the lorj base library.

# To use it, add require 'lorj'

require 'config_layers'            # ConfigLayers

require 'prc.rb'                   # PrcLib Base module
require 'logging.rb'               # class PrcLib::Logging
require 'lorj_meta.rb'             # PRC::Meta class - Application defaults
require 'lorj_defaults.rb'         # PRC::Defaults class - Application defaults
require 'lorj_config.rb'           # Lorj::Config class -
require 'lorj_account.rb'          # Lorj::Account class  - account config

require 'core/core_internal'       # Lorj Core class private init. functions
require 'core/core'                # Lorj Core class
require 'core/core_object_params'  # Lorj Internal core class
require 'core/core_model'          # Lorj Model class
require 'core/core_process'        # Lorj core process functions
require 'core/core_process_setup'  # Lorj core process setup
require 'core/core_setup_ask'      # Lorj core setup ask functions
require 'core/core_setup_encrypt'  # Lorj core setup encrypt functions
require 'core/core_setup_init'     # Lorj core setup init functions
require 'core/core_setup_list'     # Lorj core setup list functions
require 'core/core_controller'     # Lorj core controller functions

require 'core/core_object_data'    # Lorj ObjectData class
require 'core/lorj_data'           # Lorj Lorj::Data object
require 'core/lorj_basedefinition' # Lorj Lorj::BaseDefinition object
require 'core/lorj_baseprocess'    # Lorj Lorj::BaseProcess object
require 'core/lorj_basecontroller' # Lorj Lorj::BaseController object
require 'core/lorj_keypath'        # Lorj Lorj::BaseDefinition object
require 'core/definition'          # Lorj Process definition
require 'core/definition_internal' # Lorj internal functions
require 'core/process'             # Lorj Process Module feature

# lorj module
module Lorj
  # Internal Lorj function to debug lorj.
  #
  # * *Args* :
  #   - +iLevel+ : value between 1 to 5. Setting 5 is the most verbose!
  #   - +sMsg+   : Array of string or symbols. keys tree to follow and check
  #                existence in yVal.
  #
  # * *Returns* :
  #   - nothing
  #
  # * *Raises* :
  #   No exceptions
  def self::debug(iLevel, sMsg, *p)
    if iLevel <= PrcLib.core_level
      message = format('-%s- %s', iLevel, sMsg)

      PrcLib.debug(message, *p)
    end
  end

  # Internal PrcError class object derived from RuntimeError.
  # Internally used with raise.
  # Used to identify the error origin, while an error is thrown.
  class PrcError < RuntimeError
    attr_reader :lorg_message

    def initialize(message = nil)
      @lorj_message = message
    end
  end

  slib_forj = File.dirname(__FILE__)

  PrcLib.lib_path = File.expand_path(File.join(File.dirname(slib_forj), 'lib'))

  PrcLib.core_level = 0
end
