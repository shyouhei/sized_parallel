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

require_relative 'test_helper'
require 'sized_parallel'

class Test004Complicated < Test::Unit::TestCase
  def test_pooled_threads_are_too_much
    # If there are more threads than jobs, those orphan threads die immediately
    # and NOT EVERYONE.
    SizedParallel.new(32) { |sp|
      obj = Object.new
      sp.start(obj) { |x|
        sleep 1
        next x
      }.then { |x|
        assert { x == obj }
      }
    }
  end

  def test_pooled_threads_are_too_few
    # No parallelizm shall work.
    SizedParallel.new(1) { |sp|
      obj = Object.new
      sp.start(obj) { |x|
        sleep 1
        next x
      }.then { |x|
        assert { x == obj }
      }
    }
  end

  def test_long_chain
    ary = []
    SizedParallel.new { |sp|
      car = sp.start {
        next ary
      }

      cdr = car
      128.times {|i|
        cdr = cdr.then { ary << i }
      }
    }
    assert { ary.size == 128 }
  end

  def test_execution_order
    # 17 and 29 are pairwise disjoint below.
    ary = []
    m = Mutex.new
    SizedParallel.new(17) { |sp|
      tmp = []
      29.times { |i|
        tmp << Thread.start(i) {|j|
          sp.start(j) { |k|
            m.synchronize { ary << [k, 1] }
            next k
          }.then { |k|
            m.synchronize { ary << [k, 2] }
            next k
          }.then { |k|
            m.synchronize { ary << [k, 3] }
            next k
          }.then { |k|
            m.synchronize { ary << [k, 4] }
            next k
          }.then { |k|
            m.synchronize { ary << [k, 5] }        
          }
        }
      }
      tmp.each(&:join)
    }
    assert { ary.length == 29 * 5 }
    # For all pairs in  ary, [x, y] should appear BEFORE [x,  y+1] BUT [x+1, y]
    # can be in advance.
    ary.each_with_index do |(x, y), i|
      next if y == 1
      assert { ary.index([x, y - 1]) < i }
    end
  end
end
