require 'test/unit'
STDOUT.sync = true
$:.unshift 'lib'
$:.unshift '../lib'
$:.unshift '.'
require 'arrayfields'

class ArrayFieldsTest < Test::Unit::TestCase
#--{{{
  def setup
#--{{{
    @fields = %w(zero one two)
    @str_fields = %w(zero one two)
    @sym_fields = [:zero, :one, :two] 
    @a = [0,1,2] 
#--}}}
  end
#
# setting fields correctly
#
  def test_00
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_equal @a.fields, @str_fields
#--}}}
  end
  def test_01
#--{{{
    assert_nothing_raised do
      @a.fields = @sym_fields
    end
    assert_equal @a.fields, @sym_fields
#--}}}
  end
  def test_02
#--{{{
    assert_nothing_raised do
      a = ArrayFields::FieldSet.new @str_fields
      b = ArrayFields::FieldSet.new @str_fields
      assert_equal a, b 
      assert_equal a.object_id, b.object_id 
    end
#--}}}
  end
  def test_03
#--{{{
    assert_nothing_raised do
      a = ArrayFields::FieldSet.new @sym_fields
      b = ArrayFields::FieldSet.new @sym_fields
      c = ArrayFields::FieldSet.new @str_fields
      d = ArrayFields::FieldSet.new @str_fields
      assert_equal a, b 
      assert_equal a.object_id, b.object_id 
      assert_not_equal a, c
      assert_not_equal a.object_id, c.object_id
    end
#--}}}
  end
#
# setting fields incorrectly
#
  def test_10
#--{{{
    assert_raises(ArgumentError) do
      @a.fields = nil 
    end
#--}}}
  end
  def test_11
#--{{{
    assert_raises(ArgumentError) do
      @a.fields = []
    end
#--}}}
  end
  def test_11
#--{{{
    assert_raises(ArgumentError) do
      @a.fields = [Hash.new]
    end
#--}}}
  end
#
# [] 
#
  def test_20
#--{{{
    a, b, c = @a[0], @a[1,1].first, @a[2..2].first
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      assert_equal a, @a['zero']
    end
    assert_nothing_raised do
      assert_equal b, @a['one']
    end
    assert_nothing_raised do
      assert_equal c, @a['two']
    end
#--}}}
  end
  def test_21
#--{{{
    a = @a[0,@a.size]
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      assert_equal a, @a['zero', @a.size]
    end
#--}}}
  end
#
# []=
#
  def test_30
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    value = 42 
    assert_nothing_raised do
      @a['zero'] = value
      assert_equal value, @a['zero']
      assert_equal @a[0], @a['zero']
    end
#--}}}
  end
  def test_31
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    value = 42 
    assert_nothing_raised do
      @a['zero', 1] = value
      assert_equal value, @a['zero']
      assert_equal @a[0,1], @a['zero',1]
    end
#--}}}
  end
  def test_32
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    value = 42 
    assert_nothing_raised do
      @a[0..0] = value
      assert_equal value, @a['zero']
      assert_equal @a[0,1], @a['zero',1]
    end
#--}}}
  end
  def test_33
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      @a['zero', @a.size] = nil
      assert_equal @a, []
    end
#--}}}
  end
  def test_34
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      @a['three'] = 3
      assert_equal 3, @a['three']
      assert_equal 3, @a[3]
    end
#--}}}
  end
  def test_35
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
      @a['three'] = 3
    end
    %w(zero one two three).inject(exp=[]){|ex,f| ex << [ex.size, f]}
    actual = []
    assert_nothing_raised do
      @a.each_with_field{|e,f| actual << [e,f]}
    end
    assert_equal exp, actual
#--}}}
  end
  def test_36
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
      @a['three'] = 3
    end
    assert_equal %w(zero one two three), @a.fields
#--}}}
  end
#
# at
#
  def test_40
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    @str_fields.each_with_index do |f, i|
      ret = nil
      assert_nothing_raised do
        ret = @a.at f
      end
      assert_equal ret, i
    end
#--}}}
  end
#
# delete_at
#
  def test_50
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      value = @a.delete_at 'zero'
      assert_equal 0, value
    end
    assert_nothing_raised do
      value = @a.delete_at 'three'
      assert_equal nil, value
    end
#--}}}
  end
#
# fill 
#
  def test_60
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      @a.fill 42, 'zero', 1
      assert_equal 42, @a[0] 
    end
#--}}}
  end
  def test_61
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      @a.fill 42
      assert_equal 42, @a[-1] 
    end
#--}}}
  end
  def test_62
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      @a.fill 42, 0...@a.size
      assert_equal(Array.new(@a.size, 42), @a)
    end
#--}}}
  end
#
# slice 
#
  def test_70
#--{{{
    a, b, c = @a[0], @a[1,1].first, @a[2..2].first
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      assert_equal a, @a.slice('zero')
    end
    assert_nothing_raised do
      assert_equal b, @a.slice('one')
    end
    assert_nothing_raised do
      assert_equal c, @a.slice('two')
    end
#--}}}
  end
#
# slice!
#
  def test_80
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      @a.slice! 'zero', @a.size
      assert_equal @a, []
    end
#--}}}
  end
  def test_81
#--{{{
    assert_nothing_raised do
      @a.fields = @str_fields
    end
    assert_nothing_raised do
      @a.slice! 0, @a.size
      assert_equal @a, []
    end
#--}}}
  end
if false
end
#--}}}
end
