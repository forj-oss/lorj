#!/usr/bin/env ruby
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

# This script works in ruby 1.8

require 'lorj'

#  require 'ruby-debug'
#  Debugger.start

# Class to test encryted data.
class Test < Lorj::BaseDefinition
  def initialize(core)
    @core = core
  end

  def self.def_internal(name)
    spec_name = 's' + name

    # To call the function identified internally with 'spec' prefix
    define_method(spec_name) do |*p|
      send(name, *p)
    end
  end

  # Internal function to test.
  def_internal '_get_encrypt_key'
  def_internal '_get_encrypted_value'

  def run
    puts 'Checking imported account...'
    tests = [:account_key_test]
    tests.each { |t| send(t) if self.class.private_method_defined?(t) }
  end

  private

  def account_key_test
    entr = _get_encrypt_key
    data = @core.config['credentials#account_key']

    res = _get_encrypted_value(data, entr, 'credentials#account_key')

    test_state(!res.nil?, 'Account key', data)
  end

  def test_state(res, test, value)
    test_str = "#{test}. (#{value})"
    if res
      puts "OK   : #{test_str}"
    else
      puts "FAIL : #{test_str}"
    end
  end
end

# TODO: Implement Thor instead of ARGV use.
if ARGV.length <= 3
  puts "Syntax is 'ruby #{__FILE__}' <LorjRef> <key> <CloudDataFile> "\
       "[<AccountName[@provider]>]\n"\
       "where:\n"\
       "LorjRef       : Lorj application struture to use. \n"\
       '                Format: <datapath[|<pdatapath>]>='\
       "<process>[@<libToLoad]\n"\
       "  datapath    : Path where Lorj store data.\n"\
       "  pdatapath   : Path where Lorj store private data.\n"\
       "  process     : Lorj process name to load. It can be a path to a\n"\
       "                process file.\n"\
       "  libToLoad   : Optional. Ruby library containing The Lorj process.\n"\
       "                If missing, it will try to load a lib named \n"\
       "                lorj_<process>\n"\
       'key           : Base64 encoded key. Used to decrypt the <CloudDataFi'\
       "le>\n"\
       "CloudDataFile : File containing the Lorj cloud data to import.\n"\
       "AccountName   : Account name to import. Usually the CloudDataFile\n"\
       "                have the name embedded and may use that one except\n"\
       '                if you force it.'
  exit
end

ref, key_encoded, data_file, account = ARGV

ref_found = ref.match(/^(.*(\|(.*))?)=(.*?)(@(.*))?$/)

unless ref_found
  puts 'LorjRef must be formatted as : <datapath[|<pdatapath>]>='\
       '<process>[@<libToLoad]'
  exit 1
end

datapath = ref_found[1]
pdatapath = datapath
pdatapath = ref_found[3] unless ref_found[3].nil?
process = ref_found[4]

if ref_found[6].nil?
  lib_name = "lorj_#{process}"
else
  lib_name = ref_found[6]
end

unless File.exist?(data_file)
  puts "#{data_file} doesn't exist. Please check and retry."
  exit 1
end

if key_encoded == ''
  puts 'The key provided is empty. Please check and retry.'
  exit 1
end

begin
  require lib_name
rescue => e
  puts "Warning! Unable to load RubyGem '#{lib_name}'.\n#{e}"
end

if key_encoded.length % 4 > 0
  key_encoded += '=' * (4 - (key_encoded.length % 4))
end

begin
  key_yaml = Base64.strict_decode64(key_encoded)
rescue => e
  puts "Reading Base64 Key: '#{key_encoded}' is not a valid encoded Base64"\
       " data.\n#{e}\nPlease check and retry."
  exit 1
end

begin
  entr = YAML.load(key_yaml)
rescue => e
  puts "Reading Base64 Key: '#{key_yaml}' is not a valid YAML data.\n#{e}\n"\
       'Please check and retry.'
  exit 1
else
  unless entr.key?(:iv) && entr.key?(:key) && entr.key?(:salt)
    puts 'Reading Base64 Key: Invalid key. Missing entropy data.'
    exit 1
  end
end

name, controller = account.split('@') unless account.nil?

PrcLib.data_path = datapath
PrcLib.pdata_path = pdatapath

keypath = Lorj::KeyPath.new(process)

processes = [{ :process_module => keypath.key_tree }]

core = Lorj::Core.new(Lorj::Account.new, processes)

data = File.read(data_file).strip

core.account_import(entr, data, name, controller)

puts 'Import done.'

unless core.config.ac_save
  puts 'Issue during configuration saved.'
  exit 1
end
puts "Config imported and saved in #{core.config['account#name']}"

Test.new(core).run

puts 'Import process done.'
