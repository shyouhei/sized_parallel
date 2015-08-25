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

class Test002Pool < Test::Unit::TestCase
  Pool = SizedParallel::Pool # saves my keyboard

  def test_class
    assert { SizedParallel::Pool.is_a? Class }
  end

  def test_new
    assert { Pool.new.is_a? Pool }
    assert { Pool.new(4).is_a? Pool }
    assert_raise(TypeError) { Pool.new(4.5) }
    assert_raise(TypeError) { Pool.new(Time.now) }
    assert_raise(TypeError) { Pool.new("4") }
    assert_raise(ArgumentError) { Pool.new(-1) }
    assert_raise(ArgumentError) { Pool.new(0) }
    assert_nothing_raised { Pool.new(1) }
  end

  def test_new_with_block
    # In case a method _ignores_ a block,  which is the default behaviour for a
    # ruby method, no exception  happens.  So if you want to  check sanity of a
    # block-accepting  method,  you  should intentionally  raise  an  exception
    # inside, then  check to see  if that exception  _you_ raised is  seen, not
    # others.
    assert_raise_message(/foo/) { Pool.new { raise 'foo' } }
    assert_raise_message(/foo/) { Pool.new(4) { raise 'foo' } }

    assert_nothing_raised {
      Pool.new {|this|
        assert { this.is_a? Pool }
      }
    }

    assert_nothing_raised {
      Pool.new(4) {|this|
        assert { this.is_a? Pool }
      }
    }
  end

  def test_process
    Pool.new {|this|
      assert_raise(ArgumentError) { this.process }
      assert_nothing_raised { this.process { false } }
      assert_nothing_raised { this.process -> { true } { false } }
      assert_nothing_raised {
        1024.times { |i|
          this.process(i) { |j|
            j
          }
        }
      }
    }
  end

  def test_process_exception_handling
    Pool.new {|this|
      assert_nothing_raised { this.process { raise 'foo' }.wait }
      assert_raise_message(/foo/) {
        this.process {
          Thread.abort_on_exception = true
          raise 'foo'
        }.wait
      }
    }
  end

  def test_wait
    Pool.new {|this|
      assert_nothing_raised { this.wait }
      assert_nothing_raised { this.wait.wait.wait }
      assert_nothing_raised { this.process { false }.wait }
      assert_nothing_raised { this.process(-> { true }) { false }.wait }
      assert_nothing_raised {
        1024.times { |i|
          this.process(i) { |j|
            j
          }
        }
        this.wait
      }
    }
  end

  def test_thread_resusability
    # This test _can_ fail, because there is no guarantee that all
    # allocated threads are used fairly; there can be inter-thread
    # scheduing problem and it's hard to solve from ruby level.
    a = []
    Pool.new(3) {|this|
      1023.times {
        this.process {
          a |= [ Thread.current ]
          Thread.pass
        }
      }
    }
    assert { a.size == 3 }
  end
end
