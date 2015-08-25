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

# Very naive thread pool; does everything I need and nothing more.  It does not
# have any 'maximum'  or 'minimum' thread count but just  only one fixed number
# of threads,  allocated at once,  run in parallel, then  die when no  jobs are
# left.  You can reuse a pool after you once did something on it, though.
#
#     p = Pool.new
#     1024.times do |i|
#       p.process i do |j|
#         printf "%d\n", j
#         sleep 1
#       end
#     end
#     p.wait
#     p.process ...
#
class SizedParallel::Pool

  # Allocates a  new pool.  If  no block is given,  just returns a  new object.
  # Otherwise,  evaluates  the  given  block  with  expection  that  the  block
  # registers some jobs to it, and wait for them to finish, i.e:
  #
  #     Pool.new do |p|
  #       ...
  #     end
  #
  # is a shorthand for:
  #
  #     p = Pool.new
  #     begin
  #       ...
  #     ensure
  #       p.wait
  #     end
  #
  # @param      [Integer]      n parallelizm.
  # @yieldparam [Pool]         self
  # @raise      [ArgumetError] argument does not make sense.
  def initialize n = Etc.nprocessors
    case n when Integer then
      raise ArgumentError, 'negative number makes no sense' if n <= 0
      @n = n
      @q = Queue.new
    else
      raise TypeError, 'not a number'
    end

    return unless defined? yield

    begin
      yield self
    ensure
      wait
    end
  end

  # Registers what shall be done.
  #
  # @param      [...]  argv passed to the block verbatimly.
  # @yieldparam [...] *argv what was passed to the method.
  # @return     [self]
  #
  # @note what on  earth is the arguments that seems  completely useless?  Well
  #   the problem we are routing  is inter-thread variable scope.  For instance
  #   it is a WRONG idea to write code like this:
  #
  #       1024.times { |i| Thread.start { puts i } } # WRONG WRONG WROG WRONG
  #
  #   The code above behaves unexpectedly because the variable `i` is shared
  #   across threads, overwritten on occasions.  A valid usage is below:
  #
  #       1024.times { |i| Thread.start(i) {|j| puts j } }
  #       #                            ^^^  ^^^      ^
  #
  #   Note the use of newly introduced block-parameter `j`.  The same
  #   discussion goes exactly the same way to this method, because obviously
  #   this is a method that spawns (or reuses) a thread.
  def process *argv
    argv.unshift Proc.new
    @q.enq argv
    return self
  end

  # This method  blocks until all jobs  registered to finish.  Once  after this
  # method returns, the thread pool gets back to its initial state; ready to be
  # used again.
  # @return [self]
  def wait
    Array.new @n do
      Thread.start do
        failed = false
        begin
          while a = @q.deq(true) do
            # rubocop:disable Style/EmptyElse, Lint/RescueException
            begin
              job, *argv = *a
              job.call(*argv)
            rescue Exception => e
              if Thread.abort_on_exception then
                # When a  job ends abnormally, we  are not sure what  to do for
                # it.  Can't but just  follow abort_on_exception global setting
                # for now.  Should there be a better way.
                failed = e
                break
              else
                # silently ignore
              end
            end
            # rubocop:enable Style/EmptyElse, Lint/RescueException
          end
          # Reaching here indicates the abnormal end-of-job. tricky!
        rescue ThreadError
          # This  ThreadError can  only  come from  @q.deq,  indicates no  more
          # job(s) to call.
          Thread.exit
        end
        raise failed if failed
      end
    end.each(&:join)
    return self
  end
end
