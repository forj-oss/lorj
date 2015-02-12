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

#
# PrcLib module
#
# This module helps to configure the lorj library.
# It implements also a Logging class based on logger.
#
# For details about this class capabilities, see PrcLib::Logging
#
# List of possible library settings:
# - PrcLib.log
#
#   Set a logger object.
#   By default, Lorj creates a Lorj::Logging object which enhance a double
#   logging system (output and file at the same time)
#
#   You can set your own logger system.
#   This logger instance requires to have following features:
#   * functions : unknown/warn/fatal/error/debug/info(message)
#   * Is level functions: info?/debug?/warn?/error?/fatal?
#     NOTE: Those functions are currently not used but may be used in the future
#   * attribute : level
#
#   This object is automatically created as soon as a message is printed out
# - PrcLib.core_level
#
#   Initialize lorj debug level. from 0 to 5.
#
#   ex:
#
#    PrcLib.core_level = 4
# - PrcLib.pdata_path
#
#   Define the private data local directory. Usually used
#   for any private keys, passwords, etc...
#
#   By default: ~/.config/<app_name>
#
#   ex:
#
#    PrcLib.pdata_path = File.join('~', '.private_myapp')
# - PrcLib.data_path
#
#   Define the data local directory.
#   This setting influences default settings for:
#   PrcLib.log_file
#
#   By default: ~/.<app_name>
#
#   ex:
#
#    PrcLib.data_path = File.join('/etc', 'myapp')
#
# - PrcLib.app_name
#
#   Define the application name. By default 'lorj'.
#   This setting influences default settings for:
#   PrcLib.data_path, PrcLib.pdata_path and PrcLib.log_file
#
#   ex:
#
#    PrcLib.app_name = 'myapp'
# - PrcLib.app_defaults
#
#   Used by Lorj::Config to identify application defaults and your application
#   data model data.
#
#   By default nil.
#   Ex:
#
#    puts PrcLib.app_defaults[:data] # To get value of the predefined :data key.
#
# - PrcLib.level
#   logger level used. It can be updated at runtime.
#
#   Ex:
#
#    PrcLib.level = Logger::FATAL
#
# - PrcLib.model
#
#   Model loaded.
#
# - PrcLib.log_file
#
#   Initialize a log file name (relative or absolute path) instead of default
#   one.
#   By default, defined as #{data_path}/#{app_name}.log
#
#
#   Ex:
#
#    PrcLib.log_file = "mylog.file.log" # Relative path to the file
#
# - PrcLib.controller_path
#
#   Provides the default controller path.
#
# - PrcLib.process_path
#
#   Provides the default process path.
#
module PrcLib
  # Check if dir exists and is fully accessible (rwx)
  def self.dir_exists?(path)
    return false unless File.exist?(path)

    unless File.directory?(path)
      msg = format("'%s' is not a directory. Please fix it.", path)

      fatal_error(1, msg)
    end
    unless File.readable?(path) &&
           File.writable?(path) &&
           File.executable?(path)
      msg = format("'%s is not a valid directory. "\
                   'Check permissions and fix it.',  path)

      fatal_error(1, msg)
    end
    true
  end

  def self.fatal_error(rc, msg)
    fail msg if log.nil?
    log.fatal(rc, msg)
  end

  # ensure dir exists and is fully accessible (rwx)
  def self.ensure_dir_exists(path)
    FileUtils.mkpath(path) unless dir_exists?(path)
  rescue => e
    fatal_error(1, e.message)
  end

  # Define module data for lorj library configuration
  class << self
    attr_accessor :log, :core_level
    attr_reader :app_defaults,  :level, :lib_path
  end

  module_function

  # Attribute app_name
  #
  # app_name is set to 'lorj' if not set.
  #
  def app_name
    self.app_name = 'lorj' unless @app_name
    @app_name
  end

  # Attribute app_name setting
  #
  # You can set the application name only one time
  #
  def app_name=(v)
    @app_name = v unless @app_name
  end

  # Attribute pdata_path
  #
  # Path to a private data, like encrypted keys.
  #
  # It uses pdata_path= to set the default path if not set
  # ~/.config/#{app_name}
  def pdata_path
    return @pdata_path unless @pdata_path.nil?
    self.pdata_path = File.join('~', '.config', app_name)
    @pdata_path
  end

  # Attribute pdata_path setting
  #
  # If path doesn't exist, it will be created with 700 rights (Unix).
  #
  def pdata_path=(v)
    @pdata_path = File.expand_path(v) unless @pdata_path
    begin
      ensure_dir_exists(@pdata_path)
      FileUtils.chmod(0700, @pdata_path) # no-op on windows
    rescue => e
      fatal_error(1, e.message)
    end
  end

  # Attribute data_path
  #
  # Path to the application data.
  #
  # It uses data_path= to set the default path if not set
  # ~/.#{app_name}
  def data_path
    return @data_path unless @data_path.nil?

    self.data_path = File.join('~', '.' + app_name)
    @data_path
  end

  # Attribute data_path setting
  #
  # If path doesn't exist, it will be created.
  #
  def data_path=(v)
    @data_path = File.expand_path(v) unless @data_path
    begin
      ensure_dir_exists(@data_path)
    rescue => e
      fatal_error(1, e.message)
    end
  end

  # TODO: Low. Be able to support multiple model.

  # Lorj::Model object access.
  # If the object doesn't exist, it will be created
  def model
    @model = Lorj::Model.new if @model.nil?
    @model
  end

  # TODO: Support for several defaults, depending on controllers loaded.

  # Attribute app_defaults
  #
  # Used to define where the application defaults.yaml is located.
  #
  def app_defaults=(v)
    return if @app_defaults

    v = File.join(File.dirname(__FILE__), v) unless v.include?('/')

    @app_defaults = File.expand_path(v)
  end

  # log_file module attribute
  #
  # by default, log_file is nil.
  # The user can define a log_file name or path
  # The path is created (if possible) as soon a
  # log_file is set.
  # The file name is created by the logging class.
  #
  # *args*
  # - +log file+ : absolute or relative path to a log file.
  #
  def log_file
    return @log_file unless @log_file.nil?

    self.log_file = File.join(data_path, app_name + '.log')
    @log_file
  end

  # Attribute log_file setting
  #
  # It ensures that the path to the log file is created.
  #
  def log_file=(v)
    file = File.basename(v)
    dir = File.dirname(File.expand_path(v))
    ensure_dir_exists(dir)

    @log_file = File.join(dir, file)
  end

  # Attribute level setting
  #
  # Set the new output logging level
  #
  def level=(v)
    @level = v

    log.level = v unless log.nil?
  end

  # Attribute lib_path setting
  #
  # initialize the Lorj library path
  # Used by Lorj module declaration
  # See lib/lorj.rb
  #
  # This setting cannot be updated later.
  #
  def lib_path=(v)
    @lib_path = v if @lib_path.nil?
  end

  # TODO: Support for updating the default controller path
  # OR:
  # TODO: Support for path search of controllers.

  # Read Attribute setting for default library controller path
  def controller_path
    File.expand_path(File.join(@lib_path,  'providers'))
  end

  # Read Attribute setting for default library model/process path
  def process_path
    File.expand_path(File.join(@lib_path, 'core_process'))
  end
end

# Redefine Object to add a boolean? function.
class Object
  # Simplify boolean test on objects
  def boolean?
    self.is_a?(TrueClass) || self.is_a?(FalseClass)
  end
end
