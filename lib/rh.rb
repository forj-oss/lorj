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

# Rh common module included in Hash and Array class.
module Rh
  public

  # Function which will parse arrays in hierarchie and will remove any control
  # element (index 0)
  def rh_remove_control(result)
    return unless [Hash, Array].include?(result.class)

    if result.is_a?(Hash)
      result.each { |elem| rh_remove_control(elem) }
    else
      result.delete_at(0) if result[0].is_a?(Hash) && result[0].key?(:__control)
      result.each_index { |index| rh_remove_control(result[index]) }
    end
  end

  private

  # Internal function to determine if result and data key contains both Hash or
  # Array and if so, do the merge task on those sub Hash/Array
  #
  def _rh_merge_recursive(result, key, data)
    return false unless [Array, Hash].include?(data.class)

    value = data[key]
    return false unless [Array, Hash].include?(value.class) &&
                        value.class == result[key].class

    if object_id == result.object_id
      result[key].rh_merge!(value)
    else
      result[key] = result[key].rh_merge(value)
    end

    true
  end

  # Internal function to determine if changing from Hash/Array to anything else
  # is authorized or not.
  #
  # The structure is changing if `result` or `value` move from Hash/Array to any
  # other type.
  #
  # * *Args*:
  #   - result: Merged Hash or Array structure.
  #   - key   : Key in result and data.
  #   - data  : Hash or Array structure to merge.
  #
  # * *returns*:
  #   - +true+  : if :__struct_changing == true
  #   - +false+ : otherwise.
  def _rh_struct_changing_ok?(result, key, data)
    return true unless [Array, Hash].include?(data[key].class) ||
                       [Array, Hash].include?(result[key].class)

    # result or value are structure (Hash or Array)
    if result.is_a?(Hash)
      control = result[:__struct_changing]
    else
      control = result[0][:__struct_changing]
      key -= 1
    end
    return true if control.is_a?(Array) && control.include?(key)

    false
  end

  # Internal function to determine if a data merged can be updated by any
  # other object like Array, String, etc...
  #
  # The decision is given by a :__unset setting.
  #
  # * *Args*:
  #   - Hash/Array data to replace.
  #   - key: string or symbol.
  #
  # * *returns*:
  #   - +false+ : if key is found in :__protected Array.
  #   - +true+ : otherwise.
  def _rh_merge_ok?(result, key)
    if result.is_a?(Hash)
      control = result[:__protected]
    else
      control = result[0][:__protected]
      key -= 1
    end

    return false if control.is_a?(Array) && control.include?(key)

    true
  end

  def _rh_control_tags
    [:__remove, :__remove_index, :__add, :__add_index,
     :__protected, :__struct_changing, :__control]
  end
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
  #   :__struct_changing: true
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
end

# Recursive Hash added to the Hash class
class Hash
  private

  # Internal function which do the real merge task by #rh_merge and #rh_merge!
  #
  # See #rh_merge for details
  #
  def _rh_merge(result, data)
    return _rh_merge_choose_data(result, data) unless data.is_a?(Hash)

    data.each do |key, _value|
      next if [:__struct_changing, :__protected].include?(key)

      _do_rh_merge(result, key, data)
    end
    [:__struct_changing, :__protected].each do |key|
      # Refuse merge by default if key data type are different.
      # This assume that the first layer merge has set
      # :__unset as a Hash, and :__protected as an Array.

      _do_rh_merge(result, key, data, true) if data.key?(key)

      # Remove all control element in arrays
      rh_remove_control(result[key]) if result.key?(key)
    end

    result
  end

  def _rh_merge_choose_data(result, data)
    # return result as first one impose the type between Hash/Array.
    return result if [Hash, Array].include?(result.class) ||
                     [Hash, Array].include?(data.class)

    data
  end
  # Internal function to execute the merge on one key provided by #_rh_merge
  #
  # if refuse_discordance is true, then result[key] can't be updated if
  # stricly not of same type.
  def _do_rh_merge(result, key, data, refuse_discordance = false)
    value = data[key]

    return if _rh_merge_do_add_key(result, key, value)

    return if _rh_merge_recursive(result, key, data)

    return if refuse_discordance

    return unless _rh_struct_changing_ok?(result, key, data)

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

  include Rh
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

  # This function is part of the rh_merge functionnality adapted for Array.
  #
  # To provide Array recursivity, we uses the element index.
  #
  # **Warning!** If the Array order has changed (sort/random) the index changed
  # and can generate unwanted result.
  #
  # To implement recursivity, and some specific Array management (add/remove)
  # you have to create an Hash and insert it at position 0 in the 'self' Array.
  #
  # **Warning!** If you create an Array, where index 0 contains a Hash, this
  # Hash will be considered as the Array control element.
  # If the first index of your Array is not a Hash, an empty Hash will be
  # inserted at position 0.
  #
  # 'data' has the same restriction then 'self' about the first element.
  # 'data' can influence the rh_merge Array behavior, by updating the first
  # element.
  #
  # The first Hash element has the following attributes:
  #
  # - :__struct_changing: Array of index which accepts to move from a structured
  #   data (Hash/Array) to another structure or type.
  #
  #   Ex: Hash => Array, Array => Integer
  #
  # - :__protected: Array of index which protects against update from 'data'
  #
  # - :__remove: Array of elements to remove. each element are remove with
  #   Array.delete function. See Array delete function for details.
  #
  # - :__remove_index: Array of indexes to remove.
  #   Each element are removed with Array.delete_at function.
  #   It starts from the highest index until the lowest.
  #   See Array delete function for details.
  #
  # **NOTE**: __remove and __remove_index cannot be used together.
  #   if both are set, __remove is choosen
  #
  # **NOTE** : __remove* is executed before __add*
  #
  # - :__add: Array of elements to add. Those elements are systematically added
  #   at the end of the Array. See Array.<< for details.
  #
  # - :__add_index: Hash of index(key) + Array of data(value) to add.
  #   The index listed refer to merged 'self' Array. several elements with same
  #   index are grouply inserted in the index.
  #   ex:
  #     [:data3].rh_merge({:__add_index => [0 => [:data1, :data2]]})
  #     => [{}, :data1, :data2, :data3]
  #
  # **NOTE**: __add and __add_index cannot be used together.
  #   if both are set, __add is choosen
  #
  # How merge is executed:
  #
  # Starting at index 0, each index of 'data' and 'self' are used to compare
  # indexed data.
  # - If 'data' index 0 has not an Hash, the 'self' index 0 is just skipped.
  # - If 'data' index 0 has the 'control' Hash, the array will be updated
  #   according to :__add and :__remove arrays.
  #   when done, those attributes are removed
  #
  # - For all next index (1 => 'data'.length), data are compared
  #
  #   - If the 'data' length is >  than 'self' length
  #     addtionnal indexed data are added to 'self'
  #
  #   - If index element exist in both 'data' and 'self',
  #     'self' indexed data is updated/merged according to control.
  #     'data' indexed data can use :unset to remove the data at this index
  #     nil is also supported. But the index won't be removed. data will just
  #     be set to nil
  #
  # when all Arrays elements are merged, rh_merge will:
  # - remove 'self' elements containing ':unset'
  #
  # - merge 'self' data at index 0 with 'data' found index 0
  #
  def rh_merge(data)
    _rh_merge(clone, data)
  end

  def rh_merge!(data)
    _rh_merge(self, data)
  end

  private

  def _rh_merge(result, data)
    data = data.clone
    data_control = _rh_merge_control(data)
    result_control = _rh_merge_control(result)

    _rh_do_control_merge(result_control, result, data_control, data)

    (1..(data.length - 1)).each do |index|
      _rh_do_array_merge(result, index, data)
    end

    (-(result.length - 1)..-1).each do |index|
      result.delete_at(index.abs) if result[index.abs] == :unset
    end

    _rh_do_array_merge(result, 0, [data_control])
    rh_remove_control(result[0]) # Remove all control elements in tree of arrays

    result
  end

  def _rh_do_array_merge(result, index, data)
    return if _rh_merge_recursive(result, index, data)

    return unless _rh_struct_changing_ok?(result, index, data)

    return unless _rh_merge_ok?(result, index)

    result[index] = data[index] unless data[index] == :kept
  end

  #  Get the control element. or create it if missing.
  def _rh_merge_control(array)
    unless array[0].is_a?(Hash)
      array.insert(0, :__control => true)
      return array[0]
    end

    _rh_control_tags.each do |prop|
      if array[0].key?(prop)
        array[0][:__control] = true
        return array[0]
      end
    end

    array.insert(0, :__control => true)

    array[0]
  end

  # Do the merge according to :__add and :__remove
  def _rh_do_control_merge(_result_control, result, data_control, _data)
    if data_control[:__remove].is_a?(Array)
      _rh_do_control_remove(result, data_control[:__remove])
    elsif data_control[:__remove_index].is_a?(Array)
      index_to_remove = data_control[:__remove_index].uniq.sort.reverse
      _rh_do_control_remove_index(result, index_to_remove)
    end

    data_control.delete(:__remove)
    data_control.delete(:__remove_index)

    if data_control[:__add].is_a?(Array)
      data_control[:__add].each { |element| result << element }
    elsif data_control[:__add_index].is_a?(Hash)
      _rh_do_control_add_index(result, data_control[:__add_index].sort)
    end

    data_control.delete(:__add)
    data_control.delete(:__add_index)
  end

  def _rh_do_control_add_index(result, add_index)
    add_index.reverse_each do |elements_to_insert|
      next unless elements_to_insert.is_a?(Array) &&
                  elements_to_insert[0].is_a?(Fixnum) &&
                  elements_to_insert[1].is_a?(Array)

      index = elements_to_insert[0] + 1
      elements = elements_to_insert[1]

      elements.reverse_each { |element| result.insert(index, element) }
    end
  end

  # do the element removal.
  def _rh_do_control_remove(result, remove)
    remove.each { |element| result.delete(element) }
  end

  def _rh_do_control_remove_index(result, index_to_remove)
    index_to_remove.each { |index| result.delete_at(index + 1) }
  end

  include Rh
end
