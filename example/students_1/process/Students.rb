# Students process
class StudentsProcess
  def create_student(sObjectType, hParams)
    puts "Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name]]
    # If you prefer to print out to the log system instead:
    # PrcLib::debug("Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name] ])
  end
end

# Declaring your data model and handlers.
class Lorj::BaseDefinition
  # We need to define the student object and the handler to use while we need to create it.
  define_obj(:student,

             create_e: :create_student # The function to call in the class Students
             )

  obj_needs :data,         :student_name,         for: [:create_e]
end
