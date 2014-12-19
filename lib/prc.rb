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
#    limitations under the License.module Lorj

require 'fileutils'
require 'logger'

# General lorj library. Used as library data configuration
# List of possible library settings:
# PrcLib.log          : PrcLib::Logging object. Used internally by PrcLib
#                       logging system.
#                       This object is automatically created as soon as
#                       a message is printed out
# PrcLib.core_level   : lorj debug level. from 0 to 5.
# PrcLib.data_path    : Define the data local directory.
#                       By default: ~/.<app_name>
# PrcLib.app_name     : Define the application name. By default 'lorj'
# PrcLib.app_defaults : Used by Lorj::Config to load application default data.
#                       By default nil.
# PrcLib.log_file     : Define the log file name used.
#                       By default, defined as ~/.<app_name>/<app_name>.log
# PrcLib.level        : logger level used.
#                       Can be set at runtime, with PrcLib.set_level
module PrcLib

  # Check if dir exists and is fully accessible (rwx)
  def self.dir_exists?(path)
    if File.exist?(path)
      unless File.directory?(path)
        msg = "'%s' is not a directory. Please fix it." % path
        unless log_object.nil?
          log_object.fatal(1, msg)
        else
          fail msg
        end
      end
      if !File.readable?(path) || !File.writable?(path) || !File.executable?(path)
        msg = '%s is not a valid directory. Check permissions and fix it.' % path
        unless log_object.nil?
          log_object.fatal(1, msg)
        else
          fail msg
        end
      end
      return true
    end
    false
  end

  # ensure dir exists and is fully accessible (rwx)
  def self.ensure_dir_exists(path)
    unless dir_exists?(path)
      FileUtils.mkpath(path) unless File.directory?(path)
    end
  end

  # Define module data for lorj library configuration
  class << self
    attr_accessor :log, :core_level
    attr_reader :data_path, :app_name, :app_defaults, :log_file, :level
  end

  module_function

  def data_path=(v)
    @data_path = File.expand_path(v) unless @data_path
    PrcLib.ensure_dir_exists(@data_path)
  end


  def app_name=(v)
    @app_name = v unless @app_name
  end

  # TODO: Support for several defaults, depending on controllers loaded.
  def app_defaults=(v)
    return if @app_defaults
    unless v[0] == '/'
       v = File.join(File.dirname(__FILE__), v)
    end
    @app_defaults = File.expand_path(v)
  end

  def log_file=(v)
    sFile = File.basename(v)
    sDir = File.dirname(File.expand_path(v))
    unless File.exist?(sDir)
      fail "'%s' doesn't exist. Unable to create file '%s'" % [sDir, sFile]
    end
    @log_file = File.join(sDir, sFile)
  end

  def level=(v)
    @level = v
    unless PrcLib.log.nil?
      PrcLib.set_level(v)
    end
  end

  def lib_path=(v)
    @lib_path = v if @lib_path.nil?
  end

  attr_reader :lib_path

  def controller_path
    File.expand_path(File.join(@lib_path,  'providers'))
  end

  def process_path
    File.join(@lib_path, 'core_process')
  end
end

class Object
  # Simplify boolean test on objects
  def boolean?
    self.is_a?(TrueClass) || self.is_a?(FalseClass)
  end
end
