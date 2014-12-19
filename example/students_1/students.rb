#!/usr/bin/env ruby

$APP_PATH = File.dirname(__FILE__)
require 'lorj'

# If you want to see what is happening in the framework, uncomment debug settings.
# PrcLib.level = Logger::DEBUG # Printed out to your console.
# PrcLib.core_level = 3 # framework debug levels.

# Initialize the framework
hProcesses = [File.join($APP_PATH, 'process', 'Students.rb')]

oStudentCore = Lorj::Core.new(nil, hProcesses)

# Ask the framework to create the object student 'Robert Redford'
oStudentCore.Create(:student, student_name: 'Robert Redford')
