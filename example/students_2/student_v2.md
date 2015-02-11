# Writing student version 2

**NOTE**: following example is available in `examples/students_2/`

lorj comes with a `:mock` controller. This one is really basic. It keeps data in an Hash in MockController class.<br>
In this example, we add create/get/query/delete capability in the process and use the `:mock` controller to store the data.

## File `process/Students.rb`

Add 3 handlers query_e, get_e and delete_e like this. Add the :mapping case as well.

``` ruby
class Lorj::BaseDefinition
   define_obj(:student,
   {
      :create_e => :create_student,   # The function to call in the class Students
      :query_e  => :controller_query, # We use predefined call to the controller query
      :get_e    => :controller_get,   # We use predefined call to the controller get
      :delete_e => :controller_delete # We use predefined call to the controller delete
   })

# Note about mapping. This is usually done by the controller. We will see this later.
obj_needs    :data, :student_name, :for => [:create_e], :mapping => :name

end
```

Update the handler `create_student`:

``` ruby
def create_student(sObjectType, hParams)
    PrcLib.state("Running creation process for object '%s' = '%s'",
                  sObjectType, hParams[:student_name])

    object = controler.create(sObjectType)
    fail "Student '%s' not created.",
          hParams[:student_name] if object.nil?
    PrcLib.info("'%s': '%s' created with id %s",
                sObjectType, hParams[:student_name],  object[:id])
    object
end
```



## File `students.rb`
The update your main and add those lines. In the following, we create 3 students, while 2 are duplicated.

``` ruby

  # Want to create a duplicated student 'Robert Redford'?
  student_core.create(:student, :student_name => "Robert Redford")
  # no problem. The key is the key in the Mock controller array.

  student_core.create(:student, :student_name => "Anthony Hopkins")

  # Let's create a third different student.
  students = student_core.query(:student, { :name => "Robert Redford" } )

  puts "%s students found" % students.length

  students.each { | a_student |
     puts "%s: %s" % [a_student[:id], a_student[:name]]
  }

  # let's check the get function, who is the ID 2?
  student = student_core.get(:student, 2)

  puts "The student ID 2 is %s" % student[:name]

```

##typical output:

    $ example/students_2/students.rb
    WARNING: PrcLib.app_defaults is not set. Application defaults won't be loaded.
    2 students found
    0: Robert Redford
    1: Robert Redford
    The student ID 2 is Anthony Hopkins


Cool! But everything is in memory! We would like to write this in a file.
Writing our controller, means that the process should not be updated anymore!

Let's move to the most interesting version. Integrate an API example in lorj!

# Next?

[Details is explained here](https://github.com/forj-oss/lorj/blob/master/example/students_3/student_v3.md)
