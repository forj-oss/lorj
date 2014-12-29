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

require 'rubygems'
require 'yaml'

# Recursive Hash added to the Hash class
class Hash
  # Recursive Hash deep level found counter
  # This function will returns the count of deep level of recursive hash.
  # * *Args* :
  #   - +p+    : Array of string or symbols. keys tree to follow and check
  #              existence in yVal.
  #
  # * *Returns* :
  #   - +integer+ : Represents how many deep level was found in the recursive
  #                 hash
  #
  # * *Raises* :
  #   No exceptions
  #
  # Example: (implemented in spec)
  #
  #    yVal = { :test => {:test2 => 'value1', :test3 => 'value2'},
  #             :test4 => 'value3'}
  #
  # yVal can be represented like:
  #
  #   yVal:
  #     test:
  #       test2 = 'value1'
  #       test3 = 'value2'
  #     test4 = 'value3'
  #
  # so:
  #   # test is found
  #   yVal.rh_lexist?(:test) => 1
  #
  #   # no test5
  #   yVal.rh_lexist?(:test5) => 0
  #
  #   # :test/:test2 tree is found
  #   yVal.rh_lexist?(:test, :test2) => 2
  #
  #   # :test/:test2 is found (value = 2), but :test5 was not found in this tree
  #   yVal.rh_lexist?(:test, :test2, :test5) => 2
  #
  #   # :test was found. but :test/:test5 tree was not found. so level 1, ok.
  #   yVal.rh_lexist?(:test, :test5 ) => 1
  #
  #   # it is like searching for nothing...
  #   yVal.rh_lexist? => 0

  def rh_lexist?(*p)
    return 0 if p.length == 0

    p = p.flatten
    if p.length == 1
      return 1 if self.key?(p[0])
      return 0
    end
    return 0 unless self.key?(p[0])
    ret = 0
    ret = self[p[0]].rh_lexist?(p.drop(1)) if self[p[0]].is_a?(Hash)
    1 + ret
  end

  # Recursive Hash deep level existence
  #
  # * *Args* :
  #   - +p+    : Array of string or symbols. keys tree to follow and check
  #              existence in yVal.
  #
  # * *Returns* :
  #   - +boolean+ : Returns True if the deep level of recursive hash is found.
  #                 false otherwise
  #
  # * *Raises* :
  #   No exceptions
  #
  # Example:(implemented in spec)
  #
  #    yVal = { :test => {:test2 => 'value1', :test3 => 'value2'},
  #             :test4 => 'value3'}
  #
  # yVal can be represented like:
  #
  #   yVal:
  #     test:
  #       test2 = 'value1'
  #       test3 = 'value2'
  #     test4 = 'value3'
  #
  # so:
  #   # test is found
  #   yVal.rh_exist?(:test) => True
  #
  #   # no test5
  #   yVal.rh_exist?(:test5) => False
  #
  #   # :test/:test2 tree is found
  #   yVal.rh_exist?(:test, :test2) => True
  #
  #   # :test/:test2 is found (value = 2), but :test5 was not found in this tree
  #   yVal.rh_exist?(:test, :test2, :test5) => False
  #
  #   # :test was found. but :test/:test5 tree was not found. so level 1, ok.
  #   yVal.rh_exist?(:test, :test5 ) => False
  #
  #   # it is like searching for nothing...
  #   yVal.rh_exist? => nil
  def rh_exist?(*p)
    return nil if p.length == 0

    count = p.length
    (rh_lexist?(*p) == count)
  end

  # Recursive Hash Get
  # This function will returns the level of recursive hash was found.
  # * *Args* :
  #   - +p+    : Array of string or symbols. keys tree to follow and check
  #              existence in yVal.
  #
  # * *Returns* :
  #   - +value+ : Represents the data found in the tree. Can be of any type.
  #
  # * *Raises* :
  #   No exceptions
  #
  # Example:(implemented in spec)
  #
  #    yVal = { :test => {:test2 => 'value1', :test3 => 'value2'},
  #             :test4 => 'value3'}
  #
  # yVal can be represented like:
  #
  #   yVal:
  #     test:
  #       test2 = 'value1'
  #       test3 = 'value2'
  #     test4 = 'value3'
  #
  # so:
  #   yVal.rh_get(:test) => {:test2 => 'value1', :test3 => 'value2'}
  #   yVal.rh_get(:test5) => nil
  #   yVal.rh_get(:test, :test2) => 'value1'
  #   yVal.rh_get(:test, :test2, :test5) => nil
  #   yVal.rh_get(:test, :test5 ) => nil
  #   yVal.rh_get => { :test => {:test2 => 'value1', :test3 => 'value2'},
  #                    :test4 => 'value3'}
  def rh_get(*p)
    p = p.flatten
    return self if p.length == 0

    if p.length == 1
      return self[p[0]] if self.key?(p[0])
      return nil
    end
    return self[p[0]].rh_get(p.drop(1)) if self[p[0]].is_a?(Hash)
    nil
  end

  # Recursive Hash Set
  # This function will build a recursive hash according to the '*p' key tree.
  # if yVal is not nil, it will be updated.
  #
  # * *Args* :
  #   - +p+    : Array of string or symbols. keys tree to follow and check
  #              existence in yVal.
  #
  # * *Returns* :
  #   - +value+ : the value set.
  #
  # * *Raises* :
  #   No exceptions
  #
  # Example:(implemented in spec)
  #
  #    yVal = {}
  #
  #   yVal.rh_set(:test) => nil
  #   # yVal = {}
  #
  #   yVal.rh_set(:test5) => nil
  #   # yVal = {}
  #
  #   yVal.rh_set(:test, :test2) => :test
  #   # yVal = {:test2 => :test}
  #
  #   yVal.rh_set(:test, :test2, :test5) => :test
  #   # yVal = {:test2 => {:test5 => :test} }
  #
  #   yVal.rh_set(:test, :test5 ) => :test
  #   # yVal = {:test2 => {:test5 => :test}, :test5 => :test }
  #
  #   yVal.rh_set('blabla', :test2, 'text') => :test
  #   # yVal  = {:test2 => {:test5 => :test, 'text' => 'blabla'},
  #              :test5 => :test }
  def rh_set(value, *p)
    return nil if p.length == 0

    p = p.flatten
    if p.length == 1
      self[p[0]] = value
      return value
    end

    self[p[0]] = {} unless self[p[0]].is_a?(Hash)
    self[p[0]].rh_set(value, p.drop(1))
  end

  # Recursive Hash delete
  # This function will remove the last key defined by the key tree
  #
  # * *Args* :
  #   - +p+    : Array of string or symbols. keys tree to follow and check
  #              existence in yVal.
  #
  # * *Returns* :
  #   - +value+ : The Hash updated.
  #
  # * *Raises* :
  #   No exceptions
  #
  # Example:(implemented in spec)
  #
  #   yVal = {{:test2 => { :test5 => :test,
  #                        'text' => 'blabla' },
  #            :test5 => :test}}
  #
  #
  #   yVal.rh_del(:test) => nil
  #   # yVal = no change
  #
  #   yVal.rh_del(:test, :test2) => nil
  #   # yVal = no change
  #
  #   yVal.rh_del(:test2, :test5) => {:test5 => :test}
  #   # yVal = {:test2 => {:test5 => :test} }
  #
  #   yVal.rh_del(:test, :test2)
  #   # yVal = {:test2 => {:test5 => :test} }
  #
  #   yVal.rh_del(:test, :test5)
  #   # yVal = {:test2 => {} }
  #
  def rh_del(*p)
    return nil if p.length == 0

    p = p.flatten
    return delete(p[0]) if p.length == 1

    return nil if self[p[0]].nil?
    self[p[0]].rh_del(p.drop(1))
  end

  # Move levels (default level 1) of tree keys to become symbol.
  #
  # * *Args*    :
  #   - +levels+: level of key tree to update.
  # * *Returns* :
  #   - a new hash of hashes updated. Original Hash is not updated anymore.
  #
  # examples:
  #   With hdata = { :test => { :test2 => { :test5 => :test,
  #                                         'text' => 'blabla' },
  #                             'test5' => 'test' }}
  #
  #  rh_key_to_symbol(1) return no diff
  #  rh_key_to_symbol(2) return "test5" is replaced by :test5
  #  # hdata = { :test => { :test2 => { :test5 => :test,
  #  #                                  'text' => 'blabla' },
  #  #                      :test5 => 'test' }}
  #  rh_key_to_symbol(3) return "test5" replaced by :test5, and "text" to :text
  #  # hdata = { :test => { :test2 => { :test5 => :test,
  #  #                                  :text => 'blabla' },
  #  #                      :test5 => 'test' }}
  #  rh_key_to_symbol(4) same like rh_key_to_symbol(3)

  def rh_key_to_symbol(levels = 1)
    result = {}
    each do | key, value |
      new_key = key
      new_key = key.to_sym if key.is_a?(String)
      if value.is_a?(Hash) && levels > 1
        value = value.rh_key_to_symbol(levels - 1)
      end
      result[new_key] = value
    end
    result
  end

  # Check if levels of tree keys are all symbols.
  #
  # * *Args*    :
  #   - +levels+: level of key tree to update.
  # * *Returns* :
  #   - true  : one key path is not symbol.
  #   - false : all key path are symbols.
  # * *Raises* :
  #   Nothing
  #
  # examples:
  #   With hdata = { :test => { :test2 => { :test5 => :test,
  #                                         'text' => 'blabla' },
  #                             'test5' => 'test' }}
  #
  #  rh_key_to_symbol?(1) return false
  #  rh_key_to_symbol?(2) return true
  #  rh_key_to_symbol?(3) return true
  #  rh_key_to_symbol?(4) return true
  def rh_key_to_symbol?(levels = 1)
    each do | key, value |
      return true if key.is_a?(String)

      res = false
      if levels > 1 && value.is_a?(Hash)
        res = value.rh_key_to_symbol?(levels - 1)
      end
      return true if res
    end
    false
  end
end
