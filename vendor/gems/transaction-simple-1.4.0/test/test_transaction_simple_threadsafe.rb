#!/usr/bin/env ruby
#--
# Transaction::Simple
# Simple object transaction support for Ruby
# http://rubyforge.org/projects/trans-simple/
#   Version 1.4.0
#
# Licensed under a MIT-style licence. See Licence.txt in the main
# distribution for full licensing information.
#
# Copyright (c) 2003 - 2007 Austin Ziegler
#
# $Id: test_transaction_simple_threadsafe.rb 48 2007-02-03 16:00:11Z austin $
#++
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'transaction/simple/threadsafe'
require 'test/unit'

module Transaction::Simple::Test
  class ThreadSafe < Test::Unit::TestCase #:nodoc:
    VALUE = "Now is the time for all good men to come to the aid of their country."

    def setup
      @value = VALUE.dup
      @value.extend(Transaction::Simple::ThreadSafe)
    end

    def test_extended
      assert_respond_to(@value, :start_transaction)
    end

    def test_started
      assert_equal(false, @value.transaction_open?)
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
    end

    def test_rewind
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.rewind_transaction }
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.gsub!(/men/, 'women') }
      assert_not_equal(VALUE, @value)
      assert_nothing_raised { @value.rewind_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_equal(VALUE, @value)
    end

    def test_abort
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.abort_transaction }
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.gsub!(/men/, 'women') }
      assert_not_equal(VALUE, @value)
      assert_nothing_raised { @value.abort_transaction }
      assert_equal(false, @value.transaction_open?)
      assert_equal(VALUE, @value)
    end

    def test_commit
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.commit_transaction }
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.gsub!(/men/, 'women') }
      assert_not_equal(VALUE, @value)
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.commit_transaction }
      assert_equal(false, @value.transaction_open?)
      assert_not_equal(VALUE, @value)
    end

    def test_multilevel
      assert_equal(false, @value.transaction_open?)
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.gsub!(/men/, 'women') }
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.start_transaction }
      assert_nothing_raised { @value.gsub!(/country/, 'nation-state') }
      assert_nothing_raised { @value.commit_transaction }
      assert_equal(VALUE.gsub(/men/, 'women').gsub(/country/, 'nation-state'), @value)
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value.abort_transaction }
      assert_equal(VALUE, @value)
    end

    def test_multilevel_named
      assert_equal(false, @value.transaction_open?)
      assert_raises(Transaction::TransactionError) { @value.transaction_name }
      assert_nothing_raised { @value.start_transaction(:first) } # 1
      assert_raises(Transaction::TransactionError) { @value.start_transaction(:first) }
      assert_equal(true, @value.transaction_open?)
      assert_equal(true, @value.transaction_open?(:first))
      assert_equal(:first, @value.transaction_name)
      assert_nothing_raised { @value.start_transaction } # 2
      assert_not_equal(:first, @value.transaction_name)
      assert_equal(nil, @value.transaction_name)
      assert_raises(Transaction::TransactionError) { @value.abort_transaction(:second) }
      assert_nothing_raised { @value.abort_transaction(:first) }
      assert_equal(false, @value.transaction_open?)
      assert_nothing_raised do
        @value.start_transaction(:first)
        @value.gsub!(/men/, 'women')
        @value.start_transaction(:second)
        @value.gsub!(/women/, 'people')
        @value.start_transaction
        @value.gsub!(/people/, 'sentients')
      end
      assert_nothing_raised { @value.abort_transaction(:second) }
      assert_equal(true, @value.transaction_open?(:first))
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_nothing_raised do
        @value.start_transaction(:second)
        @value.gsub!(/women/, 'people')
        @value.start_transaction
        @value.gsub!(/people/, 'sentients')
      end
      assert_raises(Transaction::TransactionError) { @value.rewind_transaction(:foo) }
      assert_nothing_raised { @value.rewind_transaction(:second) }
      assert_equal(VALUE.gsub(/men/, 'women'), @value)
      assert_nothing_raised do
        @value.gsub!(/women/, 'people')
        @value.start_transaction
        @value.gsub!(/people/, 'sentients')
      end
      assert_raises(Transaction::TransactionError) { @value.commit_transaction(:foo) }
      assert_nothing_raised { @value.commit_transaction(:first) }
      assert_equal(VALUE.gsub(/men/, 'sentients'), @value)
      assert_equal(false, @value.transaction_open?)
    end

    def test_array
      assert_nothing_raised do
        @orig = ["first", "second", "third"]
        @value = ["first", "second", "third"]
        @value.extend(Transaction::Simple::ThreadSafe)
      end
      assert_equal(@orig, @value)
      assert_nothing_raised { @value.start_transaction }
      assert_equal(true, @value.transaction_open?)
      assert_nothing_raised { @value[1].gsub!(/second/, "fourth") }
      assert_not_equal(@orig, @value)
      assert_nothing_raised { @value.abort_transaction }
      assert_equal(@orig, @value)
    end
  end
end
