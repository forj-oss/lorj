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
  # This class is the Data object used by lorj object!
  # This is a key component of lorj
  #
  # You find this object in different places.
  #
  # type:
  # - object/data : The Data object contains any kind of data.
  #   This data contains 2 elements:
  #   - controler object : This is a ruby object managed by the controller.
  #     Only the controller has the knowledge to manage this kind of data.
  #   - attributes       : This is the internal data mapping from the controller object.
  #     The controller helped to build this data thanks to the BaseController.get_attr / BaseController.set_attr
  #     Attributes are declared by the Data model in BaseDefinition. At least usually, each object has 2 attributes: :id and :name
  #
  # - list        : The Data object contains a list of Lorj::Data
  #
  # If the object is of type :list, following functions are usable:
  #
  # - length                : return numbers of Lorj::Data
  # - each / each_index     : loop on the list, key/value or key_index. yield can return 'remove' to remove the element from the list during loop.
  #
  # If the Data object is of type :data or :object or even :list, following functions are usable.
  #
  # - set/[]=/get/[]/exist? : Basic get/set/exist? feature.
  # - type?/object_type?    : Determine the type of this object. ie :data (stands for :object as well) or :list
  # - to_a                  : Array of Data attributes
  # - empty? nil?           : Identify if the object is empty. Avoid to use nil?.
  # - register/unregister   : Used by Lorj::BaseDefinition internal @ObjectData.
  #   registered?           : Determine if this object is stored in the global object cache.

  class Lorj::Data
    # Initialize Lorj::Data object
    #
    # * *Args* :
    #   - +oType+ : default is :object
    #     Support :data/:object for single object data
    #             :list for a list of object data
    #
    # * *Returns* :
    #   hash - internal data object.
    #
    # * *Raises* :
    #   No exceptions
    #
    def initialize(oType = :object)
      oType = :data unless [:list, :object, :data].include?(oType)
      @oType = oType
      case oType
         when :data, :object
           @data = new_object
         when :list
           @data = new_object_list
      end
    end

    # Return Lorj::Data object type
    #
    # * *Args* :
    #   Nothing
    #
    # * *Returns* :
    #   - +type+ : Symbol or nil
    #      nil if no object.
    #      :object for single object data
    #      :list for a list of object data
    #
    # * *Raises* :
    #   No exceptions
    #
    def type?
      @oType
    end

    # Return :object type of the Lorj::Data object.
    #
    # * *Args* :
    #   Nothing
    #
    # * *Returns* :
    #   - +type+ : Symbol or nil
    #      nil if no object.
    #      :object type
    #
    # * *Raises* :
    #   No exceptions
    #
    def object_type?
      @data[:object_type]
    end

    # Set a Lorj::Data object and return itself.
    #
    # There 3 usages:
    # - Set from a Lorj::Data.
    #   ex: if data is already a Lorj::Data,
    #      copy = Lorj::Data.new()
    #      copy.set(data)
    # - Set from an object, not Lorj::Data and not a list.
    #   ex:
    #      data = { :test => 'toto'}
    #      copy = Lorj::Data.new()
    #      copy.set(data, :object) { |oObject |
    #         oObject
    #      }
    # - Set from a list of objects, not Lorj::Data and not a :object.
    #   ex:
    #      data = [{ :name => 'toto'}, {:name => 'test'}]
    #      copy = Lorj::Data.new()
    #      copy.set(data, :list, { :name => /^t/ }) { |oObject |
    #         oObject
    #      }
    #
    # * *Args* :
    #   - +data+  : Lorj::Data or any other data.
    #   - +ObjType: required only if data is not a Lorj::Data
    #     Use :object to store and extract attributes
    #     Use :list to extract elements, store them and extract attributes for each of them. data must support each(oObject) loop function
    #   - +Query+ : Optional. To store the query object used to get the list objects. It assumes ObjectType = :list
    #   - +yield+ : code to extract +data+ attributes from the object (:object or :list). Should return an hash containing attributes data.
    #
    # * *Returns* :
    #   - +self+ : Lorj::Data
    #
    # * *Raises* :
    #   No exceptions
    #
    def set(oObj, sObjType = nil, hQuery = {})
      if oObj.is_a?(Lorj::Data)
        oType = oObj.type?
        case oType
           when :data, :object
             @data[:object_type] = ((sObjType.nil?) ? (oObj.object_type?) : sObjType)
             @data[:object] = oObj.get(:object)
             @data[:attrs] = oObj.get(:attrs)
           when :list
             @data[:object_type] = ((sObjType.nil?) ? (oObj.object_type?) : sObjType)
             @data[:object] = oObj.get(:object)
             @data[:list] = oObj.get(:list)
             @data[:query] = oObj.get(:query)
        end
        return self
      end

      # while saving the object, a mapping work is done?
      case @oType
         when :data, :object
           @data[:object_type] = sObjType
           @data[:object] = oObj
           @data[:attrs] = yield(sObjType, oObj)
         when :list
           @data[:object] = oObj
           @data[:object_type] = sObjType
           @data[:query] = hQuery
           unless oObj.nil?
             begin
               oObj.each do | oObject |
                 next if oObject.nil?
                 begin
                   oDataObject = Lorj::Data.new(:object)

                   oDataObject.set(oObject, sObjType) do |sObjectType, oObject|
                     yield(sObjectType, oObject)
                   end
                   @data[:list] << oDataObject
                rescue => e
                  raise Lorj::PrcError.new, "'%s' Mapping attributes issue.\n%s" % [sObjType, e.message]
                 end
               end
            rescue => e
              raise Lorj::PrcError.new, "each function is not supported by '%s'.\n%s" % [oObj.class, e.message]
             end
           end
      end
      self
    end

    # Set the :object type
    #
    # * *Args* :
    #   - +ObjType: required only if data is not a Lorj::Data
    #
    # * *Returns* :
    #   - +self+ : Lorj::Data
    #
    # * *Raises* :
    #   No exceptions
    #
    def type=(sObjType)
      return self if self.empty?
      @data[:object_type] = sObjType
      self
    end

    # Get value from Lorj::data
    #
    # * *Args* :
    #   - +keys+: See get function.
    #
    # * *Returns* :
    #   - +self+ : Lorj::Data
    #
    # * *Raises* :
    #   No exceptions
    #
    def [](*key)
      get(*key)
    end

    # Set Lorj::data attribute value for an :object
    #
    # * *Args* :
    #   - +keys+ : attribute keys
    #   - +value+: Value to set
    #
    # * *Returns* :
    #   true
    #
    # * *Raises* :
    #   No exceptions
    #
    def []=(*key, value)
      return false if @oType == :list
      Lorj.rhSet(@data, value, :attrs, key)
      true
    end

    # Get value from Lorj::data
    # Depending on Lorj::Data type, you can get:
    # - :object
    #   - get internal object data (:object)
    #     ex: object = data[:object]
    #   - get attribute data
    #     ex:
    #      data = { :name => 'toto'}
    #      copy = Lorj::Data.new()
    #      copy.set(data, :object) { |oObject |
    #         {:real_name => oObject[:name]}
    #      }
    #
    #      puts copy[:name]      # => nil
    #      puts copy[:real_name] # => 'toto'
    #      puts copy[:object]    # => { :name => 'toto'}
    #      puts copy[:attrs]     # => { :real_name => 'toto'}
    # - :list
    #   - get internal object data (:object)
    #     ex: object = data[:object]
    #   - get stored query object data (:query)
    #     ex: object = data[:query]
    #   - get one element attribute or object data
    #     ex:
    #      data = [{ :name => 'toto'}, {:name => 'test'}]
    #      copy = Lorj::Data.new()
    #      copy.set(data, :list, { :name => /^t/ }) { |oObject |
    #         {:real_name => oObject[:name]}
    #      }
    #
    #      puts copy[0]             # => { :real_name => 'toto'}
    #      puts copy[0][:object]    # => { :name => 'toto'}
    #      puts copy[0][:attrs]     # => { :real_name => 'toto'}
    #      puts copy[1]             # => { :real_name => 'test'}
    #      puts copy[1, :real_name] # => 'test'
    #      puts copy[1, :test]      # => nil
    #
    # * *Args* :
    #   - +keys+: See get function.
    #
    # * *Returns* :
    #   - +self+ : Lorj::Data
    #
    # * *Raises* :
    #   No exceptions
    #
    def get(*key)
      return @data if key.length == 0
      case @oType
         when :data, :object # Return only attrs or the real object.
           return @data[key[0]] if key[0] == :object
           return Lorj.rhGet(@data, key) if key[0] == :attrs
           Lorj.rhGet(@data, :attrs, key)
         when :list
           return @data[key[0]] if [:object, :query].include?(key[0])
           return @data[:list][key[0]] if key.length == 1
           @data[:list][key[0]][key[1..-1]] # can Return only attrs or the real object.
      end
    end

    # Get the list of elements in an array from Lorj::Data :list type.
    #
    # * *Args* :
    #   No parameters
    #
    # * *Returns* :
    #   - +Elements+ : Array of elements
    #
    # * *Raises* :
    #   No exceptions
    #
    def to_a
      result = []
      each do |elem|
        result << elem[:attrs]
      end
      result
    end

    # return true if a data object exist or if an extracted attribute exist.
    #
    # * *Args* :
    #   - +keys+ : Keys to verify.
    #
    # * *Returns* :
    #   - +exist?+ : true or false.
    #
    # * *Raises* :
    #   No exceptions
    #
    # Examples:
    #      data = Lorj::Data.new()
    #
    #      puts data.exist?(:object)          # => false
    #
    #      data.set({ :name => 'toto'}, :object) { |oObject |
    #         {:real_name => oObject[:name]}
    #      }
    #      list = Lorj::Data.new()
    #
    #      puts data.exist?(:object)          # => false
    #
    #      list.set([{ :name => 'toto'}, {:name => 'test'}], :list) { |oObject |
    #         {:real_name => oObject[:name]}
    #      }
    #
    #       puts data.exist?(:object)         # => true
    #       puts data.exist?(:name)           # => true
    #       puts data.exist?(:test)           # => false
    #       puts data.exist?(:attrs, :name)   # => true
    #       puts list.exist?(0)               # => true
    #       puts list.exist?(0, :object)      # => true
    #       puts list.exist?(2)               # => false
    #       puts list.exist?(2, :object)      # => false
    #       puts list.exist?(0, :name)        # => true
    #       puts list.exist?(0, :test)        # => false
    def exist?(*key)
      case @oType
         when :data, :object
           return true if key[0] == :object && @data.key?(key[0])
           return true  if key[0] == :attrs && Lorj.rhExist?(@data, key)
           (Lorj.rhExist?(@data, :attrs, key) == key.length + 1)
         when :list
           return true if key[0] == :object && @data.key?(key[0])
           (Lorj.rhExist?(@data[:list][key[0]], :attrs, key[1..-1]) == key.length)
      end
    end

    # return true if the Lorj::Data object is nil.
    #
    # * *Args* :
    #   No parameters
    #
    # * *Returns* :
    #   - true/false
    #
    # * *Raises* :
    #   No exceptions
    #
    def empty?
      @data[:object].nil?
    end

    # Redefine nil? Warning! Can be confused. Cannot see if your object is simply nil or if current object is simply empty.
    # Use empty? instead.
    # A warning will be raised soon to ask developer to update it.
    #
    # * *Args* :
    #   No parameters
    #
    # * *Returns* :
    #   - true/false
    #
    # * *Raises* :
    #   No exceptions
    #
    def nil?
      # Obsolete Use empty? instead.
      @data[:object].nil?
    end

    # return 0, 1 or N if the Lorj::Data object is nil.
    # 0 if no objects stored
    # 1 if an object exist even if type :object or :list
    # >1 if a list is stored. It will give the number of elements in the list.
    #
    # * *Args* :
    #   No parameters
    #
    # * *Returns* :
    #   - >=0 : Number of elements
    #
    # * *Raises* :
    #   No exceptions
    #
    def length
      case @oType
         when :data
           return 0 if self.empty?
           1
         when :list
           @data[:list].length
      end
    end

    # yield loop on a list
    #
    # * *Args* :
    #   - +yield+ : sAction = yield (elem), where action can :removed to remove the element from the list.
    #
    # * *Returns* :
    #   no values
    #
    # * *Raises* :
    #   No exceptions
    #
    def each(sData = :list)
      to_remove = []
      return nil if @oType != :list || ![:object, :list].include?(sData)

      @data[:list].each do |elem|
        sAction = yield (elem)
        case sAction
           when :remove
             to_remove << elem
        end
      end
      if to_remove.length > 0
        to_remove.each do | elem |
          @data[:list].delete(elem)
        end
      end
    end

    # yield loop on a list
    #
    # * *Args* :
    #   - +yield+ : sAction = yield (index), where action can :removed to remove the element from the list.
    #
    # * *Returns* :
    #   no values
    #
    # * *Raises* :
    #   No exceptions
    #
    def each_index(sData = :list)
      to_remove = []
      return nil if @oType != :list || ![:object, :list].include?(sData)

      @data[:list].each_index do |iIndex|
        sAction = yield (iIndex)
        case sAction
           when :remove
             to_remove << @data[:list][iIndex]
        end
      end
      if to_remove.length > 0
        to_remove.each do | elem |
          @data[:list].delete(elem)
        end
      end
    end

    # A Lorj::Data can be cached by Lorj::ObjectData.
    # When adding Lorj::Data to Lorj::ObjectData, Lorj::Data object will be registered.
    # This function will determine if this object is registered or not.
    #
    # * *Args* :
    #     none
    #
    # * *Returns* :
    #   - registered : true or false if registered or not
    #
    # * *Raises* :
    #   No exceptions
    #
    def registered?
      @bRegister
    end

    # A Lorj::Data can be cached by Lorj::ObjectData.
    # When adding Lorj::Data to Lorj::ObjectData, Lorj::Data object will be registered.
    # Lorj::ObjectData will call this function to marked it as registered.
    #
    # * *Args* :
    #     none
    #
    # * *Returns* :
    #   - self
    #
    # * *Raises* :
    #   No exceptions
    #
    def register
      @bRegister = true
      self
    end

    # A Lorj::Data can be cached by Lorj::ObjectData.
    # When adding Lorj::Data to Lorj::ObjectData, Lorj::Data object will be registered.
    # Lorj::ObjectData will call this function to marked it as unregistered.
    #
    # * *Args* :
    #     none
    #
    # * *Returns* :
    #   - self
    #
    # * *Raises* :
    #   No exceptions
    #
    def unregister
      @bRegister = false
      self
    end

    private

    # Define minimal @data structure for a :list object type.
    def new_object_list
      {
        object: nil,
        object_type: nil,
        list: [],
        query: nil
      }
    end

    # Define minimal @data structure for a :object object type.
    def new_object
      oCoreObject = {
        object_type: nil,
        attrs: {},
        object: nil
      }
    end
  end
end
