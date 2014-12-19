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
# - controler (BaseControler) : If a provider is defined, define how will do object creation/etc...
# - definition(BaseDefinition): Functions to declare objects, query/data mapping and setup
# this task to make it to work.

module Lorj
  # Class to handle key or keypath on needs
  # The application configuration can configure a key tree, instead of a key.
  # KeyPath is used to commonly handle key or key tree.
  # Thus, a Keypath can be converted in different format:
  #
  # Ex:
  # oKey = KeyPath(:test)
  # puts oKey.to_s      # => 'test'
  # puts oKey.sKey      # => :test
  # puts oKey.sKey[0]   # => :test
  # puts oKey.sKey[1]   # => nil
  # puts oKey.sFullPath # => ':test'
  #  puts oKey.aTree    # => [:test]
  #
  # oKey = KeyPath([:test,:test2,:test3])
  # puts oKey.to_s      # => 'test/test2/test3'
  # puts oKey.sKey      # => :test3
  # puts oKey.sKey[0]   # => :test
  # puts oKey.sKey[1]   # => :test2
  # puts oKey.sFullPath # => ':test/:test2/:ẗest3'
  # puts oKey.aTree     # => [:test,:test2,:test3]
  #
  class KeyPath
    def initialize(sKeyPath = nil)
      @keypath = []
      set sKeyPath
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
        if /[^\\\/]?\/[^\/]/ =~ sKeyPath || /:[^:\/]/ =~ sKeyPath
          # keypath to interpret
          aResult = sKeyPath.split('/')
          aResult.each_index do | iIndex |
            next unless aResult[iIndex].is_a?(String)
            aResult[iIndex] = aResult[iIndex][1..-1].to_sym if aResult[iIndex][0] == ':'
          end
          @keypath = aResult
        else
          @keypath = [sKeyPath]
        end
      end
    end

    def aTree
      @keypath
    end

    def sFullPath
      return nil if @keypath.length == 0
      aKeyAccess = @keypath.clone
      aKeyAccess.each_index do |iIndex|
        next unless aKeyAccess[iIndex].is_a?(Symbol)
        aKeyAccess[iIndex] = ':' + aKeyAccess[iIndex].to_s
      end
      aKeyAccess.join('/')
    end

    def to_s
      return nil if @keypath.length == 0
      aKeyAccess = @keypath.clone
      aKeyAccess.each_index do |iIndex|
        next unless aKeyAccess[iIndex].is_a?(Symbol)
        aKeyAccess[iIndex] = aKeyAccess[iIndex].to_s
      end
      aKeyAccess.join('/')
    end

    def sKey(iIndex = -1)
      return nil if @keypath.length == 0
      @keypath[iIndex] if length >= 1
    end

    def length
      @keypath.length
    end
  end
end
