# Writing student version 1

**NOTE**: following example is available in `examples/students_1/`

First of all, write your first main. Create a file `example.rb` with following content:

## File `students.rb`

``` ruby
    #!/usr/bin/env ruby

    app_path = File.dirname(__FILE__)
    require 'lorj'

    # If you want to see what is happening in the framework, uncomment debug settings.
    # PrcLib.level = Logger::DEBUG # Printed out to your console.
    # PrcLib.core_level = 3 # framework debug levels.

    # Initialize the framework
    processes = [ File.join(app_path, 'process', 'students.rb')]
    processes = []
    processes << { :process_path => File.join(app_path, 'process', 'students.rb') }
    student_core = Lorj::Core.new( nil, processes)

    # Ask the framework to create the object student 'Robert Redford'
    student_core.create(:student, :student_name => "Robert Redford")
```

## File `process/students.rb`

Now, let's write our first process. We are going to create a file Students.rb
under a sub-directory 'process'.

``` ruby
  # Students process
  class StudentsProcess
    def create_student(object_type, params)
        puts format("Running creation process for object '%s' = '%s'",
                    object_type, params[:student_name] )

        # If you prefer to print out to the log system instead:
        # PrcLib::debug("Running creation process for object '%s' = '%s'",
        #               object_type, params[:student_name])
    end
  end

  # Declaring your data model and handlers.
  class Lorj::BaseDefinition

     # We need to define the student object and the handler to use while we need to create it.
     define_obj(:student,
        # The function to call in the class Students
        :create_e => :create_student
     )

     obj_needs :data, :student_name, :for => [:create_e]

  end
```

What did we wrote?

* We defined a *StudentsProcess* class

    This is the core of your GENERIC process. It describes how to handle the
    object requested. The data to use is available in `params`.

    **IMPORTANT !!** There is no reference to any files or Database connection.

    **NOTE**: Lorj framework requires you to define a class name composed by the
    name of the process and 'Process'.
    Here, it is 'Students' + **'Process'**


* We declared the data model and the process handlers with declaration in
  *Lorj::BaseDefinition* class.

    In short, we declared `:student` object, which needs `:student_name` at
    creation step.
    Currently the data model used here is very simple. There is one meta object
    with some limited attributes, handlers and parameters.
    The process itself is defined by several functions in StudentsProcess class
    with one handlers function declared by the data model.

    **NOTE** Implicitely, the framework consider that the object contains at
    least 2 attributes, :id (should be unique) and :name (string)

  We used the following feature provided by *Lorj::BaseDefinition*:
  * define_obj         : Declare a meta object, and attach handlers
  * obj_needs          : Assign some data as parameters.


Currently, this model do nothing except printing out.

##typical output

    $ example/students_1/students.rb
    WARNING: PrcLib.app_defaults is not set. Application defaults won't be loaded.
    Running creation process for object 'student' = 'Robert Redford'
    WARNING: 'create_student' has returned no data for object Lorj::Data 'student'!

There is 2 warnings.

* **PrcLib.app_defaults** represents the application name. It is used to keep
  your application configuration data in ~/.{PrcLib.app_defaults}/ directory.
  Defining this data in your main, will eliminate this warning.
* **create_student** function in your process has returned nothing. while lorj
  is called to create an object, it assumes to get the object data created. Lorj
  keep those data in a cache. In this example, **create_student** returned nil,
  and lorj raise a warning about that.

# what next? version 2

Complete the process to have create/query/get and delete capability, with mock controller.
The mock controller is basically a controller keeping data in memory.

[Details is explained here](https://github.com/forj-oss/lorj/blob/master/example/students_2/student_v2.md)
