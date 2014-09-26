#!/usr/bin/env ruby

$APP_PATH = File.dirname(__FILE__)
require 'lorj'
require 'ansi'

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
# oConfig = Lorj::Account.new('MyAccount') #


# If you want to see what is happening in the framework, uncomment debug settings.
# PrcLib.level = Logger::DEBUG # Printed out to your console.
# PrcLib.core_level = 3 # framework debug levels.

# Initialize the framework
hProcesses = [ File.join($APP_PATH, 'process', 'students.rb')]

#~ oStudentCore = Lorj::Core.new( oConfig, hProcesses, :mock)
oStudentCore = Lorj::Core.new( oConfig, hProcesses, File.join($APP_PATH, 'controller', 'yaml_students.rb'))

oStudentCore.Create(:connection, :connection_string => "/tmp/students.yaml")

puts ANSI.bold("Create 1st student:")

# Set the student name to use
# There is different way to set them... Those lines do the same using config object. Choose what you want.
oConfig.set(:first_name, 'Robert')
oConfig[:last_name]    = "Redford"
oConfig[:student_name] = "Robert Redford"
oConfig[:course]       = 'Art Comedy'

# Ask the framework to create the object student 'Robert Redford'
oStudentCore.Create(:student)

puts ANSI.bold("Create 2nd student:")
# We can set runtime configuration instantly from the Create call
# The following line :
oStudentCore.Create(:student, {
   student_name:  'Anthony Hopkins',
   first_name:    'Anthony',
   last_name:     'Hopkins',
   course:        'Art Drama'
})
# oConfig[:student_name] = "Anthony Hopkins"
# oConfig[:course] = "Art Drama"
# oStudentCore.Create(:student)

puts ANSI.bold("Create 3rd student:")
oStudentCore.Create(:student, {
   student_name: "Marilyn Monroe",
   first_name:   'Marilyn',
   last_name:    'Monroe',
   course:       'Art Drama'
})
# replaced the following :
# oConfig[:student_name] = "Anthony Hopkins"
# oStudentCore.Create(:student)

puts ANSI.bold("Create mistake")
oStudent = oStudentCore.Create(:student, {
   :student_name  => "Anthony Mistake",
   :first_name    => 'Anthony',
   :last_name     => 'Mistake',
   :course        => 'what ever you want!!!'
})

puts "Student created '%s'" % oStudent[:attrs]

# Because the last student was the mistake one, we can directly delete it.
# Usually, we use get instead.
puts ANSI.bold("Remove mistake")
oStudentCore.Delete(:student)
puts "Wrong student to remove: %s = %s" % [oStudent[:id], oStudent[:student_name]]

puts ANSI.bold("List of students for 'Art Drama':")
puts oStudentCore.Query(:student, { :course => "Art Drama"}).to_a

puts ANSI.bold("Deleted students:")
puts oStudentCore.Query(:student,{ :status => :removed}).to_a
