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

require 'thread'

# This is just a Struct with no actual methods but {#then}.
class SizedParallel::Task

  # @param pool  [Pool]  a pool.
  def initialize pool
    # (Surprisingly  enough) this  class  does _not_  hold  the task  procedure
    # itself.  Instead  the environment that  is enclosed into a  closure holds
    # this instance, and that does the job.  This seems tricky, but a task is a
    # closure by  nature so a closure  holds a task  and not vice versa  is the
    # right way.
    raise ArgumentError, 'no block given' unless defined? yield
    @p = pool
    @q = Queue.new
    pool.process do
      begin
        (*val) = yield self
      ensure
        @q.enq val
      end
    end
  end

  # Creates another Task,  that "depends" self.  The returned  task waits until
  # self finishes.
  # @yieldparam  [...] *argv the return value of previous task.
  # @yieldreturn [...]       passed to the next task.
  # @return      [Task]      a new task that does the given block.
  def then
    raise ArgumentError, 'no block given' unless defined? yield
    Thread.pass
    self.class.new @p do
      v = @q.deq
      next yield(*v)
    end
  end
end
