#!/usr/bin/env ruby

$APP_PATH = File.dirname(__FILE__)
require 'lorj'
require 'ansi'

# If you want to see what is happening in the framework, uncomment debug settings.
#PrcLib.level = Logger::DEBUG # Printed out to your console.
#PrcLib.core_level = 3 # framework debug levels. (0 to 5)

# Load global Config

# This object is used to provide configuration data to lorj

# The config search is:
# 1- Application defaults (defaults.yaml) - Not defined by default. update the following line and create defaults.yaml
# PrcLib.app_defaults = $APP_PATH
# 2- Local defaults (~/.<Application Name>/config.yaml) - <Application Name> is 'Lorj' by default. Can be updated with following line.
# PrcLib.app_name = 'myapp'
# 3 - runtime. Those variables are set, with oConfig[key] = value

oConfig = Lorj::Config.new() # Use Simple Config Object

# You can use an account object, which add an extra account level
# between runtime and config.yaml/app default
# oConfig = Lorj::Account.new('MyAccount')


# Initialize the framework
# Use students process
hProcesses = [ File.join($APP_PATH, 'process', 'students.rb')]
# Use yaml_students controller
sController = File.join($APP_PATH, 'controller', 'yaml_students.rb')
oStudentCore = Lorj::Core.new( oConfig, hProcesses, sController )

# This kind of connection_string should be part of an Account Data.
# So, we won't need to set this config.
# But you can imagine to set at runtime this config as well.
oConfig[:connection_string] = "/tmp/students.yaml"

# Note that we have commented the next line.
# oStudentCore.Create(:connection, :connection_string => "/tmp/students.yaml")
# This call is not required, as the framework has all the information to create
# the connection, at the first time this connection is required.
# ie, while starting to create a student.


# Set the student name to use
oConfig[:student_name] = "Robert Redford"

# Ask the framework to create the object student 'Robert Redford'
puts ANSI.bold("Create 1st student:")
oStudentCore.Create(:student)
# The connection is made because creating a student requires
# the object :connection. (See example/students_4/controller/yaml_students.rb, around line 70)

puts ANSI.bold("Create 2nd student:")
# Want to create a duplicated student 'Robert Redford'?
oStudentCore.Create(:student)
# Because the process ensure that there is no duplicate, this won't create duplicates

# We can set runtime configuration instantly from the Create call
# The following line :
puts ANSI.bold("Create 3rd student:")
oStudentCore.Create(:student, {:student_name => "Anthony Hopkins"})
# replaced the following :
# oConfig[:student_name] = "Anthony Hopkins"
# oStudentCore.Create(:student)

# Let's query students named "Robert Redford"
puts ANSI.bold("Querying students as 'Robert Redford':")
oStudents = oStudentCore.Query(:student, { :name => "Robert Redford" } )

puts "%s students found for '%s':" % [oStudents.length, "Robert Redford"]

oStudents.each { | oStudent |
   puts "%s: %s" % [oStudent[:id], oStudent[:name]]
}

# let's check the get function, who is the ID 2?
puts ANSI.bold("Who is student ID 2?")
oStudent = oStudentCore.Get(:student, 2)

puts "\nThe student ID 2 is %s" % oStudent[:name] unless oStudent.nil?
puts "\nThe student ID 2 doesn't exist." if oStudent.nil?

puts ANSI.bold("Create mistake")
oStudentCore.Create(:student, {
   :student_name => "Anthony Mistake",
   :course => 'what ever you want!!!'
})

# The query logic has been implemented directly in the process,
# so now, any kind of  controller Delete will have the same behavior...
puts ANSI.bold("Remove mistake")
hQuery = { :name => "Anthony Mistake"}
oStudentCore.Delete(:student, :query => hQuery)

puts ANSI.bold("List of students for 'Art Drama':")
puts oStudentCore.Query(:student, { :course => "Art Drama"}).to_a

puts ANSI.bold("Deleted students:")
puts oStudentCore.Query(:student,{ :status => :removed}).to_a
