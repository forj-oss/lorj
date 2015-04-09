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

# Module Lorj which contains several classes.
#
# Those classes describes :
# - processes (BaseProcess)   : How to create/delete/edit/query object.
# - controler (BaseControler) : If a provider is defined, define how will do
# object creation/etc...
# - definition(BaseDefinition): Functions to declare objects, query/data
# mapping and setup
# this task to make it to work.

module Lorj
  # Class to handle key or keypath on needs
  # The application configuration can configure a key tree, instead of a key.
  # KeyPath is used to commonly handle key or key tree.
  # Thus, a Keypath can be converted in different format:
  #
  # Ex:
  # oKey = KeyPath(:test)
  # puts oKey.to_s     # => 'test'
  # puts oKey.key      # => :test
  # puts oKey.key[0]   # => :test
  # puts oKey.key[1]   # => nil
  # puts oKey.fpath    # => ':test'
  # puts oKey.tree     # => [:test]
  # puts oKey.key_tree # => :test
  #
  # oKey = KeyPath([:test,:test2,:test3])
  # puts oKey.to_s      # => 'test/test2/test3'
  # puts oKey.key       # => :test3
  # puts oKey.key[0]    # => :test
  # puts oKey.key[1]    # => :test2
  # puts oKey.fpath     # => ':test/:test2/:test3'
  # puts oKey.tree      # => [:test,:test2,:test3]
  # puts oKey.key_tree  # => ':test/:test2/:test3'
  #
  class KeyPath
    def initialize(sKeyPath = nil, max_level = -1)
      @keypath = []
      @max_level = max_level
      set sKeyPath unless sKeyPath.nil?
    end

    def key=(sKeyPath)
      set(sKeyPath)
    end

    def set(sKeyPath)
      if sKeyPath.is_a?(Symbol)
        @keypath = [sKeyPath]
      elsif sKeyPath.is_a?(Array)
        @keypath = sKeyPath
      elsif sKeyPath.is_a?(String)
        @keypath = string_to_sarray(sKeyPath)
      end
      PrcLib.error 'key path size limit (%s) reached',
                   @max_level if @max_level > 0 && @keypath.length > @max_level
    end

    def tree # rubocop: disable TrivialAccessors
      @keypath
    end

    def key_tree
      return @keypath[0] if @keypath.length == 1
      fpath
    end

    def fpath
      return nil if @keypath.length == 0
      key_access = @keypath.clone
      key_access.each_index do |iIndex|
        next unless key_access[iIndex].is_a?(Symbol)
        key_access[iIndex] = ':' + key_access[iIndex].to_s
      end
      key_access.join('/')
    end

    def to_s
      return nil if @keypath.length == 0
      key_access = @keypath.clone
      key_access.each_index do |iIndex|
        next unless key_access[iIndex].is_a?(Symbol)
        key_access[iIndex] = key_access[iIndex].to_s
      end
      key_access.join('/')
    end

    def key(iIndex = -1)
      return nil if @keypath.length == 0
      @keypath[iIndex] if length >= 1
    end

    def length
      @keypath.length
    end

    private

    def string_to_sarray(sKeyPath)
      # rubocop: disable Style/RegexpLiteral
      if %r{[^\\/]?/[^/]} =~ sKeyPath || %r{:[^:/]} =~ sKeyPath
        # rubocop: enable Style/RegexpLiteral
        # keypath to interpret
        res = sKeyPath.split('/')
        res.each_index do |iIndex|
          next unless res[iIndex].is_a?(String)
          res[iIndex] = res[iIndex][1..-1].to_sym if res[iIndex][0] == ':'
        end
        @keypath = res
      else
        @keypath = [sKeyPath]
      end
    end
  end
end
