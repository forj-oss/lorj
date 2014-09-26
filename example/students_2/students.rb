#!/usr/bin/env ruby

$APP_PATH = File.dirname(__FILE__)
require 'lorj'

# If you want to see what is happening in the framework, uncomment debug settings.
# PrcLib.level = Logger::DEBUG # Printed out to your console.
# PrcLib.core_level = 3 # framework debug levels.

# Initialize the framework
hProcesses = [ File.join($APP_PATH, 'process', 'Students.rb')]

oStudentCore = Lorj::Core.new( nil, hProcesses, :mock)

# Ask the framework to create the object student 'Robert Redford'
oStudentCore.Create(:student, :student_name => "Robert Redford")

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
