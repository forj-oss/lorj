# encoding: UTF-8
#
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

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task' unless RUBY_VERSION.match(/1\.8/)
require 'rdoc/task'
require 'json'

task :default => [:lint, :spec]

desc 'Run all specs (locally + docker).'
task :spec => [:spec_local, :spec18]

desc 'Run acceptance test (docker - specs).'
task :acceptance => [:spec18]

desc 'Generate lorj documentation'
RDoc::Task.new do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_files.include('README.md', 'lib', 'example', 'bin')
end

desc 'Run the specs.'
RSpec::Core::RakeTask.new(:spec_local) do |t|
  t.pattern = 'spec/*_spec.rb'
  t.rspec_opts = '-f doc'
end

if RUBY_VERSION.match(/1\.8/)
  desc 'no lint with ruby 1.8'
  task :lint
else
  desc 'Run RuboCop on the project'
  RuboCop::RakeTask.new(:lint) do |task|
    task.formatters = ['progress']
    task.verbose = true
    task.fail_on_error = true
  end
end

# rubocop: disable Style/SpecialGlobalVars

desc 'Run spec with docker for ruby 1.8'
task :spec18 do
  begin
    `docker`
  rescue
    puts 'Unable to run spec against ruby 1.8: docker not found'
  else
    cmd = 'build/build_with_proxy.sh -t ruby/1.8'
    puts "Running #{cmd}"
    system(cmd)
    image_id = `docker images ruby/1.8`.split("\n")[1].split[2]
    res = `docker inspect -f '{{json .}}' lorj`
    c_img = ''
    c_img = JSON.parse(res)['Image'][0..11] if $?.exitstatus == 0

    if $?.exitstatus == 0 && image_id == c_img && ENV['RSPEC_DEBUG'].nil?
      system('docker start -ai lorj')
    else
      `docker rm lorj` if $?.exitstatus == 0
      cmd = "docker run -e RSPEC_DEBUG=#{ENV['RSPEC_DEBUG']} --name "\
             'lorj -v "$(pwd):/src" -w /src ruby/1.8 /tmp/bundle.sh'
      puts "Running #{cmd}"
      system(cmd)
    end
  end
end

task :build => [:lint, :spec]
