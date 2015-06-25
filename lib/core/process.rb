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
    attr_reader :defaults_file, :data_file, :process, :name, :controllers,
                :lib_name

    # ProcessResource initialization
    #
    # Create a ProcessResource Instance with resource data.
    #
    # * *Args*:
    #   - +name+ : Name of the process
    #   - +path+ : Process path
    #     By default the process path will search for:
    #     - <name>_process.rb : Main process file
    #     - <name>/controllers/<controller>/<controller>.rb : controllers list
    #       attached to the process `name`.
    #     - <name>/defaults.yaml : defaults process values
    #       (under section :defaults)
    #     - <name>/data.yaml : Process data definition
    #
    #   You can redefine some defaults, with `props` Hash argument.
    #
    #   - :controllers_dir : Change the name of the controllers directory.
    #     Default is `controllers`
    #   - :controllers_path: Change the complete path to search for controllers
    #     By default is `<name>/controllers`
    #   - :defaults_file   : Use a different file as process defaults.
    #     By default is `<name>/defaults.yaml`
    #   - :data_file    : Use a different file as process data definition.
    #     By default is `<name>/data.yaml`
    #   - :lib_name     : Is the name of the library declaring the process.
    #
    # * *return*:
    #   - self with at least a process name and a path to it.
    #
    #     If any data are invalid, the process name will be set to nil.
    def initialize(name, path, props = {})
      name, path, props = _validate_parameters(name, path, props)

      return if name.nil?

      process_path = File.expand_path(File.join(path, 'process',
                                                name + '_process.rb'))

      return nil unless File.exist?(process_path)
      @process = process_path
      @name = name

      controller_dir = 'controllers'
      controller_dir = props[:controllers_dir] if props.key?(:controllers_dir)
      ctrls_path = File.expand_path(File.join(path, 'process', name,
                                              controller_dir))

      _identify_controllers(_get_value(props, :controllers_path, ctrls_path))

      defaults_file = _get_file(props, :defaults_file,
                                File.join(path, 'process',
                                          name, 'defaults.yaml'))
      @defaults_file = defaults_file if defaults_file

      data_file = _get_file(props, :data_file, File.join(path, 'process',
                                                         name, 'data.yaml'))
      @data_file = data_file if data_file

      @lib_name = props[:lib_name] if props.key?(:lib_name)

      self
    end

    private

    def _get_value(props, key, default)
      return props[key] if props.key?(key)
      default
    end

    def _get_file(props, key, filename)
      file = File.expand_path(filename)
      file = _get_value(props, key, file)
      return file if File.exist?(file)
    end

    # Ensure parameters are correct
    def _validate_parameters(name, path, props)
      return unless [String, Symbol].include?(name.class) && path.is_a?(String)

      props = {} unless props.is_a?(Hash)

      # Determine resources
      name = name.to_s if name.is_a?(Symbol)
      [name, path, props]
    end

    def _identify_controllers(controller_path)
      return unless File.directory?(controller_path)

      @controllers = {}

      Dir.foreach(controller_path) do |dir|
        next if dir.match(/^\.\.?$/)

        next unless File.exist?(File.join(controller_path, dir, dir + '.rb'))

        @controllers[dir] = File.join(controller_path, dir, dir + '.rb')
      end
    end
  end
end
