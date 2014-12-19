# Students process
class StudentsProcess
  def create_student(sObjectType, hParams)
    PrcLib.state ("Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name]])

    oObject = controller_create(sObjectType)
    fail "Student '%s' not created." % hParams[:student_name] if oObject.nil?
    PrcLib.info ("'%s': '%s' created with id %s" % [sObjectType, hParams[:student_name],  oObject[:id]])
    oObject
  end
end

# Declaring your data model and handlers.
class Lorj::BaseDefinition
  # We need to define the student object and the handler to use while we need to create it.
  define_obj(:student,

             create_e: :create_student,   # The function to call in the class Students
             query_e: :controller_query, # We use predefined call to the controller query
             get_e: :controller_get,   # We use predefined call to the controller get
             delete_e: :controller_delete # We use predefined call to the controller delete
             )

  obj_needs :data,         :student_name,         for: [:create_e], mapping: :name
end
