# Students process
class StudentsProcess
  def create_student(sObjectType, hParams)
    PrcLib.state ("Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name]])

    aStudentName = hParams[:student_name].split(' ')
    # config object is a reference to runtime/config data.
    config[:first_name] = aStudentName[0]
    config[:last_name] = aStudentName[1]

    oList = Query(sObjectType, name: hParams[:student_name])
    case oList.length
       when 0
         oObject = controller_create(sObjectType)
         fail "Student '%s' not created." % hParams[:student_name] if oObject.nil?
         PrcLib.info ("'%s': '%s' created with id %s" % [sObjectType, hParams[:student_name],  oObject[:id]])
       when 1
         oObject = oList[0]
         PrcLib.info ("'%s': '%s' loaded with id %s" % [sObjectType, hParams[:student_name],  oObject[:id]])
       else
         oObject = oList[0]
         PrcLib.warning("More than one student named '%s' is found: %s records. Selecting the first one and removing duplicates." % [hParams[:student_name], oList.length])
         iCount = 0
         oList[1..-1].each do | elem |
           register(elem)
           iCount += controller_delete(sObjectType)
         end
         PrcLib.info ("'%s': %s duplicated '%s' removed. First loaded with id %s" % [sObjectType, iCount, hParams[:student_name],  oObject[:id]])
    end
    oObject
  end

  def query_student(sObjectType, sQuery, _hParams)
    PrcLib.state ("Running query process for object '%s' with query '%s'" % [sObjectType, sQuery])

    oObjects = controller_query(sObjectType, sQuery)
    fail 'Query error.' if oObjects.nil?

    PrcLib.info ("'%s': Queried. %s records found." % [sObjectType, oObjects.length])
    oObjects
  end

  def get_student(sObjectType, sId, _hParams)
    PrcLib.state ("Running get process for object '%s' with ID %s" % [sObjectType, sId])

    oObject = controller_get(sObjectType, sId)
    PrcLib.debug('No ID %s found.' % sId) if oObject.nil?

    oObject
  end

  def delete_student(sObjectType, hParams)
    Error 'Unable to delete students, if at least one student is not loaded, or query not defined.' if !hParams.exist?(:student) && !hParams.exist?(:query)

    # This student deletion process supports 2 modes:
    # - Delete from a query field (:query hParams)
    # - Delete the latest loaded student.

    if hParams.exist?(:query)
      result = Query(sObjectType, hParams[:query])
      if result.length > 0
        result.each do | student |
          puts 'Student to remove: %s = %s' % [student[:id], student[:name]]
          register(student)
          controller_delete(:student)
          PrcLib.info ("'%s:%s' student removed" % [student[:id], student[:name]])
        end
      end
    else
      controller_delete(:student)
    end
  end
end

# Declaring your data model and handlers.
class Lorj::BaseDefinition
  # We need to define the student object and the handler to use while we need to create it.
  define_obj(:student,

             create_e: :create_student, # The function to call in the class Students
             query_e: :query_student,
             delete_e: :delete_student,
             get_e: :get_student
             )

  # All obj_needs will be collected and passed to the process handler as hParams.
  # Data required to create a student
  obj_needs :data,   :student_name,          for: [:create_e]

  # Data optional for any kind of event
  obj_needs_optional
  obj_needs :data,   :query,                 for: [:delete_e]
  obj_needs :data,   :first_name
  obj_needs :data,   :last_name
  obj_needs :data,   :course

  # Define Data a student object needs to take care.
  # The controller should map it if needed (if the value exists)
  # But it can also add some extra attributes not predefined by the process.
  # Usually, the process should ignore it.
  # But if it detect it, the process should be careful with this data
  # which are really specific to only one controller and may break the controller agnostic capability.
  def_attribute :course
  def_attribute :first_name
  def_attribute :last_name
  def_attribute :name
  def_attribute :status
end

class Lorj::BaseDefinition
end
