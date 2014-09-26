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
module PrcLib

   class Logging
     # Class used to create 2 log object, in order to keep track of error in a log file and change log output to OUTPUT on needs (option flags).

     attr_reader :level

      def initialize()

         if not PrcLib.app_name
            PrcLib.app_name = "Lorj"
         end

         if not PrcLib.data_path
            PrcLib.data_path = File.expand_path(File.join("~", ".%s" % PrcLib.app_name))
         end

         sLogFile = File.join(PrcLib.data_path, "%s.log" % PrcLib.app_name)

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
      end

      def info?
         return(@oOutLogger.info?)
      end

      def debug?
         return(@oOutLogger.debug?)
      end

      def error?
         return(@oOutLogger.error?)
      end

      def fatal?
         return(@oOutLogger.fatal?)
      end

      def info(message)
         @oOutLogger.info(message + ANSI.clear_line)
         @oFileLogger.info(message)
      end

      def debug(message)
         @oOutLogger.debug(message + ANSI.clear_line)
         @oFileLogger.debug(message)
      end

      def error(message)
         @oOutLogger.error(message + ANSI.clear_line)
         @oFileLogger.error(message)
      end

      def fatal(message, e)
         @oOutLogger.fatal(message + ANSI.clear_line)
         @oFileLogger.fatal("%s\n%s\n%s" % [message, e.message, e.backtrace.join("\n")]) if e
         @oFileLogger.fatal(message)
      end

      def warn(message)
         @oOutLogger.warn(message + ANSI.clear_line)
         @oFileLogger.warn(message)
      end

      def set_level(level)
         @level = level
         @oOutLogger.level = level
      end

      def unknown(message)
         @oOutLogger.unknown(message + ANSI.clear_line)
      end

   end

   module_function

   def log_object()
      if PrcLib.log.nil?
         PrcLib.log = PrcLib::Logging.new
      else
         PrcLib.log
      end
   end

   def message(message)
      log_object.unknown(message)
   end

   def info(message)
      log_object.info(message)
      nil
   end

   def debug(message)
      log_object.debug(message)
      nil
   end

   def warning(message)
      log_object.warn(message)
      nil
   end

   def error(message)
      log_object.error(message)
      nil
   end

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

   def high_level_msg(message)
      # Not DEBUG and not INFO. Just printed to the output.
      print ("%s" % [message]) if log_object.level > 1
      nil
   end

end
