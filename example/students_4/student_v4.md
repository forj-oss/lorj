# Writing student version 4

In this example, we will enhance the process to remove duplicates, and ensure
a student is created if it does not exist.

We will also manage a little more data, like first name, last name and course.

And we will simplify the way to transmit those data to the controller using the
notion of hdata

First of all, let's add 4 additional fields to the process:
- student_name : Already configured.
- first_name   : The controller should be able to use a different first_name than
                 the one splitted from student_name. This is a new data.
- last_name    : list first_name, last_name can be set directly, instead of built
                 from student_name
- course       : This is a new field. We will consider that YamlStudent API know it
                 it as 'training' instead.

---
Before any update, compare to example 3, we have splitted `process/students.rb`
in several files, to make the distintion of 'definition' and 'code'

`process/students.rb` now contains:
```ruby
process_path = File.dirname(__FILE__)

# Define model

lorj_objects = %w(students)

lorj_objects.each do | name |
  require File.join(process_path, 'students', 'code', name + '.rb')
  require File.join(process_path, 'students', 'definition', name + '.rb')
end
```

The definition part is stored in:
`process/students/definition/students.rb` : Definition of student meta object.
                                            It contains the BaseDefinition code.
`process/students/code/students.rb`       : Student meta object code.
                                            It contains the StudentsProcess code.

---
Ok, To add new field to the process, update the process definition file:

```ruby
class Lorj::BaseDefinition # rubocop: disable Style/ClassAndModuleChildren
  # We need to define the student object and the handler to use while we need to
  # create it.
  define_obj(:student,
             # The function to call in the class Students
             :create_e => :create_student,
             # We use predefined call to the controller query
             :query_e => :controller_query,
             # We use predefined call to the controller get
             :get_e => :controller_get,
             # We use predefined call to the controller delete
             :delete_e => :controller_delete
             )

    # obj_needs is used to declare parameters to pass to handlers.
    # :for indicates those parameters to be passed to create_e handler only.
    # Those data (or objects) will be collected and passed to the process
    # handler as hParams.

    obj_needs :data,   :student_name,           :for => [:create_e]

    # By default, all data are required.
    # You can set it as optional. Your process will need to deal with this
    # optional data.
    obj_needs_optional
    obj_needs :data,   :first_name,             :for => [:create_e]
    obj_needs :data,   :last_name,              :for => [:create_e]
    obj_needs :data,   :course
    # Note that in this model, the training is renamed as course.

    # the controller will need to map it to 'training'.

    # def_attribute defines the data model.
    # The process will be able to access those data
    def_attribute :course
    def_attribute :student_name
    def_attribute :first_name
    def_attribute :last_name
    def_attribute :status

    undefine_attribute :name
end

```

The YamlStudent controller needs to be updated as well, because we considered
that training is the known field to use for course. We need to map it.

We will also instroduce the hdata.
hdata will ask lorj to create a Hash with the data set and already mapped.
So, instead of setting yourself an Hash that the API may requires to work,
you declare it and lorj will build it for you.

Then on the controller code, you will just need to refer to the :hdata.
We will see that in the next file.

Here in the controller definition, we just declared the hdata to map.

So, we need to update the controller definition file:

```ruby
class YamlStudents
  define_obj(:connection,
             # Nothing complex to do. So, simply call the controller create.
             :create_e => :controller_create
  )

  obj_needs :data,   :connection_string,  :mapping => :file_name
  undefine_attribute :id    # Do not return any predefined ID
  undefine_attribute :name  # Do not return any predefined NAME

  define_obj(:student)
  obj_needs :CloudObject, :connection

  # To simplify controller wrapper, we use hdata built by lorj, and passed to
  # the API
  # This hdata is a hash containing mapped data, thanks to def_hdata.
  def_hdata :first_name
  def_hdata :last_name
  # Instead of 'course', the yaml API uses 'training'
  def_hdata :course, :mapping => :training

  def_attr_mapping :course, :training
  # instead of 'student_name', the yaml API uses 'name'
  def_attr_mapping :student_name, :name
```

ok, cool.

Now we need to update the controller code because we did not implemented the
delete task in the controller. The process needs it to remove duplicates.

But we need also to accept first and last name data from the process.
We will move the split to the process as well.

Additionnally, we talked about 'hdata'. 'hdata' will simplify the code as well.

Let's see.
We need to change the create, as we are going to use hdata:

```ruby
  # controller wrapper
  def create(sObjectType, hParams)
    case sObjectType
    when :connection
      required?(hParams, :hdata, :file_name)
      YamlSchool.new(hParams[:hdata, :file_name])
    when :student
      required?(hParams, :connection)
      required?(hParams, :student_name)
      # We added test requiring :first_name and :last_name
      required?(hParams, :first_name)
      required?(hParams, :last_name)

      #We replaced the previous code with simply hParams[:hdata].
      hParams[:connection].create_student(hParams[:student_name],
                                          hParams[:hdata])
    else
      controller_error "'%s' is not a valid object for 'create'", sObjectType
    end
  end
```

And then add the delete function used by the process to remove duplicates.

```ruby
  # Example 4: Delete added to the controller.
  def delete(sObjectType, hParams)
    case sObjectType
    when :student
      required?(hParams, :connection)

      hParams[:connection].delete_student(hParams[sObjectType][:id])
    else
      Error format("'%s' is not a valid object for 'create'", sObjectType)
    end
  end
```
That's it.

As you saw, the main program has not changed. Just process and controllers.

In the next version is the full implementation of what `yaml_students/students.rb`
main basic tool running the YamlStudent API.
