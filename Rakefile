#! /your/favourite/path/to/rake
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

require 'rubygems'
require 'bundler/setup'
Bundler.setup :development
require 'rake'
require 'yard'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

YARD::Rake::YardocTask.new
RuboCop::RakeTask.new

task default: :test
task spec: :test
desc "run tests"
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb'] - ['test/test_helper.rb']
end

desc "a la rails console"
task :console do
  require_relative 'lib/sized_parallel'
  require 'irb'
  require 'irb/completion'
  ARGV.clear
  IRB.start
end
task c: :console

desc "pry console"
task :pry do
  require_relative 'lib/sized_parallel'
  require 'pry'
  ARGV.clear
  Pry.start
end
