# Lorj

**Lorj** library is a process/controller framework used to build inter-operable process functions against any kind of controllers.

It has been designed to provide cloud agnostics feature to forj command line tool and FORJ maestro gardener.

This framework helps to design any kind of solution which needs to maintain a generic process logic, fully controller independant.

## Implementations examples

### How forj cli implemented Lorj lib

This case was implemented by forj cli to implement services on any kind of cloud solution.

forj cli needs to build a forge (collection of servers) on a cloud.
It requires to ensure that everything is in place (network properly configured if not create it, router exists, flavors available, etc.) to create the first server.

For **Lorj**, how to create the forge and ensure that everything is in place is the **process**.<br>
And then how to manipulate the cloud (get the network, create the network, create the server, etc...) is the **controller**. <br>
Usually, the controller is a wrapper to an API, which do actions, like 'create server'.

Then, at runtime, while changing the controller to aws, hpcloud, openstack, or even docker or decker, forj cli process will be still the same.
It simplifies forj cli extension, by just adding new controller to support more clouds providers.

Currently, forj cli has implemented *hpcloud* and *openstack* providers, using *fog*. Docker controller is under development.

## Getting started

As playing by example is better than a long discussion, let's start playing with a simple example.

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'lorj'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lorj


### Write your first Lorj code

#### Student database management example context:

Imagine you have an API code which today manages students database in yaml format.<br>
We have written a small class to illustrate this API. (See examples/yaml_students/yaml_students.rb)

This api has everything to create, query, edit and delete a student in a yaml file.

Using Lorj, you want to propose multiple storage system (not only using the yaml format) to your application, by supporting several storage systems, like mysql DB.

next, we will write 3 versions, which will introduce how to deal with process and controllers:

* version 1:
     Writing your first 'do nothing' process, with no controller.

* version 2:
     Complete the process to have create/query/get and delete capability, with mock controller.
     The mock controller is basically a controller keeping data in memory.

* version 3:
     Update the version 2 to fully implement the example of an yaml_student API.

     The main is `examples/yaml_students/students.rb`<BR>
     The API is `examples/yaml_students/yaml_students.rb`

We have created a full example version 4 which implements some interesting way to improve your code available in `examples/students_4/`

---
#### Writing student version 1

**NOTE**: following example is available in `examples/students_1/`

First of all, write your first main. Create a file `example.rb` with following content:

##### File `students.rb`

``` ruby
    #!/usr/bin/env ruby

    $APP_PATH = File.dirname(__FILE__)
    require 'lorj'

    # If you want to see what is happening in the framework, uncomment debug settings.
    # PrcLib.level = Logger::DEBUG # Printed out to your console.
    # PrcLib.core_level = 3 # framework debug levels.

    # Initialize the framework
    hProcesses = [ File.join($APP_PATH, 'process', 'students.rb')]
    oStudentCore = Lorj::Core.new( nil, hProcesses)

    # Ask the framework to create the object student 'Robert Redford'
    oStudentCore.Create(:student, {:student_name => "Robert Redford"})
```

##### File `process/Students.rb`

Now, let's write our first process. We are going to create a file Students.rb under a sub-directory 'process'.

``` ruby
  # Students process
  class StudentsProcess
    def create_student(sObjectType, hParams)
        puts "Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name] ]

        # If you prefer to print out to the log system instead:
        # PrcLib::debug("Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name] ])
    end
  end

  # Declaring your data model and handlers.
  class Lorj::BaseDefinition

     # We need to define the student object and the handler to use while we need to create it.
     define_obj(:student,
     {
        :create_e => :create_student # The function to call in the class Students
     })

     obj_needs    :data,         :student_name,        { :for => [:create_e] }

  end
```

What did we wrote?

* We defined a *StudentsProcess* class

    This is the core of your process. It describes how to handle the object requested. The data to use is available in `hParams`.

    **IMPORTANT !!** There is no reference to any files or Database connection.

    **NOTE**: The framework requires you to define a class name composed by the name of the process and 'Process'.
    Here, it is 'Students' + **'Process'**


* We declared the data model and the process handlers with declaration in *Lorj::BaseDefinition* class.

     In short, we declared `:student` object, which needs `:student_name` at creation step.

     **NOTE** Implicitly, the framework consider that the object contains at least 2 data fields, :id (should be unique) and :name (string)


Currently, this model do nothing except printing out.

#####typical output

    $ example/students_1/students.rb
    WARNING: PrcLib.app_defaults is not set. Application defaults won't be loaded.
    Running creation process for object 'student' = 'Robert Redford'
    WARNING: 'create_student' has returned no data for object Lorj::Data 'student'!

There is 2 warnings.

* **PrcLib.app_defaults** represents the application name. It is used to keep your application configuration data in ~/.{PrcLib.app_defaults}/ directory. Defining this data in your main, will eliminate this warning.
* **create_student** function in your process has returned nothing. while lorj is called to create an object, it assumes to get the object data created. Lorj keep those data in a cache. In this example, **create_student** returned nil, and lorj raise a warning about that.

---
#### Writing student version 2

**NOTE**: following example is available in `examples/students_2/`

lorj comes with a `:mock` controller. This one is really basic. It keep data in an Hash in MockController class.<br>
In this example, we add create/get/query/delete capability in the process and use the `:mock` controller to store the data.

##### File `process/Students.rb`

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
  obj_needs    :data,         :student_name,        { :for => [:create_e], :mapping => :name }

  end
```

Update the handler `create_student`:

``` ruby
  def create_student(sObjectType, hParams)
      PrcLib::state ("Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name] ])

      oObject = controler.create(sObjectType)
      raise "Student '%s' not created." % hParams[:student_name] if oObject.nil?
      PrcLib::info ("'%s': '%s' created with id %s" % [sObjectType, hParams[:student_name],  oObject[:id]])
      oObject
  end
```



##### File `students.rb`
The update your main and add those lines. In the following, we create 3 students, while 2 are duplicated.

``` ruby

    # Want to create a duplicated student 'Robert Redford'?
    oStudentCore.Create(:student)
    # no problem. The key is the key in the Mock controller array.

    oStudentCore.Create(:student, :student_name => "Anthony Hopkins")

    # Let's create a third different student.
    oStudents = oStudentCore.Query(:student, { :name => "Robert Redford" } )

    puts "%s students found" % oStudents.length

    oStudents.each { | oStudent |
       puts "%s: %s" % [oStudent[:id], oStudent[:name]]
    }

    # let's check the get function, who is the ID 2?
    oStudent = oStudentCore.Get(:student, 2)

    puts "The student ID 2 is %s" % oStudent[:name]

```

#####typical output:

    $ example/students_2/students.rb
    WARNING: PrcLib.app_defaults is not set. Application defaults won't be loaded.
    2 students found
    0: Robert Redford
    1: Robert Redford
    The student ID 2 is Anthony Hopkins


Cool! But everything is in memory! We would like to write this in a file.
Writing our controller, means that the process should not be updated anymore!

Let's move to the most interesting version. Translate an API example to use lorj!

#### Writing student version 3

**NOTE**: following example is available in `examples/students_3/`

A controller is like a wrapper to an API which offer what we would like to use to save our yaml file.<br>
We already have a running API that we can use to manage students in yaml format.

This API is written in `examples/yaml_students/yaml_students.rb`. <br>
`examples/yaml_students/students.rb` is the main program calling the api and create a basic yaml file example in `/tmp/students.yaml`

You can review the main 'students.rb' to see the simple code.

In short, this code do:

* create 3 students, only if they do not exists
* remove a wrong one
* Identify list of students on a specific training
* Identify students removed.

We will do the same thing with lorj.

Using lorj means you are going to split your code in different pieces. You will need to integrate a layer between your main and the API. This layer is composed by :

* 1 generic data model
* 1 generic process handlers
* 1 controller definition - expanding the data model for our Student yaml API
* 1 controller code - wrapper to the student yaml API.

So, we are going to update following files:

* students.rb - Adapt the main to do the same as original students script using the student yaml API.
* process/students.rb - Student data model - Update the process data model.
* process/students.rb - Student process handler - Update student process handlers.
* controller/yaml_students.rb - controller definition - Extend the student data model with controller definition.
* controller/yaml_students_controller.rb - controller code - Write the student yaml API wrapper.

First of all, let me re-visit the :student data model, then the student process handlers.

We need to define more parameters for handlers, and define the data model.

##### File `process/students.rb`
Update the class Lorj::BaseDefinition, and the data model and handlers parameters.

*The generic data model:*

``` ruby
    class Lorj::BaseDefinition
       define_obj(:student,
       {
          :create_e => :create_student,   # The function to call in the class Students
          :query_e  => :controller_query, # We use predefined call to the controller query
          :delete_e => :controller_delete # We use predefined call to the controller delete
       })

       # obj_needs is used to declare parameters to pass to handlers.
       # :for indicates those parameters to be passed to create_e handler only.
       # Those data (or objects) will be collected and passed to the process handler as hParams.

       obj_needs   :data,   :student_name,          { :for => [:create_e] }

       # By default, all data are required.
       # You can set it as optional. Your process will need to deal with this optional data.
       obj_needs_optional
       obj_needs   :data,   :first_name,            { :for => [:create_e] }
       obj_needs   :data,   :last_name,             { :for => [:create_e] }
       obj_needs   :data,   :course  # Note that in this model, the training is renamed as course.
                                     # the controller will need to map it to 'training'.

       # def_attribute defines the data model.
       # The process will be able to access those data
       # if the controller has mapped them.
       # For the exercice, I have changed the name of the training field to become :course instead.
       def_attribute :course
       # Same thing for the student name. instead of 'name', we defined :student_name
       def_attribute :student_name
       def_attribute :first_name
       def_attribute :last_name
       def_attribute :status

       undefine_attribute :name
   end
```

Then, update the process to manage student duplicates. Update function `create_student`

*The generic process handlers:*

``` ruby
    class StudentsProcess
       def create_student(sObjectType, hParams)
          PrcLib::state ("Running creation process for object '%s' = '%s'" % [sObjectType, hParams[:student_name] ])

          # config object is a reference to runtime/config data.
          oList = Query(sObjectType, {:name => hParams[:student_name]})
          case oList.length
             when 0
                oObject = controller_create(sObjectType)
                raise "Student '%s' not created." % hParams[:student_name] if oObject.nil?
                PrcLib::info ("'%s': '%s' created with id %s" % [sObjectType, hParams[:student_name],  oObject[:id]])
             when 1
                oObject = oList[0]
                PrcLib::info ("'%s': '%s' loaded with id %s" % [sObjectType, hParams[:student_name],  oObject[:id]])
             else
                oObject = oList[0]
                PrcLib::warning("More than one student named '%s' is found: %s records. Selecting the first one and removing duplicates." % [hParams[:student_name], oList.length])
                iCount = 0
                oList[1..-1].each { | elem |
                   register(elem)
                   iCount += controller_delete(sObjectType)
                }
                PrcLib::info ("'%s': %s duplicated '%s' removed. First loaded with id %s" % [sObjectType, iCount, hParams[:student_name],  oObject[:id]])
          end
          oObject
       end
    end
```

Here you see that we query, check list, create if missing, or delete if duplicates found.
You can run it now, as we still uses mock controller. It should work.

##### File `students.rb`

Now, let's update the main to be close to what we have on `examples/yaml_students/students.rb`

This is a simple basic translation of `examples/yaml_students/students.rb`

``` ruby
    #!/usr/bin/env ruby

    $APP_PATH = File.dirname(__FILE__)
    require 'lorj'
    require 'ansi'

    # If you want to see what is happening in the framework, uncomment debug settings.
    # PrcLib.level = Logger::DEBUG # Printed out to your console.
    # PrcLib.core_level = 3 # framework debug levels. Values between 0 to 5.

    # Initialize the framework
    hProcesses = [ File.join($APP_PATH, 'process', 'students.rb')]

    # You can try with mock instead. uncomment the next line and comment 2 next lines.
    #~ oStudentCore = Lorj::Core.new( nil, hProcesses, :mock)
    oStudentCore = Lorj::Core.new( nil, hProcesses, File.join($APP_PATH, 'controller', 'yaml_students.rb'))
    oStudentCore.Create(:connection, :connection_string => "/tmp/students.yaml")

    puts ANSI.bold("Create 1st student:")

    oStudentCore.Create(:student, {
       student_name:  'Robert Redford',
       first_name:    'Robert',
       last_name:     'Redford',
       course:        'Art Comedy'
    })

    puts ANSI.bold("Create 2nd student:")
    oStudentCore.Create(:student, {
       student_name:  'Anthony Hopkins',
       first_name:    'Anthony',
       last_name:     'Hopkins',
       course:        'Art Drama'
    })

    puts ANSI.bold("Create 3rd student:")
    oStudentCore.Create(:student, {
       student_name: "Marilyn Monroe",
       first_name:   'Marilyn',
       last_name:    'Monroe',
       course:       'Art Drama'
    })

    puts ANSI.bold("Create mistake")
    oStudentCore.Create(:student, {
       :student_name  => "Anthony Mistake",
       :first_name    => 'Anthony',
       :last_name     => 'Mistake',
       :course        => 'what ever you want!!!'
    })

    # Because the last student was the mistake one, we can directly delete it.
    # Usually, we use get instead.
    puts ANSI.bold("Remove mistake")
    oStudentCore.Delete(:student)

    puts ANSI.bold("List of students for 'Art Drama':")
    puts oStudentCore.Query(:student, { :course => "Art Drama"}).to_a

    puts ANSI.bold("Deleted students:")
    puts oStudentCore.Query(:student,{ :status => :removed}).to_a
```

We have reproduced the code. Note that there is no if while creating. It is embedded in the create_student process.

##### File `controller/yaml_students_controller.rb`

We need to write the controller part, now. As I said, it is like a wrapper. Let's have a look:

*The controller code:*

``` ruby
    # declare yaml student API to the controller
    cur_file = File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), "..", "yaml_students", 'yaml_students.rb'))
    require cur_file

    # The controller is a combination of 2 elements:
    # - Controller class
    #   Code which will interfere with the external API.
    #
    #   The file name must respect the name of the class. 1st letter already capitalized and letter after _ is capitalized.
    #   file: my_code.rb => needs to create MyCodeController class
    #
    # - Definition class
    #   This class declare any kind of mapping or additional fields to consider.
    #   Additionnal fields are unknow by the process. So, those fields will needs to be setup before.
    #
    #   file name convention is identical than controller class.
    #   file: my_code.rb => needs to create MyCode class

    class YamlStudentsController
       def initialize()
          @@valid_attributes = [:name, :first_name, :last_name, :id, :status, :training]
       end

       def create(sObjectType, hParams)
          case sObjectType
             when :connection
                required?(hParams, :hdata, :file_name)
                YamlSchool.new(hParams[:hdata, :file_name])
             when :student
                required?(hParams, :connection)
                required?(hParams, :student_name)

                # We use the hdata built by the lorj. See set_hdata in the next file.
                hParams[:connection].create_student(hParams[:student_name], hParams[:hdata])
             else
                Error "'%s' is not a valid object for 'create'" % sObjectType
          end
       end

       # This function return a collection which have to provide:
       # functions: [], length, each
       def query(sObjectType, sQuery, hParams)
          case sObjectType
             when :student
                required?(hParams, :connection)

                hParams[:connection].query_student(sQuery)
             else
                Error "'%s' is not a valid object for 'create'" % sObjectType
          end

       end

       def delete(sObjectType, hParams)
          case sObjectType
             when :student
                required?(hParams, :connection)

                hParams[:connection].delete_student(hParams[sObjectType][:id])
             else
                Error "'%s' is not a valid object for 'create'" % sObjectType
          end
       end

       def get_attr(oControlerObject, key)
          # This controller function read the data and
          # extract the information requested by the framework.
          # Those data will be mapped to the process data model.
          # The key is an array, to get data from a level tree.
          # [data_l1, data_l2, data_l3] => should retrieve data from structure
          #                                like data[ data_l2 [ data_l3 ] ]
          begin
             attributes = oControlerObject
             raise "get_attr: attribute '%s' is unknown in '%s'. Valid one are : '%s'",
                   key[0], oControlerObject.class,
                   @@valid_attributes unless @@valid_attributes.include?(key[0])
             Lorj::rh_get(attributes, key)
          rescue => e
             Error "get_attr: Unable to map '%s'. %s" % [key, e.message]
          end
       end

       def set_attr(oControlerObject, key, value)
          begin
             attributes = oControlerObject
             raise "set_attr: attribute '%s' is unknown in '%s'. Valid one are : '%s'",
                   key[0], oControlerObject.class,
                   @@valid_attributes  unless @@valid_attributes.include?(key[0])
             Lorj::rh_set(attributes, value, key)
          rescue => e
             Error "set_attr: Unable to map '%s' on '%s'" % [key, sObjectType]
          end
       end

       def update(sObjectType, oObject, hParams)
          case sObjectType
             when :student
                required?(hParams, :connection)

                hParams[:connection].update_student(oObject)
             else
                Error "'%s' is not a valid object for 'create'" % sObjectType
          end
       end

    end

```
In short, we wrap:

- create with YamlSchool.create_student
- delete with YamlSchool.delete_student
- query with YamlSchool.query_student
- update with YamlSchool.update_student

And we have defined 2 additional functions

- get_attr: to extract data from a YamlSchool Object
- set_attr: to set data to a YamlSchool Object

##### File `controller/yaml_students.rb`

And we need to write some mapping stuff to the controller. We have to add this

*The controller definition:*

``` ruby
    class YamlStudents
       # This is a new object which is known by the controller only.
       # Used to open the yaml file. Generically, I named it :connection.
       # But this can be any name you want. Only the controller will deal with it.
       define_obj(:connection,{
        :create_e => :controller_create # Nothing complex to do. So, simply call the controller create.
       })

       obj_needs   :data,   :connection_string,  :mapping => :file_name
       undefine_attribute :id    # Do not return any predefined ID
       undefine_attribute :name  # Do not return any predefined NAME

       # The student model have to be expanded.
       define_obj(:student)
       # It requires to create a connection to the data, ie opening the yaml file.
       # So, before working with the :student object, the controller requires a connection
       # This connection will be loaded in the memory and provided to the controller
       # when needed.
       obj_needs   :CloudObject,              :connection

       # To simplify controller wrapper, we use hdata built by lorj, and passed to the API
       # This hdata is a hash containing mapped data, thanks to set_hdata.
       set_hdata :first_name
       set_hdata :last_name
       # Instead of 'course', the yaml API uses 'training'
       set_hdata :course, :mapping => :training

       get_attr_mapping :course, :training
       # instead of 'student_name', the yaml API uses 'name'
       get_attr_mapping :student_name, :name

       # This controller will know how to manage a student file with those data.
       # But note that the file can have a lot of more data than what the process
       # usually manage. It is up to you to increase your process to manage more data.
       # Then each controller may need to define mapping fields.
    end
```

That's it!

#####typical output:
    $ example/students_3/students.rb
    WARNING: PrcLib.app_defaults is not set. Application defaults won't be loaded.
    Create 1st student:
    Create 2nd student:
    Create 3rd student:
    Create mistake
    Student created '{:id=>3, :course=>"what ever you want!!!", :student_name=>"Anthony Mistake", :first_name=>"Anthony", :last_name=>"Mistake", :status=>:active}'
    Remove mistake
    Wrong student to remove: 3 = Anthony Mistake
    List of students for 'Art Drama':
    {:id=>1, :course=>"Art Drama", :student_name=>"Anthony Hopkins", :first_name=>"Anthony", :last_name=>"Hopkins", :status=>:active}
    {:id=>2, :course=>"Art Drama", :student_name=>"Marilyn Monroe", :first_name=>"Marilyn", :last_name=>"Monroe", :status=>:active}
    Deleted students:
    {:id=>3, :course=>"what ever you want!!!", :student_name=>"Anthony Mistake", :first_name=>"Anthony", :last_name=>"Mistake", :status=>:removed}

## What next?

Check the code in the `examples/students_3/`. It provides a little more than is written here.

In short, it introduces the usage of Lorj::Config, before initializing Lorj::Core.

## next features

lorj provides 2 differents configuration class.

* Lorj::Config  - Basic config systems. Data are retrieved in **application defaults**, then **local config**, then **runtime**.
* Lorj::Account - Based on Lorj::Config, it introduces an **account** file, between **local config** and **runtime**.
* Logging system - Based on logger. A log file contains all data until debug. It prints to the console only data specified by PrcLib::.level
* lorj.setup - This function works with Lorj::Account. Thanks an application data definition (defaults.yaml), lorj ask the user information to build an account. Those data will be loaded and used by your process/controller flow.

For details, see API documentation.

# Contributing to Lorj

We welcome all types of contributions.  Checkout our website (http://docs.forj.io/en/latest/dev/contribute.html)
to start hacking on Lorj or Forj.  Also join us in our community (https://www.forj.io/community/) to help grow and foster Lorj and Forj for your development today!


#License:

Lorj lib is licensed under the Apache License, Version 2.0.  See LICENSE for full license text.
