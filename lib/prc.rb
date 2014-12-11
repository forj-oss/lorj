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


module PrcLib

   def PrcLib.dir_exists?(path)
      if File.exists?(path)
         if not File.directory?(path)
            msg = "'%s' is not a directory. Please fix it." % path
            unless log_object.nil?
               log_object.fatal(1, msg)
            else
               raise msg
            end
         end
         if not File.readable?(path) or not File.writable?(path) or not File.executable?(path)
            msg = "%s is not a valid directory. Check permissions and fix it." % path
            unless log_object.nil?
               log_object.fatal(1, msg)
            else
               raise msg
            end
         end
         return true
      end
      false
   end


   def PrcLib.ensure_dir_exists(path)
      if not dir_exists?(path)
         FileUtils.mkpath(path) if not File.directory?(path)
      end
   end


   class << self
      attr_accessor :log, :core_level
   end

   module_function

   def data_path= v
      @data_path = File.expand_path(v) if not @data_path
      PrcLib.ensure_dir_exists(@data_path)
   end

   def data_path
      @data_path
   end

   def app_name= v
      @app_name = v if not @app_name
   end

   def app_name
      @app_name
   end

   def app_defaults= v
      @app_defaults = File.expand_path(v) if not @app_defaults
   end

   def app_defaults
      @app_defaults
   end

   def log_file= v
      sFile = File.basename(v)
      sDir = File.dirname(File.expand_path(v))
      if not File.exists?(sDir)
         raise "'%s' doesn't exist. Unable to create file '%s'" % [sDir, sFile]
      end
      @log_file = File.join(sDir, sFile)
   end

   def log_file
      @log_file
   end

   def level= v

      @level = v
      unless PrcLib.log.nil?
         PrcLib.set_level(v)
      end
   end

   def level
      @level
   end

   def lib_path=(v)
      @lib_path = v if @lib_path.nil?
   end

   def lib_path()
      @lib_path
   end

   def controller_path()
      File.expand_path(File.join(@lib_path,  "providers"))
   end

   def process_path()
      File.join(@lib_path, "core_process")
   end
end


class Object
  # Simplify boolean test on objects
  def boolean?
    self.is_a?(TrueClass) || self.is_a?(FalseClass)
  end
end
