#! /your/favourite/path/to/ruby
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

require 'etc'
require 'thread'

# SizedParallel is a `make -j4` -like experience.  When you do
#
#     sp = SizedParallel.new
#     1024.times do |i|
#        sp.start { printf("1: %d\n", i); sleep 1 }
#          .then  { printf("2: %d\n", i); sleep 1 }
#          .then  { printf("3: %d\n", i); sleep 1 }
#     end
#     sp.wait
#
# You  see  bunch  of  things  run  in parallel,  but  all  the  2s  are  after
# corresponding 1s, and 3s are after 2s.
class SizedParallel

  # Creates a set of execution.  If a  block is given, evaluates that block and
  # wait for self, i.e:
  #
  #     SizedParallel.new do |sp|
  #       ...
  #     end
  #
  # is a shorthand for:
  #
  #     sp = SizedParallel.new
  #     begin
  #       ...
  #     ensure
  #       sp.wait
  #     end
  #
  # @param      [Integer]       n  parallelizm.
  # @yieldparam [SizedParallel] self
  def initialize n = Etc.nprocessors
    if defined? yield then
      Pool.new n do |p|
        @p = p
        yield self
      end
    else
      @p = Pool.new n
    end
  end

  # Starts a series of execution.
  # @note       (see Pool#process)
  # @param      (see Pool#process)
  # @yieldparam (see Pool#process)
  # @return     [Task]             a `then`-able.
  # @raise      [ArgumentError]    when no block is given.
  def start *argv
    raise ArgumentError, 'no block given' unless defined? yield
    Task.new @p do
      yield(*argv)
    end
  end

  # Waits for tasks.  It blocks until all the jobs are done.
  # @return [SizedParallel] self
  def wait
    @p.wait
    return self
  end
end

require_relative 'sized_parallel/version'
require_relative 'sized_parallel/pool'
require_relative 'sized_parallel/task'
