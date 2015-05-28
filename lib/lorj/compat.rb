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

# Ruby 1.8 case
module Kernel
  # Defined in ruby 1.9
  unless defined?(__callee__)
    def __callee__
      caller[0] =~ /`([^']*)'/ && Regexp.last_match(1)
    end
  end
end

# Lorj Module Compatibility
module Lorj
  # BaseProcess Compatibility
  class BaseProcess
    # Adapt instance_methods
    def self._instance_methods
      # Ruby 1.8  : Object.instance_methods => Array of string
      # Ruby 1.9+ : Object.instance_methods => Array of symbol
      return instance_methods unless RUBY_VERSION.match(/1\.8/)

      instance_methods.collect(&:to_sym)
    end
  end
end

# Redefine string representation of Array
class Array
  def to_s
    '[' + map do |a|
      if a.is_a?(String)
        "\"#{a}\""
      elsif a.is_a?(Symbol)
        ":#{a}"
      else
        a.to_s
      end
    end.join(', ') + ']'
  end
end

# Redefine string representation of Hash
class Hash
  def to_s
    local = []
    each do |a, b|
      if a.is_a?(String)
        k = "\"#{a}\""
      elsif a.is_a?(Symbol)
        k = ":#{a}"
      else
        k = a.to_s
      end

      if b.is_a?(String)
        v = "\"#{b}\""
      elsif b.is_a?(Symbol)
        v = ":#{b}"
      else
        v = b.to_s
      end
      local << "#{k}=>#{v}"
    end
    '{' + local.join(', ') + '}'
  end
end

# Support for encode 64 without \n
module Base64
  # Returns the Base64-encoded version of +bin+.
  # This method complies with RFC 4648.
  # No line feeds are added.
  def strict_encode64(bin)
    [bin].pack('m0')
  end

  # Returns the Base64-decoded version of +str+.
  # This method complies with RFC 4648.
  # ArgumentError is raised if +str+ is incorrectly padded or contains
  # non-alphabet characters.  Note that CR or LF are also rejected.
  def strict_decode64(str)
    str.unpack('m0').first
  end
end
