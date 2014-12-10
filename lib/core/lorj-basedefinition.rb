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
   # Following class defines class levels function to
   # declare framework objects.
   # As each process needs to define new object to deal with
   # require that process to define it with definition functions
   # See definition.rb for functions to use.

   class BaseDefinition
      # Capitalized function are called to start a process. It is done by Core class.

      # Call meta lorj object creation process.
      # The creation process can implement any logic like:
      # - create an object in the DB.
      # - check object existence in the DB. If not exists, create it.
      #
      # * *Args* :
      #   - +ObjectType+ : Meta object type to create.
      #   - +Config+     : Optional. Hash containing list of data to use for creation.
      #
      # * *Returns* :
      #   - +Object+ : Lorj::Data object of type +ObjectType+ created.
      #
      # * *Raises* :
      #   - Warning if the create_e process handler did not return any data. (nil)
      #   - Warning if the Config data passed are not required by the meta object (or dependencies) at creation time.
      #   - Error if ObjectType has never been declared.
      #   - Error if the dependencies create_e process handler did not return any data. (nil) - Loop detection.
      #   - Error if the create_e process handler raise an error.
      #
      def Create(sObjectType, hConfig = {})

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sObjectType, :create_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               PrcLib::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sObjectType, sObjectType])
            end
         end

         return nil if not sObjectType
         raise Lorj::PrcError.new(), "%s.Create: '%s' is not a known object type." % [self.class, sObjectType] if Lorj::rhExist?(@@meta_obj, sObjectType) != 1

         pProc = Lorj::rhGet(@@meta_obj, sObjectType, :lambdas, :create_e)

         # Check required parameters
         oObjMissing = _check_required(sObjectType, :create_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop

            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sObjectType, :create_e, pProc).reverse

            raise Lorj::PrcError.new(), "loop detection: '%s' is required but Create(%s) did not loaded it." % [sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sObjectType # Context: Default object used.

         if pProc.nil?
            # This object is a meta object, without any data.
            # Used to build other kind of objects.
            oObject = Lorj::Data.new
            oObject.set({}, sObjectType) {}
         else
            # build Function params to pass to the event handler.
            aParams = _get_object_params(sObjectType, :create_e, pProc,)
            Lorj.debug(2, "Create Object '%s' - Running '%s'" % [sObjectType, pProc])

            # Call the process function.
            # At some point, the process will call the controller, via the framework.
            # This controller call via the framework has the role to
            # create an ObjectData well formatted, with _return_map function
            # See Definition.connect/create/update/query/get functions (lowercase)
            oObject = @oForjProcess.method(pProc).call(sObjectType, aParams)
            # return usually is the main object that the process called should provide.
            # Save Object if the object has been created by the process, without controller
         end

         unless oObject.nil?
            query_cleanup(sObjectType)
            @ObjectData.add(oObject)
         else
            PrcLib::warning("'%s' has returned no data for object Lorj::Data '%s'!" % [pProc, sObjectType])
         end
      end

      # Call meta lorj object deletion process
      # There is no implementation of cascade deletion. It is up to the process to do it or not.
      #
      # * *Args* :
      #   - +ObjectType+ : Meta object type to create.
      #   - +Config+     : Optional. Hash containing list of data to use for creation.
      #
      # * *Returns* :
      #   - +Deleted+    : true if deleted or false otherwise.
      #
      # * *Raises* :
      #   - Warning if the create_e process handler did not return any data. (nil)
      #   - Warning if the Config data passed are not required by the meta object (or dependencies) at creation time.
      #   - Error if ObjectType has never been declared.
      #   - Error if the dependencies query_e process handler did not return any data. (nil) - Loop detection.
      #   - Error if the query_e process handler raise an error.
      #
      def Delete(sCloudObj, hConfig = {})
         return nil if not sCloudObj

         raise Lorj::PrcError.new(), "%s.Delete: '%s' is not a known object type." % [self.class, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sCloudObj, :delete_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               PrcLib::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sCloudObj, sCloudObj])
            end
         end

         pProc = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas, :delete_e)

         return nil if pProc.nil?

         # Check required parameters
         oObjMissing = _check_required(sCloudObj, :delete_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop
            if sElem == sCloudObj
               debug(2, "'%s' object is not previously loaded or created." % sCloudObj) if sElem == sCloudObj
               next
            end
            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sCloudObj, :delete_e, pProc).reverse
            raise Lorj::PrcError.new(), "Unable to delete '%s' object. required '%s' data was not loaded after 'Create(%s)'. Check create handler for object type '%s'." % [sCloudObj, sElem, sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sCloudObj # Context: Default object used.

         # build Function params to pass to the event handler.
         aParams = _get_object_params(sCloudObj, :delete_e, pProc)

         bState = @oForjProcess.method(pProc).call(sCloudObj, aParams)
         # return usually is the main object that the process called should provide.
         if bState
            @ObjectData.delete(sCloudObj)
         end

      end

      # Function to clean the cache for a specific meta lorj object queried.
      #
      # * *Args* :
      #   - +ObjectType+ : Meta object type to cleanup.
      #
      # * *Returns* :
      #   no data
      #
      # * *Raises* :
      #
      def query_cleanup(sCloudObj)
         oList = @ObjectData[:query, sCloudObj]
         unless oList.nil?
            @ObjectData.delete(oList)
            Lorj.debug(2, "Query cache for object '%s' cleaned." % sCloudObj)
         end
      end

      # Function to clean the cache for a specific meta lorj object.
      #
      # * *Args* :
      #   - +ObjectType+ : Meta object type to cleanup.
      #
      # * *Returns* :
      #   no data
      #
      # * *Raises* :
      #
      def object_cleanup(sCloudObj)
         oObject = @ObjectData[sCloudObj, :ObjectData]
         unless oObject.nil?
            @ObjectData.delete(oObject)
         end
      end

      # Function to execute a query process. This function returns a Lorj::Data of type :list.
      #
      # * *Args* :
      #   - +ObjectType+ : Meta object type to query.
      #   - +Query+      : Hash. Represent the query to execute.
      #   - +Config+     : Optional. Hash containing list of data to use for query.
      #
      # * *Returns* :
      #   Lorj::Data of type :list
      #
      # * *Raises* :
      #
      #
      def Query(sCloudObj, hQuery, hConfig = {})

         return nil if not sCloudObj

         raise Lorj::PrcError.new(), "$s.Get: '%s' is not a known object type." % [self.class, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sCloudObj, :query_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               PrcLib::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sCloudObj, sCloudObj])
            end
         end

         # Check if we can re-use a previous query
         oList = @ObjectData[:query, sCloudObj]
         unless oList.nil?
            if oList[:query] == hQuery
               Lorj.debug(3, "Using Object '%s' query cache : %s" % [sCloudObj, hQuery])
               return oList
            end
         end

         pProc = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas, :query_e)

         return nil if pProc.nil?

         # Check required parameters
         oObjMissing = _check_required(sCloudObj, :query_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop
            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sCloudObj, :query_e, pProc).reverse
            raise Lorj::PrcError.new(), "loop detection: '%s' is required but Query(%s) did not loaded it." % [sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sCloudObj # Context: Default object used.

         # build Function params to pass to the Process Event handler.
         aParams = _get_object_params(sCloudObj, :query_e, pProc)

         # Call the process function.
         # At some point, the process will call the controller, via the framework.
         # This controller call via the framework has the role to
         # create an ObjectData well formatted, with _return_map function
         # See Definition.connect/create/update/query/get functions (lowercase)
         oObject = @oForjProcess.method(pProc).call(sCloudObj, hQuery, aParams)
         # return usually is the main object that the process called should provide.
         unless oObject.nil?
            # Save Object if the object has been created by the process, without controller
            @ObjectData.add(oObject)
         else
            PrcLib::warning("'%s' returned no collection of objects Lorj::Data for '%s'" % [pProc, sCloudObj])
         end
      end

      # Function to execute a get process. This function returns a Lorj::Data of type :object.
      #
      # * *Args* :
      #   - +ObjectType+ : Meta object type to query.
      #   - +UniqId+     : Uniq ID.
      #   - +Config+     : Optional. Hash containing list of data to use for getting.
      #
      # * *Returns* :
      #   Lorj::Data of type :object
      #
      # * *Raises* :
      #   - Warning if the Config data passed are not required by the meta object (or dependencies) at creation time.
      #   - Error if ObjectType has never been declared.
      #   - Error if the dependencies get_e process handler did not return any data. (nil) - Loop detection.
      #   - Error if the get_e process handler raise an error.
      #
      def Get(sCloudObj, sUniqId, hConfig = {})

         return nil if not sCloudObj

         raise Lorj::PrcError.new(), "$s.Get: '%s' is not a known object type." % [self.class, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sCloudObj, :get_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               Lorj::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sCloudObj, sCloudObj])
            end
         end

         pProc = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas, :get_e)

         return nil if pProc.nil?

         # Check required parameters
         oObjMissing = _check_required(sCloudObj, :get_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop
            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sCloudObj, :get_e, pProc).reverse
            raise Lorj::PrcError.new(), "loop detection: '%s' is required but Get(%s) did not loaded it." % [sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sCloudObj # Context: Default object used.

         # build Function params to pass to the Process Event handler.
         aParams = _get_object_params(sCloudObj, :get_e, pProc)

         # Call the process function.
         # At some point, the process will call the controller, via the framework.
         # This controller call via the framework has the role to
         # create an ObjectData well formatted, with _return_map function
         # See Definition.connect/create/update/query/get functions (lowercase)
         oObject = @oForjProcess.method(pProc).call(sCloudObj, sUniqId, aParams)
         # return usually is the main object that the process called should provide.
         unless oObject.nil?
            # Save Object if the object has been created by the process, without controller
            @ObjectData.add(oObject)
         end
      end

      # Function to execute a update process. This function returns a Lorj::Data of type :object.
      #
      # * *Args* :
      #   - +ObjectType+ : Meta object type to query.
      #   - +Config+     : Optional. Hash containing list of data to use for updating.
      #
      # * *Returns* :
      #   Lorj::Data of type :object
      #
      # * *Raises* :
      #   - Warning if the Config data passed are not required by the meta object (or dependencies) at creation time.
      #   - Error if ObjectType has never been declared.
      #   - Error if the dependencies get_e process handler did not return any data. (nil) - Loop detection.
      #   - Error if the get_e process handler raise an error.
      #
      def Update(sCloudObj, hConfig = {})

         return nil if not sCloudObj

         raise Lorj::PrcError.new(), "$s.Update: '%s' is not a known object type." % [self.class, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj) != 1

         if hConfig.length > 0
            # cleanup runtime data to avoid conflicts between multiple calls
            valid_keys = _identify_data(sCloudObj, :update_e)
            valid_keys.each { | sKey|
               value = Lorj::rhGet(hConfig, sKey)
               @oForjConfig[sKey] = value if not @oForjConfig.exist?(sKey) or @oForjConfig.exist?(sKey) == 'runtime'
               Lorj::rhSet(hConfig, nil, sKey)
            }
            if hConfig.length > 0
               PrcLib::warning("'%s' has been passed but not declared to '%s' object. Those are ignored until you add it in the model definition of '%s'" % [hConfig.keys, sCloudObj, sCloudObj])
            end
         end

         pProc = Lorj::rhGet(@@meta_obj, sCloudObj, :lambdas, :update_e)

         return nil if pProc.nil?

         # Check required parameters
         oObjMissing = _check_required(sCloudObj, :update_e, pProc).reverse

         while oObjMissing.length >0
            sElem = oObjMissing.pop
            raise Lorj::PrcError.new(),"Unable to create Object '%s'" % sElem if not Create(sElem)
            oObjMissing = _check_required(sCloudObj, :update_e, pProc).reverse
            raise Lorj::PrcError.new(), "loop detection: '%s' is required but Update(%s) did not loaded it." % [sElem, sElem] if oObjMissing.include?(sElem)
         end
         @RuntimeContext[:oCurrentObj] = sCloudObj # Context: Default object used.

         # build Function params to pass to the event handler.
         aParams = _get_object_params(sCloudObj, :update_e, pProc)

         oObject = @oForjProcess.method(pProc).call(sCloudObj, aParams)
         # return usually is the main object that the process called should provide.
         unless oObject.nil?
            # Save Object if the object has been created by the process, without controller
            @ObjectData.add(oObject)
         end
      end

      # Function to execute a setup process.
      # The setup process will ask the end user to enter values as defined by the defaults.yaml application defaults.
      # For setup features implemented, see Lorj::BaseDefinition::meta_data class variable definition.
      #
      # Setup by default, will ask any kind of data required by a meta object and all dependencies.
      # If the setup needs to add some extra fields to ask to the user, set it in /:setup/:ask_step/*:add/* section
      #
      # Setup uses a Config model object which requires to have at least following functions:
      # - value = get(key, default)
      # - set(key, value)
      #
      # Setup keep end user data in memory. After setup, you HAVE to save them
      # If you are using Lorj::Account, use function ac_save
      # If you are using Lorj::Config, use function configSave
      #
      # * *Args* :
      #   - +ObjectType+ : Meta object type to query.
      #   - +Config+     : Optional. Hash containing list of data to use for updating.
      #
      # * *Returns* :
      #   Lorj::Data of type :object
      #
      # * *Raises* :
      #
      def Setup(sObjectType, sAccountName)
         # Loop in dependencies to get list of data object to setup
         raise Lorj::PrcError,new(), "Setup: '%s' not a valid object type." if Lorj::rhExist?(@@meta_obj, sObjectType) != 1

         hAskStep = Lorj::Default.get(:ask_step, :setup)
         aSetup = []
         hAskStep.each{ | value |
            aSetup << {
               :desc => value[:desc],
               :explanation => value[:explanation],
               :pre_step_handler => value[:pre_step_function],
               :order => [[]],
               :post_step_handler => value[:post_step_function]
            }

         }
         oInspectedObjects = []
         oInspectObj = [sObjectType]

         @oForjConfig.ac_load(sAccountName) if sAccountName

         Lorj.debug(2, "Setup is identifying account data to ask for '%s'" % sObjectType)
         while oInspectObj.length() >0
            # Identify data to ask
            # A data to ask is a data needs from an object type
            # which is declared in section of defaults.yaml
            # and is declared :account to true (in defaults.yaml or in process declaration - define_data)

            sObjectType = oInspectObj.pop
            sAsk_step = 0
            Lorj.debug(1, "Checking '%s'" % sObjectType)
            hTopParams = Lorj::rhGet(@@meta_obj,sObjectType, :params)
            if hTopParams[:keys].nil?
               Lorj.debug(1, "Warning! Object '%s' has no data/object needs. Check the process" % sObjectType)
               next
            end
            hTopParams[:keys].each { |sKeypath, hParams|
               oKeyPath = KeyPath.new(sKeypath)
               sKey = oKeyPath.sKey
               case hParams[:type]
                  when :data
                     hMeta = _get_meta_data(sKey)
                     next if hMeta.nil?
                     sAsk_step = hMeta[:ask_step] if Lorj::rhExist?(hMeta, :ask_step) == 1 and hMeta[:ask_step].is_a?(Fixnum)
                     Lorj.debug(3, "#{sKey} is part of setup step #{sAsk_step}")
                     aOrder = aSetup[sAsk_step][:order]

                     if oInspectedObjects.include?(sKey)
                        Lorj.debug(2, "#{sKey} is already asked. Ignored.")
                        next
                     end
                     if hMeta[:account].is_a?(TrueClass)
                        if not hMeta[:depends_on].is_a?(Array)
                           PrcLib.warning("'%s' depends_on definition have to be an array." % oKeyPath.sFullPath) unless hMeta[:depends_on].nil?
                           iLevel = 0
                           bFound = true
                        else
                           # Searching highest level from dependencies.
                           bFound = false
                           iLevel = 0
                           hMeta[:depends_on].each { |depend_key|
                              aOrder.each_index { |iCurLevel|
                                 if aOrder[iCurLevel].include?(depend_key)
                                    bFound = true
                                    iLevel = [iLevel, iCurLevel + 1].max
                                 end
                              }
                                 aOrder[iLevel] = [] if aOrder[iLevel].nil?
                           }
                        end
                        if bFound
                           if not aOrder[iLevel].include?(sKey)
                              if hMeta[:ask_sort].is_a?(Fixnum)
                                 iOrder = hMeta[:ask_sort]
                                 if aOrder[iLevel][iOrder].nil?
                                    aOrder[iLevel][iOrder] = sKey
                                 else
                                    aOrder[iLevel].insert(iOrder, sKey)
                                 end
                                 Lorj.debug(3, "S%s/L%s/O%s: '%s' added in setup list. " % [sAsk_step, iLevel, iOrder, sKey])
                              else
                                 aOrder[iLevel] << sKey
                                 Lorj.debug(3, "S%s/L%s/Last: '%s' added in setup list." % [sAsk_step, iLevel, sKey])
                              end
                           end
                        end
                        oInspectedObjects << sKey
                     else
                        Lorj.debug(2, "#{sKey} used by #{sObjectType} won't be asked during setup. :account = true not set.")
                     end
                  when :CloudObject
                     oInspectObj << sKey if not oInspectObj.include?(sKey) and not oInspectedObjects.include?(sKey)
               end
            }
            oInspectedObjects << sObjectType
         end
         Lorj.debug(2, "Setup check if needs to add unrelated data in the process")
         hAskStep.each_index{ | iStep |
            value = hAskStep[iStep]
            if Lorj::rhExist?(value, :add) == 1
               sKeysToAdd = Lorj::rhGet(value, :add)
               sKeysToAdd.each { | sKeyToAdd |
                  bFound = false
                  aSetup[iStep][:order].each_index { | iOrder |
                     sKeysToAsk = aSetup[iStep][:order][iOrder]
                     unless sKeysToAsk.index(sKeyToAdd).nil?
                        bFound = true
                        break
                     end
                  }
                  next if bFound
                  iLevel = 0
                  iOrder = aSetup[iStep][:order].length
                  iAtStep = iStep
                  hMeta = _get_meta_data(sKeyToAdd)
                  if Lorj::rhExist?(hMeta, :after) == 1
                     sAfterKeys = hMeta[:after]
                     sAfterKeys = [ sAfterKeys ] if not sAfterKeys.is_a?(Array)
                     sAfterKeys.each{ |sAfterKey |
                        bFound = false
                        aSetup.each_index { |iStepToCheck|
                           aSetup[iStepToCheck][:order].each_index { | iLevelToCheck |
                              sKeysToAsk = aSetup[iStepToCheck][:order][iLevelToCheck]
                              iOrderToCheck = sKeysToAsk.index(sAfterKey)
                              unless iOrderToCheck.nil?
                                 iAtStep = iStepToCheck if iStepToCheck > iAtStep
                                 iLevel = iLevelToCheck if iLevelToCheck > iLevel
                                 iOrder = iOrderToCheck + 1 if iOrderToCheck + 1 > iOrder
                                 bFound = true
                                 break
                              end
                           }
                        }
                     }
                  end
                  aSetup[iAtStep][:order][iLevel].insert(iOrder, sKeyToAdd)
                  Lorj.debug(3, "S%s/L%s/O%s: '%s' added in setup list at  position." % [iAtStep, iLevel, iOrder, sKeyToAdd])
               }
            end
         }

         Lorj.debug(2, "Setup will ask for :\n %s" % aSetup.to_yaml)

         PrcLib.info("Configuring account : '#{config[:account_name]}', provider '#{config[:provider_name]}'")

         # Ask for user input
         aSetup.each_index { | iStep |
            Lorj.debug(2, "Ask step %s:" % iStep)
            puts "%s%s%s" % [ANSI.bold, aSetup[iStep][:desc], ANSI.clear] unless aSetup[iStep][:desc].nil?
            puts "%s\n\n" % ANSI.yellow(aSetup[iStep][:explanation]) unless aSetup[iStep][:explanation].nil?
            aOrder = aSetup[iStep][:order]
            aOrder.each_index { | iIndex |
            Lorj.debug(2, "Ask order %s:" % iIndex)
               aOrder[iIndex].each { | sKey |
                  hParam = _get_meta_data(sKey)
                  hParam = {} if hParam.nil?

                  bOk = false

                  if hParam[:pre_step_function]
                     pProc = hParam[:pre_step_function]
                     bOk = not(@oForjProcess.method(pProc).call(sKey))
                  end


                  sDesc = "'%s' value" % sKey
                  puts "#{sKey}: %s" % [hParam[:explanation]] unless Lorj::rhGet(hParam, :explanation).nil?
                  sDesc = hParam[:desc] unless hParam[:desc].nil?
                  sDefault = @oForjConfig.get(sKey, hParam[:default_value])
                  rValidate = nil

                  rValidate = hParam[:validate] unless hParam[:validate].nil?
                  bRequired = (hParam[:required] == true)
                  while not bOk
                     bOk = true
                     if not hParam[:list_values].nil?
                        hValues = hParam[:list_values]
                        sObjectToLoad = hValues[:object]

                        bListStrict = (hValues[:validate] == :list_strict)

                        case hValues[:query_type]
                           when :controller_call
                              oObject = @ObjectData[sObjectToLoad, :ObjectData]
                              PrcLib.message("Loading #{sObjectToLoad}.")
                              oObject = Create(sObjectToLoad) if oObject.nil?
                              return nil if oObject.nil?
                              oParams = ObjectData.new
                              oParams.add(oObject)
                              oParams << hValues[:query_params]
                              raise Lorj::PrcError.new(), "#{sKey}: query_type => :controller_call requires missing :query_call declaration (Controller function)" if hValues[:query_call].nil?
                              pProc = hValues[:query_call]
                              begin
                                 aList = @oProvider.method(pProc).call(sObjectToLoad, oParams)
                              rescue => e
                                 raise Lorj::PrcError.new(), "Error during call of '%s':\n%s" % [pProc, e.message]
                              end
                           when :query_call
                              sQuery = {}
                              sQuery = hValues[:query_params] unless hValues[:query_params].nil?
                              PrcLib.message("Querying #{sObjectToLoad}.")
                              oObjectList = Query(sObjectToLoad, sQuery)
                              aList = []
                              oObjectList.each { | oElem |
                                 aList << oElem[hValues[:value]]
                              }
                              aList.sort!
                           when :process_call
                              raise Lorj::PrcError.new(), "#{sKey}: query_type => :process_call requires missing :query_call declaration (Provider function)" if hValues[:query_call].nil?
                              pProc = hValues[:query_call]
                              sObjectToLoad = hValues[:object]
                              oParams = ObjectData.new
                              oParams.add(oObject)
                              oParams << hValues[:query_params]
                              begin
                                 aList = @oForjProcess.method(pProc).call(sObjectToLoad, oParams)
                              rescue => e
                                 raise Lorj::PrcError.new(), "Error during call of '%s':\n%s" % [pProc, e.message]
                              end
                           else
                              raise Lorj::PrcError.new, "'%s' invalid. %s/list_values/values_type supports %s. " % [hValues[:values_type], sKey, [:provider_function]]
                        end
                        PrcLib.fatal(1, "%s requires a value from the '%s' query which is empty." % [sKey, sObjectToLoad])if aList.nil? and bListStrict
                        aList = [] if aList.nil?
                        if not bListStrict
                           aList << "other"
                        end
                        say("Enter %s" % ((sDefault.nil?)? sDesc : sDesc + " |%s|" % sDefault))
                        value = choose { | q |
                           q.choices(*aList)
                           q.default = sDefault if sDefault
                        }
                        if not bListStrict and value == "other"
                           value = _ask(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                        end
                     else
                        pValidateProc = hParam[:validate_function]
                        pAskProc = hParam[:ask_function]

                        if pAskProc.nil?
                           unless pValidateProc.nil?
                              value = _ask(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                              while not @oForjProcess.method(pValidateProc).call(value)
                                 value = _ask(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                              end
                           else
                              value = _ask(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                           end
                        else
                           unless pValidateProc.nil?
                              value = @oForjProcess.method(pAskProc).call(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                              while not @oForjProcess.method(pValidateProc).call(value)
                                 value = @oForjProcess.method(pAskProc).call(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                              end
                           else
                              value = @oForjProcess.method(pAskProc).call(sDesc, sDefault, rValidate, hParam[:encrypted], bRequired)
                           end
                        end
                     end

                     @oForjConfig.set(sKey, value)
                     if hParam[:post_step_function]
                        pProc = hParam[:post_step_function]
                        bOk = @oForjProcess.method(pProc).call()
                     end
                  end
               }
            }
         }
      end

      # Initialize Lorj BaseDefinition object

      def initialize(oForjConfig, oForjProcess, oForjProvider = nil)
         # Object Data object. Contains all loaded object data.
         # This object is used to build hParams as well.
         @ObjectData = ObjectData.new(true)
         #
         @RuntimeContext = {
            :oCurrentObj => nil
         }

         @oForjConfig = oForjConfig
         raise Lorj::PrcError.new(), "'%s' is not a valid ForjAccount or ForjConfig Object." % [oForjConfig.class] if not oForjConfig.is_a?(Lorj::Account) and not oForjConfig.is_a?(Lorj::Config)

         @oProvider = oForjProvider
         if oForjProvider
            raise Lorj::PrcError.new(), "'%s' is not a valid ForjProvider Object type." % [oForjProvider.class] if not oForjProvider.is_a?(BaseController)
         end

         @oForjProcess = oForjProcess
         raise Lorj::PrcError.new(), "'%s' is not a valid BaseProcess Object type." % [oForjProcess.class] if not oForjProcess.is_a?(BaseProcess)

         @oForjProcess.set_BaseObject(self)
      end

      # ------------------------------------------------------
      # Functions used by processes functions
      # ------------------------------------------------------
      # Ex: object.set_data(...)
      #     config


      # Function to manipulate the config object.
      # 2 kind of functions:
      # - set (key, value) and []=(key, value)
      #   From processes, you can set a runtime data with:
      #     config.set(key, value)
      #   OR
      #     config[key] = value
      #
      # - get (key, default) and [](key, default)
      #   default is an optional value.
      #   From processes, you can get a data (runtime/account/config.yaml or defaults.yaml) with:
      #     config.get(key)
      #   OR
      #     config[key]

      def config
         raise Lorj::PrcError.new(), "No config object loaded." if not @oForjConfig
         @oForjConfig
      end

      def format_query(sObjectType, oControlerObject, hQuery)
         {
            :object        => oControlerObject,
            :object_type   => :object_list,
            :list_type     => sObjectType,
            :list          => [],
            :query         => hQuery
         }
      end

      def format_object(sCloudObj, oMiscObject)
         return nil if not sCloudObj or not [String, Symbol].include?(sCloudObj.class)

         sCloudObj = sCloudObj.to_sym if sCloudObj.class == String

         oCoreObject = {
            :object_type => sCloudObj,
            :attrs => {},
            :object => oMiscObject,
         }
      end

      def get_data_metadata(sKey)
         _get_meta_data(sKey)
      end

      # Before doing a query, mapping fields
      # Transform Object query field to Provider query Fields
      def query_map(sCloudObj, hParams)
         return nil if not sCloudObj or not [String, Symbol].include?(sCloudObj.class)
         return {} if not hParams

         sCloudObj = sCloudObj.to_sym if sCloudObj.class == String

         hReturn = {}
         hMap = Lorj::rhGet(@@meta_obj, sCloudObj, :query_mapping)
         hParams.each { |key, value|
            oKeyPath = KeyPath.new(key)
            sKeyPath = oKeyPath.sFullPath
            raise Lorj::PrcError.new(), "Forj query field '%s.%s' not defined by class '%s'.\n"  % [sCloudObj, oKeyPath.sKey, self.class ] +
               "#{ANSI.bold}ACTION REQUIRED#{ANSI.clear}:\n" +
               "Missing data model 'def_attribute' or 'def_query_attribute' for '%s'??? Check the object '%s' data model." % [oKeyPath.sKey, sCloudObj] if not hMap.key?(oKeyPath.sFullPath)
            oMapPath = KeyPath.new(hMap[oKeyPath.sFullPath])
            hValueMapping = Lorj::rhGet(@@meta_obj, sCloudObj, :value_mapping, sKeyPath)
            if hValueMapping
               raise Lorj::PrcError.new(), "'%s.%s': No value mapping for '%s'" % [sCloudObj, oKeyPath.sKey, value] if Lorj::rhExist?(hValueMapping, value) != 1

               Lorj::rhSet(hReturn, hValueMapping[value], oMapPath.aTree)
            else
               Lorj::rhSet(hReturn, value, oMapPath.aTree)
            end
         }
         hReturn
      end

      # Obsolete. Used by the Process.
      # Ask controller get_attr to get a data
      # The result is the data of a defined data attribute.
      # If the value is normally mapped (value mapped), the value is
      # returned as a recognized data attribute value.
      def get_attr(oObject, key)

         raise Lorj::PrcError.new(), "'%s' is not a valid Object type. " % [oObject.class] if not oObject.is_a?(Hash) and Lorj::rhExist?(oObject, :object_type) != 1
         sCloudObj = oObject[:object_type]
         oKeyPath = KeyPath.new(key)
         raise Lorj::PrcError.new(), "'%s' key is not declared as data of '%s' CloudObject. You may need to add obj_needs..." % [oKeyPath.sKey, sCloudObj] if Lorj::rhExist?(@@meta_obj, sCloudObj, :returns, oKeyPath.sFullPath) != 3
         begin
            oMapPath = KeyPath.new Lorj::rhGet(@@meta_obj, sCloudObj, :returns, oKeyPath.sFullPath)
            hMap = oMapPath.sFullPath
            value = @oProvider.get_attr(get_cObject(oObject), hMap)

            hValueMapping = Lorj::rhGet(@@meta_obj, sCloudObj, :value_mapping, oKeyPath.sFullPath)

            if hValueMapping
               hValueMapping.each { | found_key, found_value |
                  if found_value == value
                     value = found_key
                     break
                  end
               }
            end
         rescue => e
            raise Lorj::PrcError.new(), "'%s.get_attr' fails to provide value of '%s'" % [oProvider.class, key]
         end
      end

      # Register the object to the internal @ObjectData instance
      def register(oObject, sObjectType = nil, sDataType = :object)
         if oObject.is_a?(Lorj::Data)
            oDataObject = oObject
         else
            raise Lorj::PrcError.new(), "Unable to register an object '%s' as Lorj::Data object if ObjectType is not given." % [ oObject.class ] if not sObjectType
            oDataObject = Lorj::Data.new(sDataType)
            oDataObject.set(oObject, sObjectType) { | sObjType, oControlerObject |
               _return_map(sObjType, oControlerObject)
            }
         end
         @ObjectData.add oDataObject
      end

      def DataObjects(sObjectType, *key)
         @ObjectData[sObjectType, key]
      end

      # get an attribute/object/... from an object.
      def get_data(oObj, *key)
         if oObj.is_a?(Hash) and oObj.key?(:object_type)
            oObjData = ObjectData.new
            oObjData << oObj
         else
            oObjData = @ObjectData
         end
         oObjData[oObj, *key]
      end

      #~ def hParams(sCloudObj, hParams)
         #~ aParams = _get_object_params(sCloudObj, ":ObjectData.hParams")
      #~ end

      def get_cObject(oObject)
         return nil if Lorj::rhExist?(oObject, :object) != 1
         Lorj::rhGet(oObject, :object)
      end

      # a Process can execute any kind of predefined controler task.
      # Those function build hParams with Provider compliant data (mapped)
      # Results are formatted as usual framework Data object and stored.
      def connect(sObjectType)

         hParams = _get_object_params(sObjectType, :create_e, :connect, true)
         oControlerObject = @oProvider.connect(sObjectType, hParams)
         oDataObject = Lorj::Data.new
         oDataObject.set(oControlerObject, sObjectType) { | sObjType, oObject |
            begin
               _return_map(sObjType, oObject)
            rescue => e
               raise Lorj::PrcError.new(), "connect %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }
         @ObjectData.add oDataObject
         oDataObject
      end

      def create(sObjectType)
         # The process ask the controller to create the object.
         # hParams have to be fully readable by the controller.
         hParams = _get_object_params(sObjectType, :create_e, :create, true)
         oControlerObject = @oProvider.create(sObjectType, hParams)
         oDataObject = Lorj::Data.new
         oDataObject.set(oControlerObject, sObjectType) { | sObjType, oObject |
            begin
               _return_map(sObjType, oObject)
            rescue => e
               raise Lorj::PrcError.new(), "create %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }
         @ObjectData.add oDataObject

         oDataObject
      end

      # The controller must return true to inform about the real deletion
      def delete(sObjectType)
         hParams = _get_object_params(sObjectType, :delete_e, :delete, true)
         raise Lorj::PrcError.new(), "delete Controller - %s: Object '%s' is not loaded." % [@oProvider.class, key] if not hParams.exist?(sObjectType)
         bState = @oProvider.delete(sObjectType, hParams)
         @ObjectData.delete(sObjectType) if bState
         bState
      end

      def get(sObjectType, sUniqId)

         hParams = _get_object_params(sObjectType, :get_e, :get, true)

         oControlerObject = @oProvider.get(sObjectType, sUniqId, hParams)
         oDataObject = Lorj::Data.new
         oDataObject.set(oControlerObject, sObjectType) { | sObjType, oObject |
            begin
               _return_map(sObjType, oObject)
            rescue => e
               raise Lorj::PrcError.new(), "get %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }
         @ObjectData.add oDataObject

         oDataObject
      end

      def query(sObjectType, hQuery)

         # Check if we can re-use a previous query
         oList = @ObjectData[:query, sObjectType]
         unless oList.nil?
            if oList[:query] == hQuery
               Lorj.debug(3, "Using Object '%s' query cache : %s" % [sObjectType, hQuery])
               return oList
            end
         end


         hParams = _get_object_params(sObjectType, :query_e, :query, true)
         sProviderQuery = query_map(sObjectType, hQuery)

         oControlerObject = @oProvider.query(sObjectType, sProviderQuery, hParams)

         oDataObjects = Lorj::Data.new :list
         oDataObjects.set(oControlerObject, sObjectType, hQuery) { | sObjType, key |
            begin
               _return_map(sObjType, key)
            rescue => e
               raise Lorj::PrcError.new(), "query %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }

         Lorj.debug(2, "Object %s - queried. Found %s object(s)." % [sObjectType, oDataObjects.length()])

         @ObjectData.add oDataObjects
         oDataObjects
      end

      def update(sObjectType)
         # Need to detect data updated and update the Controler object with the controler

         hParams = _get_object_params(sObjectType, :update_e, :update, true)

         oObject = @ObjectData[sObjectType, :ObjectData]
         oControlerObject = oObject[:object]

         bUpdated = false
         oObject[:attrs].each { |key, value |
            oKeyPath = KeyPath.new(key)
            oMapPath = KeyPath.new Lorj::rhGet(@@meta_obj, sObjectType, :returns, oKeyPath.sFullPath)
            old_value = @oProvider.get_attr(oControlerObject, oMapPath.aTree)
            if value != old_value
               bUpdated = true
               @oProvider.set_attr(oControlerObject, oMapPath.aTree, value)
               Lorj.debug(2, "%s.%s - Updating: %s = %s (old : %s)" % [@oForjProcess.class, sObjectType, key, value, old_value])
            end
         }

         bDone = @oProvider.update(sObjectType, oObject, hParams) if bUpdated

         raise Lorj::PrcError.new, "Controller function 'update' must return True or False. Class returned: '%s'" % bDone.class if not [TrueClass, FalseClass].include?(bDone.class)

         Lorj.debug(1, "%s.%s - updated." % [@oForjProcess.class, sObjectType]) if bDone
         oObject.set(oControlerObject, sObjectType) { | sObjType, oObject |
            begin
               _return_map(sObjType, oObject)
            rescue => e
               raise Lorj::PrcError.new(), "update %s.%s : %s" % [@oForjProcess.class, sObjectType, e.message]
            end
         }
         bDone
      end


      private

      # -------------------------------------------------------------------------
      # Functions available for Process to communicate with the controler Object
      # -------------------------------------------------------------------------
      def cloud_obj_requires(sCloudObj, res = {})
         aCaller = caller
         aCaller.pop

         return res if @ObjectData.exist?(sCloudObj)
         #~ return res if Lorj::rhExist?(@CloudData, sCloudObj) == 1

         Lorj::rhGet(@@meta_obj,sCloudObj, :params).each { |key, hParams|
            case hParams[:type]
               when :data
                  if  hParams.key?(:array)
                     hParams[:array].each{ | aElem |
                        aElem = aElem.clone
                        aElem.pop # Do not go until last level, as used to loop next.
                        Lorj::rhGet(hParams, aElem).each { | subkey, hSubParam |
                           next if aElem.length == 0 and [:array, :type].include?(subkey)
                           if hSubParams[:required] and @oForjConfig.get(subkey).nil?
                              res[subkey] = hSubParams
                           end
                        }
                     }
                  else
                     if hParams[:required] and @oForjConfig.get(key).nil?
                        res[key] = hParams
                     end
                  end
               when :CloudObject
                  #~ if hParams[:required] and Lorj::rhExist?(@CloudData, sCloudObj) != 1
                  if hParams[:required] and not @ObjectData.exist?(sCloudObj)
                     res[key] = hParams
                     cloud_obj_requires(key, res)
                  end
            end
         }
         res
      end

      def get_object(sCloudObj)
         #~ return nil if Lorj::rhExist?(@CloudData, sCloudObj) != 1
         return nil if not @ObjectData.exist?(sCloudObj)
         @ObjectData[sCloudObj, :ObjectData]
         #~ Lorj::rhGet(@CloudData, sCloudObj)
      end

      def objectExist?(sCloudObj)
         @ObjectData.exist?(sCloudObj)
         #~ (Lorj::rhExist?(@CloudData, sCloudObj) != 1)
      end

      def get_forjKey(oCloudData, key)
         return nil if not @ObjectData.exist?(sCloudObj)
         @ObjectData[sCloudObj, :attrs, key]
         #~ return nil if Lorj::rhExist?(oCloudData, sCloudObj) != 1
         #~ Lorj::rhGet(oCloudData, sCloudObj, :attrs, key)
      end
   end
end
