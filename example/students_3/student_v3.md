# Writing student version 3

The power of lorj is to keep the GENERIC process as is, and be able to create a
controller replacing simply mock by another one.
In this example, we will use a yaml_students API in the new controller.

This API is written in `examples/yaml_students/yaml_students.rb`.

A controller is like a wrapper to an API which offer what we would like to use
to save our yaml file. And that's globally, what we are going to do.

First of all, we would like to inform lorj that we are going to use a different
controller, to be written in controller/yaml_students.rb

Let's change the student_core object creation.

## File `students.rb`
``` ruby
processes = [File.join(app_path, 'process', 'students.rb')]
# now we changed from mock to our own controller, located in
controller = File.join(app_path, 'controller', 'yaml_students.rb')

processes = []
processes << { :process_path => File.join(app_path, 'process', 'students.rb'),
               :controller_path => File.join(app_path, 'controller', 'yaml_students.rb') }

student_core = Lorj::Core.new(nil, processes)
```

Now, let's write the controller file.

The controller contains 2 elements:
* controller definition
* controller code

lorj will load automatically 'controller/yaml_students.rb' and expect to find
the controller definition and code.

* The Controller definition have to be written in a class named: YamlStudents
  lorj automatically creates a class derived from Lorj::BaseDefinition, and
  expect the file to define this class.

  So, you will need to write something like:

    class YamlStudents
    ...
    end

  Parent class (< BaseDefinition) is not required, as made by lorj itself.

  All declaration function we can use are defined in BaseDefinition.

  We will use the following:
  * define_obj         : Declare a meta object, and attach handlers
  * obj_needs          : Assign some data as parameters to handlers.
  * def_attr_mapping   : Define meta object attributes mapping.
  * undefine_attribute : Remove some predefined meta object attribute

  We use define_obj to define another meta object, to create the connection
  And we need to update the existing meta object 'student', to say that in the
  context of this controller we need a connection.
  This controller definition is executed on top of the process data model.

  Then, we need to map meta object attributes with the controller data attributes

  When the controller object has been created, lorj will need to get back data
  that was defined by the model. The Process uses this data to complete his task.
  So, the controller will need to help lorj to extract data from the controller
  object.

  This the role of a get_attr function.

  The usage of hdata (def_hdata) is a framework facility to build a Hash with
  all data attributes and values required by the controller object to work.

  Ok, let's write this controller, now:

  To simplify, we split this controller in 3 files.
  controller/yaml_students.rb declare, files and API to use
  controller/yaml_students_def.rb contains the controller definition
  controller/yaml_students_code.rb contains the controller code.

## controller/yaml_students.rb
``` ruby
# when you declare this controller with a file name, lorj expect this file
# to contains the controller code and the controller definition.
# The code have to be declared in a class which is named as follow from the file
# name:
#   1st letter is capitalized
#   A '_' followed by a letterif replaced by the capicatl letter.
#   Ex: my_code.rb => assume to declare MyCode class
#
# The controller code class is built from the source file name as explained
# below + 'Controller'
#  Ex: my_code.rb => assume to use MyCodeController for controller handlers and
#                    functions.
#
# The controller definition class is build from the file name only.
#  Ex: my_code.rb => assume to use MyCode for controller definition.


# This class describes how to process some actions, and will do everything prior
# this task to make it to work.

# declare yaml student API to the controller
cur_path = File.expand_path(File.dirname(__FILE__))
api_file = File.join(cur_path, '..', '..', 'yaml_students', 'yaml_students.rb'))

require api_file

# The controller is a combination of 2 elements:
# - Controller class
#   Code which will interfere with the external API.
#
controller_file = File.join(cur_path, 'yaml_students_code.rb')
require controller_file # Load controller mapping

# - Definition class
#   This class declare any kind of mapping or additional attributes to consider.
require File.join(cur_path, 'yaml_students_def.rb')
```

## controller/yaml_students_def.rb
``` ruby
class YamlStudents
  # This is a new object which is known by the controller only.
  # Used to open the yaml file. Generically, I named it :connection.
  # But this can be any name you want. Only the controller will deal with it.
  define_obj(:connection,
             # Nothing complex to do. So, simply call the controller create.
             :create_e => :controller_create
  )

  obj_needs :data,   :connection_string,  :mapping => :file_name
  undefine_attribute :id    # Do not return any predefined ID
  undefine_attribute :name  # Do not return any predefined NAME

  # The student meta object have to be expanded.
  define_obj(:student)
  # It requires to create a connection to the data, ie opening the yaml file.
  # So, before working with the :student object, the controller requires a
  # connection
  # This connection will be loaded in the memory and provided to the controller
  # when needed.
  # obj_needs :CloudObject update the :student object to requires a connection
  # before.
  obj_needs :CloudObject,              :connection

  # instead of 'student_name', the yaml API uses 'name' as key
  def_attr_mapping :student_name, :name
end
```

##### controller/yaml_students_code.rb
This file is code of the controller which will deal with the API to wrap and
adapt the Generic process object data model to become compatible with
the controller data model.

For example:
YamlStudent requires a first and last name at student creation time.
As the GENERIC process only know the student name, the controller will
need to determine how to get the first & last name from the student name.

The generic Get a student from a unique ID doesn't exist. So, we need to adapt this
to use a query :id => id instead.

Of course, simple case, like when lorj ask directly the controller to query, it will
simply call the query API function.

Ok, let's see the code, now:

``` ruby
# This file describe the controller code.
# The class name is determined by lorj.
# See controller/yaml_students.rb for details
class YamlStudentsController
  # controller wrapper
  def create(sObjectType, hParams)
    case sObjectType
    when :connection
      required?(hParams, :hdata, :file_name)
      YamlSchool.new(hParams[:hdata, :file_name])
    when :student
      required?(hParams, :connection)
      required?(hParams, :student_name)

      # Here, we adapt the lorj student data model  with the YamlStudent data model
      fields = hParams[:student_name].split(' ')
      fields.insert(0, 'first_name unknown') if fields.length == 1

      options = {:first_name => fields[0..-2].join(' '),
                 :last_name => fields[-1]}
      hParams[:connection].create_student(hParams[:student_name], options)
    else
      controller_error "'%s' is not a valid object for 'create'", sObjectType
    end
  end

  # This function return one element identified by an ID.
  # But get is not a YamlStudent API functions. But query help to use :id
  #
  # so we will do a query
  def get(sObjectType, id, hParams)
    case sObjectType
    when :student
      result = query(sObjectType, {:id => id}, hParams)
      return nil if result.length == 0
      result[0]
    else
      controller_error "'%s' is not a valid object for 'create'", sObjectType
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
      controller_error "'%s' is not a valid object for 'create'", sObjectType
    end
  end

  # This controller function read the data and
  # extract the information requested by the framework.
  # Those data will be mapped to the process data model.
  # The key is an array, to get data from a level tree.
  # [data_l1, data_l2, data_l3] => should retrieve data from structure like
  # data[ data_l2[ data_l3 ] ]
  def get_attr(oControlerObject, key)
    attributes = oControlerObject

    controller_error("get_attr: attribute '%s' is unknown in '%s'. "\
                     "Valid one are : '%s'",
                     key[0], oControlerObject.class,
                     valid_attributes) unless valid_attributes.include?(key[0])
    attributes.rh_get(key)
  rescue => e
    controller_error "get_attr: Unable to map '%s'. %s\n See %s",
                     key, e.message, e.backtrace[0]
  end

  private

  # These are the valid controller fields.
  def valid_attributes
    [:name, :first_name, :last_name, :id, :status, :training]
  end
end
```

If you execute the code, right now, runtime/connection_string will be missing...
One of possible way should be use save this an Account file, driven by the Account
Object.

In this example, we will simply set this data manually from the main.

## students.rb
We simply add a setting
``` ruby
[...]
# now we changed from mock to our own controller, located in
# controller/yaml_students.rb
#  student_core = Lorj::Core.new(nil, processes, :mock)
config = Lorj::Config.new
config[:connection_string] = '/tmp/students.yaml'
student_core = Lorj::Core.new(config, processes, controller)
[...]
```

# Playing around

If you want to move back to the mock controller, do it! You will still see that its keeps working.

You can enhance your main by selecting between mock or yaml_students

# next?

In next version, we will enhance the process to remove duplicates, and ensure
a student is created if it does not exist.

[Details is explained here](https://github.com/forj-oss/lorj/blob/master/example/students_4/student_v4.md)
