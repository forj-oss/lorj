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

# Define process module management in Lorj
#
module Lorj
  # This class defines a Process module
  #
  #
  class ProcessResource
    attr_reader :defaults_file, :data_file, :process, :name, :controllers

    def initialize(name, path, props = {})
      # Determine resources
      name = name.to_s if name.is_a?(Symbol)

      process_path = File.expand_path(File.join(path, 'process',
                                                name + '_process.rb'))

      return nil unless File.exist?(process_path)
      @process = process_path
      @name = name

      controller_dir = 'controllers'
      controller_dir = props[:controllers_dir] if props.key?(:controllers_dir)
      controller_path = File.expand_path(File.join(path, controller_dir))

      _identify_controllers(controller_path)

      defaults_file = File.expand_path(File.join(path, 'defaults.yaml'))
      @defaults_file = defaults_file if File.exist?(defaults_file)

      data_file = File.expand_path(File.join(path, 'data.yaml'))
      @data_file = data_file if File.exist?(data_file)

      self
    end

    private

    def _identify_controllers(controller_path)
      @controllers = {}

      Dir.foreach(controller_path) do |dir|
        next if dir.match(/^\.\.?$/)

        next unless File.exist?(File.join(controller_path, dir, dir + '.rb'))

        @controllers[dir] = File.join(controller_path, dir, dir + '.rb')
      end
    end
  end
end
