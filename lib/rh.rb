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

# Adding rh_clone at object level. This be able to use a generic rh_clone
# redefined per object Hash and Array.
class Object
  alias_method :rh_clone, :clone
end

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
    p = p.flatten

    return 0 if p.length == 0

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
    p = p.flatten

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
    p = p.flatten
    return nil if p.length == 0

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
    p = p.flatten

    return nil if p.length == 0

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
  #  hdata.rh_key_to_symbol(1) return no diff
  #  hdata.rh_key_to_symbol(2) return "test5" is replaced by :test5
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
    each do |key, value|
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
  #  hdata.rh_key_to_symbol?(1) return false
  #  hdata.rh_key_to_symbol?(2) return true
  #  hdata.rh_key_to_symbol?(3) return true
  #  hdata.rh_key_to_symbol?(4) return true
  def rh_key_to_symbol?(levels = 1)
    each do |key, value|
      return true if key.is_a?(String)

      res = false
      if levels > 1 && value.is_a?(Hash)
        res = value.rh_key_to_symbol?(levels - 1)
      end
      return true if res
    end
    false
  end

  # return an exact clone of the recursive Array and Hash contents.
  #
  # * *Args*    :
  #
  # * *Returns* :
  #   - Recursive Array/Hash cloned. Other kind of objects are kept referenced.
  # * *Raises* :
  #   Nothing
  #
  # examples:
  #  hdata = { :test => { :test2 => { :test5 => :test,
  #                                   'text' => 'blabla' },
  #                       'test5' => 'test' },
  #            :array => [{ :test => :value1 }, 2, { :test => :value3 }]}
  #
  #  hclone = hdata.rh_clone
  #  hclone[:test] = "test"
  #  hdata[:test] == { :test2 => { :test5 => :test,'text' => 'blabla' }
  #  # => true
  #  hclone[:array].pop
  #  hdata[:array].length != hclone[:array].length
  #  # => true
  #  hclone[:array][0][:test] = "value2"
  #  hdata[:array][0][:test] != hclone[:array][0][:test]
  #  # => true
  def rh_clone
    result = {}
    each do |key, value|
      if [Array, Hash].include?(value.class)
        result[key] = value.rh_clone
      else
        result[key] = value
      end
    end
    result
  end

  # Merge the current Hash object (self) cloned with a Hash/Array tree contents
  # (data).
  #
  # 'self' is used as original data to merge to.
  # 'data' is used as data to merged to clone of 'self'. If you want to update
  # 'self', use rh_merge!
  #
  # if 'self' or 'data' contains a Hash tree, the merge will be executed
  # recursively.
  #
  # The current function will execute the merge of the 'self' keys with the top
  # keys in 'data'
  #
  # The merge can be controlled by an additionnal Hash key '__*' in each
  # 'self' key.
  # If both a <key> exist in 'self' and 'data', the following decision is made:
  # - if both 'self' and 'data' key contains an Hash or and Array, a recursive
  #   merge if Hash or update if Array, is started.
  #
  # - if 'self' <key> contains an Hash or an Array, but not 'data' <key>, then
  #   'self' <key> will be set to the 'data' <key> except if 'self' <Key> has
  #   :__no_unset: true
  #   data <key> value can set :unset value
  #
  # - if 'self' <key> is :unset and 'data' <key> is any value
  #   'self' <key> value is set with 'data' <key> value.
  #   'data' <key> value can contains a Hash with :__no_unset: true to
  #     protect this key against the next merge. (next config layer merge)
  #
  # - if 'data' <key> exist but not in 'self', 'data' <key> is just added.
  #
  # - if 'data' & 'self' <key> exist, 'self'<key> is updated except if key is in
  #   :__protected array list.
  #
  # * *Args*    :
  #   - hash : Hash data to merge.
  #
  # * *Returns* :
  #   - Recursive Array/Hash merged.
  #
  # * *Raises* :
  #   Nothing
  #
  # examples:
  #
  def rh_merge(data)
    _rh_merge(clone, data)
  end

  # Merge the current Hash object (self) with a Hash/Array tree contents (data).
  #
  # For details on this functions, see #rh_merge
  #
  def rh_merge!(data)
    _rh_merge(self, data)
  end

  private

  # Internal function which do the real merge task by #rh_merge and #rh_merge!
  #
  # See #rh_merge for details
  #
  def _rh_merge(result, data)
    data.each do |key, value|
      next if [:__struct_changing, :__protected].include?(key)

      _do_rh_merge(result, key, value)
    end
    [:__struct_changing, :__protected].each do |key|
      # Refuse merge by default if key data type are different.
      # This assume that the first layer merge has set
      # :__unset as a Hash, and :__protected as an Array.
      _do_rh_merge(result, key, data[key], true) if data.key?(key)
    end

    result
  end

  # Internal function to execute the merge on one key provided by #_rh_merge
  #
  # if refuse_discordance is true, then result[key] can't be updated if
  # stricly not of same type.
  def _do_rh_merge(result, key, value, refuse_discordance = false)
    return if _rh_merge_do_add_key(result, key, value)

    return if _rh_merge_recursive(result, key, value)

    return if refuse_discordance

    return unless _rh_struct_changing_ok?(result, key, value)

    return unless _rh_merge_ok?(result, key)

    _rh_merge_do_upd_key(result, key, value)
  end

  def _rh_merge_do_add_key(result, key, value)
    unless result.key?(key) || value == :unset
      result[key] = value # New key added
      return true
    end
    false
  end

  def _rh_merge_do_upd_key(result, key, value)
    if value == :unset
      result.delete(key) if result.key?(key)
      return
    end

    result[key] = value # Key updated
  end

  # rubocop: disable Metrics/PerceivedComplexity

  # Internal function to determine if result and data are both Hash or Array
  # and if so, do the merge task
  #
  def _rh_merge_recursive(result, key, value)
    return false unless [Array, Hash].include?(value.class) &&
                        value.class == result[key].class

    if value.is_a?(Hash)
      if object_id == result.object_id
        result[key].rh_merge!(value)
      else
        result[key] = result[key].rh_merge(value)
      end
      return true
    end

    # No recursivity possible for an Array. add/delete only
    if object_id == result.object_id
      result[key].update!(value)
    else
      result[key] = result[key].update(value)
    end

    true
  end

  # Internal function to determine if changing from Hash/Array to anything else
  # is authorized or not.
  #
  # The structure is changing if `result` or `value` move from Hash/Array to any
  # other type.
  #
  # * *returns*:
  #   - +true+  : if :__struct_changing == true
  #   - +false+ : otherwise.
  def _rh_struct_changing_ok?(result, key, value)
    return true unless [Array, Hash].include?(value.class) ||
                       [Array, Hash].include?(result[key].class)

    # result or value are structure (Hash or Array)
    return true if result[:__struct_changing].is_a?(Array) &&
                   result[:__struct_changing].include?(key)
    false
  end

  # Internal function to determine if a data merged can be updated by any
  # other object like Array, String, etc...
  #
  # The decision is given by a :__unset setting.
  #
  # * *Args*:
  #   - Hash data to replace.
  #   - key: string or symbol.
  #
  # * *returns*:
  #   - +false+ : if key is found in :__protected Array.
  #   - +true+ : otherwise.
  def _rh_merge_ok?(result, key)
    return false if result.is_a?(Hash) &&
                    result[:__protected].is_a?(Array) &&
                    result[:__protected].include?(key)

    true
  end
end

# Defines rh_clone for Array
class Array
  # return an exact clone of the recursive Array and Hash contents.
  #
  # * *Args*    :
  #
  # * *Returns* :
  #   - Recursive Array/Hash cloned.
  # * *Raises* :
  #   Nothing
  #
  # examples:
  #  hdata = { :test => { :test2 => { :test5 => :test,
  #                                   'text' => 'blabla' },
  #                       'test5' => 'test' },
  #            :array => [{ :test => :value1 }, 2, { :test => :value3 }]}
  #
  #  hclone = hdata.rh_clone
  #  hclone[:test] = "test"
  #  hdata[:test] == { :test2 => { :test5 => :test,'text' => 'blabla' }
  #  # => true
  #  hclone[:array].pop
  #  hdata[:array].length != hclone[:array].length
  #  # => true
  #  hclone[:array][0][:test] = "value2"
  #  hdata[:array][0][:test] != hclone[:array][0][:test]
  #  # => true
  def rh_clone
    result = []
    each do |value|
      begin
        result << value.rh_clone
      rescue
        result << value
      end
    end
    result
  end

  # Add/Remove elements in the current Array object (self) with another Array
  # (data).
  #
  # one or more values in self Array can be removed by setting a Hash containing
  # :unset => Array of objects to remove.
  def update(data)
    _update(clone, data)
  end

  def update!(data)
    _update(self, data)
  end

  def _update(result, data)
    data.each do |value|
      if value.is_a?(Hash) && value.key?(:unset)
        value[:unset].each { |toremove| result.delete(toremove) }
        next
      end

      next if result.index(value)

      result << value
    end
    result
  end
end
