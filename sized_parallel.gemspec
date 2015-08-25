#! /your/favourite/path/to/gem
# -*- mode: ruby; coding: utf-8; indent-tabs-mode: nil; ruby-indent-level 2 -*-

# Copyright (c) 2015 Urabe, Shyouhei
#
# Permission is hereby granted, free of  charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction,  including without limitation the rights
# to use,  copy, modify,  merge, publish,  distribute, sublicense,  and/or sell
# copies  of the  Software,  and to  permit  persons to  whom  the Software  is
# furnished to do so, subject to the following conditions:
#
#         The above copyright notice and this permission notice shall be
#         included in all copies or substantial portions of the Software.
#
# THE SOFTWARE  IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY  KIND, EXPRESS OR
# IMPLIED,  INCLUDING BUT  NOT LIMITED  TO THE  WARRANTIES OF  MERCHANTABILITY,
# FITNESS FOR A  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO  EVENT SHALL THE
# AUTHORS  OR COPYRIGHT  HOLDERS  BE LIABLE  FOR ANY  CLAIM,  DAMAGES OR  OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# hack avoid namespace pollution
path            = File.expand_path 'lib/sized_parallel/version.rb', __dir__
content         = File.read path
version         = Module.new.module_eval <<-'end'
  SizedParallel = Module.new
  eval content, binding, path
end

Gem::Specification.new do |spec|
  spec.name          = "sized_parallel"
  spec.version       = version
  spec.authors       = ["Urabe, Shyouhei"]
  spec.email         = ["shyouhei@ruby-lang.org"]

  spec.summary       = '`make -j4` -like parallel execution'
  spec.homepage      = 'https://github.com/shyouhei/sized_parallel'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # This library requires Etc.nprocessors
  spec.required_ruby_version                 = '>= 2.2'
  spec.add_development_dependency 'bundler',   '~> 1.10'
  spec.add_development_dependency 'rake',      '~> 10.3'
  spec.add_development_dependency 'rdoc',      '~> 4.0'
  spec.add_development_dependency 'yard',      '~> 0.8'
  spec.add_development_dependency 'test-unit', '~> 3.0'
  spec.add_development_dependency 'simplecov', '>= 0'
  spec.add_development_dependency 'rubocop',   '~> 0.33'
  spec.add_development_dependency 'pry',       '~> 0.10'
end
