# encoding: UTF-8

# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# In this version 4, The process will ensure a student is created only if
# missing and remove duplicates.

process_path = File.dirname(__FILE__)

# Define model

lorj_objects = %w(students)

lorj_objects.each do |name|
  require File.join(process_path, 'students', 'code', name + '.rb')
  require File.join(process_path, 'students', 'definition', name + '.rb')
end
