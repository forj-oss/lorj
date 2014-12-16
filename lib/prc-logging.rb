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


# create a forj.log file in ~/.hpcloud/forj.log

require 'rubygems'
require 'logger'
require 'ansi'
require 'ansi/logger'

#
# PrcLib module
#
# PrcLib Implements a Logging class based on logger.
#
# For details about this class capabilities, see PrcLib::Logging
#
#    # To use the Prc::Logging system, do the following:
#    require 'PrcLib'
#
#    # To configure logging system:
#    PrcLib.app_name = 'config/app'    # Define application data path as ~/.<app_name>. Ex: 'config/app' will use ~/.config/app
#    PrcLib.log_file = 'app.log'       # Relative path to the log file name stored in the Application data path. Here, ~/.config/app/app.log
#    PrcLib.level = Logger::FATAL      # Define printout debug level. Can be any Logger predefined value.
#
#    # To log some information:
#    PrcLib.debug('My debug message')
#    PrcLib.info('My info message')
#    PrcLib.warning('my warning')
#    PrcLib.error('my error')
#    PrcLib.fatal(2, "Fatal error, with return code = 2)
#    PrcLib.message('Only printout message')
#
#    # You can printout some instant message to the terminal, not logged.
#    # This is useful before any action that will take time to be executed.
#    # It is inform the end user that something is still running, which means
#    # the application is not frozen
#    PrcLib.state("Running a long task")
#    # The next message will replace the previous state message.
#    sleep(10)
#    PrcLib.info("The long task has been executed successfully.")
#
#    # You can change the logger level with PrcLib.level
#    PrcLib.level = Logger::DEBUG
#
#    # You can just print high level message (print without \n) if PrcLib.level is not DEBUG or INFO.
#    PrcLib.high_level_msg("Print a message, not logged, if level is not DEBUG or INFO")
#
# Enjoy!
module PrcLib

   # Class used to create 2 logger object, in order to keep track of error in a log file and change log output to OUTPUT on needs (option flags).
   # The idea is that everytime, if you did not set the debug level mode, you can refer to the log file which is
   # already configured with Logger::DEBUG level.
   #
   # As well, sometimes, you do not want to keep track on messages that are just to keep informed the end user about activity.
   # So, this object implement 2 Logger objects.
   # * One for log file
   # * One for print out.
   #
   # Everytime you log a message with Logging, it is printed out if the level permits and stored everytime in the log file, never mind about Logger level set.
   # In several cases, messages are printed out, but not stored in the log file.
   #
   # See Logging functions for details.
   #
   class Logging

     attr_reader :level

      # Initialize Logging instance
      # The log file name is defined by PrcLib.log_file
      # The log path is defined by PrcLib.app_name and will be kept as ~/.<PrcLib.app_name>
      # The log level is defined by PrcLib.level. It will update only log print out.
      # Depending on levels, messages are prefixed by colored 'ERROR!!!', 'FATAL!!!', 'WARNING' or <LEVEL NAME>
      def initialize()

         if not PrcLib.app_name
            PrcLib.app_name = "Lorj"
         end

         if not PrcLib.data_path
            PrcLib.data_path = File.expand_path(File.join("~", ".%s" % PrcLib.app_name))
         end

         sLogFile = PrcLib.log_file
         sLogFile = File.join(PrcLib.data_path, "%s.log" % PrcLib.app_name) if PrcLib.log_file.nil?

         @oFileLogger = Logger.new(sLogFile, 'weekly')
         @oFileLogger.level = Logger::DEBUG
         @oFileLogger.formatter = proc do |severity, datetime, progname, msg|
            "#{progname} : #{datetime}: #{severity}: #{msg} \n"
         end

         @oOutLogger = Logger.new(STDOUT)
         @level = (PrcLib.level.nil? ? Logger::WARN : PrcLib.level)
         @oOutLogger.level = @level
         @oOutLogger.formatter = proc do |severity, datetime, progname, msg|
            case severity
               when 'ANY'
                  str = "#{msg} \n"
               when "ERROR", "FATAL"
                  str = ANSI.bold(ANSI.red("#{severity}!!!")) + ": #{msg} \n"
               when "WARN"
                  str = ANSI.bold(ANSI.yellow("WARNING")) + ": #{msg} \n"
               else
                  str = "#{severity}: #{msg} \n"
            end
            str
         end
         PrcLib.log_file = sLogFile
      end

      # Is Logging print out level is info?
      def info?
         return(@oOutLogger.info?)
      end

      # Is Logging print out level is debug?
      def debug?
         return(@oOutLogger.debug?)
      end

      # Is Logging print out level is error?
      def error?
         return(@oOutLogger.error?)
      end

      # Is Logging print out level is fatal?
      def fatal?
         return(@oOutLogger.fatal?)
      end

      # Log to STDOUT and Log file and INFO class message
      def info(message)
         @oOutLogger.info(message + ANSI.clear_line)
         @oFileLogger.info(message)
      end

      # Log to STDOUT and Log file and DEBUG class message
      def debug(message)
         @oOutLogger.debug(message + ANSI.clear_line)
         @oFileLogger.debug(message)
      end

      # Log to STDOUT and Log file and ERROR class message
      def error(message)
         @oOutLogger.error(message + ANSI.clear_line)
         @oFileLogger.error(message)
      end

      # Log to STDOUT and Log file and FATAL class message
      # fatal retrieve the caller list of functions and save it to the log file if the exception class is given.
      # The exception class should provide message and backtrace.
      def fatal(message, e)
         @oOutLogger.fatal(message + ANSI.clear_line)
         @oFileLogger.fatal("%s\n%s\n%s" % [message, e.message, e.backtrace.join("\n")]) if e
         @oFileLogger.fatal(message)
      end

      # Log to STDOUT and Log file and WARNING class message
      def warn(message)
         @oOutLogger.warn(message + ANSI.clear_line)
         @oFileLogger.warn(message)
      end

      # set STDOUT logger level
      def set_level(level)
         @level = level
         @oOutLogger.level = level
      end

      # Print out a message, not logged in the log file. This message is printed out systematically as not taking care of logger level.
      def unknown(message)
         @oOutLogger.unknown(message + ANSI.clear_line)
      end

   end

   module_function

   # Create a Logging object if missing and return it.
   # Used internally by other functions
   def log_object()
      if PrcLib.log.nil?
         PrcLib.log = PrcLib::Logging.new
      else
         PrcLib.log
      end
   end

   # Print out a message, not logged in the log file. This message is printed out systematically as not taking care of logger level.
   def message(message)
      log_object.unknown(message)
   end

   # Log to STDOUT and Log file and INFO class message
   def info(message)
      log_object.info(message)
      nil
   end

   # Log to STDOUT and Log file and DEBUG class message
   def debug(message)
      log_object.debug(message)
      nil
   end

   # Log to STDOUT and Log file and WARNING class message
   def warning(message)
      log_object.warn(message)
      nil
   end

   # Log to STDOUT and Log file and ERROR class message
   def error(message)
      log_object.error(message)
      nil
   end

   # Log to STDOUT and Log file and FATAL class message then exit the application with a return code.
   # fatal retrieve the caller list of functions and save it to the log file if the exception class is given.
   # The exception class should provide message and backtrace.
   def fatal(rc, message, e = nil)
      log_object.fatal(message, e)
      puts 'Issues found. Please fix it and retry. Process aborted.'
      exit rc
   end

   def set_level(level)
      log_object.set_level(level)
      nil
   end

   def state(message)
      print("%s ...%s\r" % [message, ANSI.clear_line]) if log_object.level <= Logger::INFO
      nil
   end

   # Not DEBUG and not INFO. Just printed to the output.
   def high_level_msg(message)

      print ("%s" % [message]) if log_object.level > 1
      nil
   end

end
