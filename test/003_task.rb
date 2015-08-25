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
require 'thread'
require 'sized_parallel'

class Test003Task < Test::Unit::TestCase
  Task = SizedParallel::Task # saves my keyboard

  def setup
    @pool = SizedParallel::Pool.new
  end

  def test_class
    assert { SizedParallel::Task.is_a? Class }
  end

  def test_new
    assert_raise(ArgumentError) { Task.new }
    assert_raise(ArgumentError) { Task.new @pool }
    assert_raise(ArgumentError) { Task.new @pool, 'garbage' }
    assert_nothing_raised { Task.new(@pool) { raise 'foo' } }
  end

  def test_then
    this = Task.new @pool do |that|
      assert { this == that }
      next 1
    end
    assert_raise(ArgumentError) { this.then }
    this.then { |*argv|
      assert { argv == [ 1 ] }
      next 2
    }.then { |*argv|
      assert { argv == [ 2 ] }
      next 3
    }
    @pool.wait
  end

  def test_then_inter_dependency
    array = []

    Task.new(@pool) {
      assert { array == [] }
      array << 1
    }.then {
      assert { array == [ 1 ] }
      array << 2
    }.then {
      assert { array == [ 1, 2 ] }
      array << 3
    }.then {
      assert { array == [ 1, 2, 3 ] }
      array << 4
    }.then {
      assert { array == [ 1, 2, 3, 4 ] }
      array << 5
    }
    @pool.wait
    assert { array == [ 1, 2, 3, 4, 5 ] }
  end
end
