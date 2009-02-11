require File.dirname(__FILE__) + '/../test_helper'

class NameTest < Test::Unit::TestCase
  def test_equality_with_self
    n = Name.new('last', 'first', 'middle')
    assert_equal n, n
  end

  def test_equality_with_equivalent
    n0 = Name.new('last', 'first', 'middle')
    n1 = Name.new('last', 'first', 'middle')

    assert_equal n0, n1
    assert_equal n1, n0
  end

  def test_non_equality_with_last_different
    n0 = Name.new('doe', 'first', 'middle')
    n1 = Name.new('smith', 'first', 'middle')

    assert_equal false, n0 == n1
    assert_equal false, n1 == n0
  end

  def test_non_equality_with_first_different
    n0 = Name.new('doe', 'john', 'M')
    n1 = Name.new('doe', 'jack', 'M')

    assert_equal false, n0 == n1
    assert_equal false, n1 == n0
  end

  def test_non_equality_with_middle_different
    n0 = Name.new('doe', 'john', 'T')
    n1 = Name.new('doe', 'john', 'M')

    assert_equal false, n0 == n1
    assert_equal false, n1 == n0
  end

  def test_last_name_collation
    n0 = Name.new('doe')
    n1 = Name.new('smith')
    n2 = Name.new('Smith')

    assert n0.<=>(n1) < 0
    assert n1.<=>(n0) > 0
    assert_equal 0, n1.<=>(n2)
    assert_equal 0, n2.<=>(n1)
  end

  def test_first_name_collation
    n0 = Name.new(nil, 'jack')
    n1 = Name.new(nil, 'john')
    n2 = Name.new(nil, 'John')
    n3 = Name.new('Smith', 'Jack')
    n4 = Name.new('Smith', 'John')

    assert n0.<=>(n1) < 0
    assert n1.<=>(n0) > 0
    assert_equal 0, n1.<=>(n2)
    assert_equal 0, n2.<=>(n1)
    assert n0.<=>(n3) < 0
    assert n3.<=>(n0) > 0
    assert n3.<=>(n4) < 0
    assert n4.<=>(n3) > 0
  end

  def test_middle_name_collation
    n0 = Name.new(nil, nil, 'J')
    n1 = Name.new(nil, nil, 'M')
    n2 = Name.new(nil, nil, 'm')
    n3 = Name.new('Kennedy', 'John', 'F')
    n4 = Name.new('Kennedy', 'John', 'G')

    assert n0.<=>(n1) < 0
    assert n1.<=>(n0) > 0
    assert_equal 0, n1.<=>(n2)
    assert_equal 0, n2.<=>(n1)
    assert n0.<=>(n3) < 0
    assert n3.<=>(n0) > 0
    assert n3.<=>(n4) < 0
    assert n4.<=>(n3) > 0
  end

  def test_full_collation
    n0 = Name.new('Smith', 'John')
    n1 = Name.new('Smith', 'Jil')
    n2 = Name.new('', 'Peter')
    n3 = Name.new('Kennedy')

    assert_equal [n2, n3, n1, n0], [n0, n1, n2, n3].sort
  end

  def test_last_formatting
    assert_equal 'Last', Name.new('Last').to_backward_s
    assert_equal 'Last', Name.new('Last', '', nil).to_backward_s
    assert_equal 'Last', Name.new('Last', '', '').to_backward_s
    assert_equal 'Last', Name.new('Last').to_forward_s
    assert_equal 'Last', Name.new('Last', '', nil).to_forward_s
    assert_equal 'Last', Name.new('Last', '', '').to_forward_s
  end

  def test_last_and_first_formatting
    assert_equal 'Last, First', Name.new('Last', 'First').to_backward_s
    assert_equal 'Last, First', Name.new('Last', 'First', '').to_backward_s
    assert_equal 'First Last', Name.new('Last', 'First').to_forward_s
    assert_equal 'First Last', Name.new('Last', 'First', '').to_forward_s
  end

  def test_last_and_middle_formatting
    assert_equal 'Last, Middle', Name.new('Last', nil, 'Middle').to_backward_s
    assert_equal 'Last, Middle', Name.new('Last', '', 'Middle').to_backward_s
    assert_equal 'Middle Last', Name.new('Last', nil, 'Middle').to_forward_s
    assert_equal 'Middle Last', Name.new('Last', '', 'Middle').to_forward_s
  end

  def test_first_and_middle_formatting
    assert_equal 'First Middle', Name.new(nil, 'First', 'Middle').to_backward_s
    assert_equal 'First Middle', Name.new('', 'First', 'Middle').to_backward_s
    assert_equal 'First Middle', Name.new(nil, 'First', 'Middle').to_forward_s
    assert_equal 'First Middle', Name.new('', 'First', 'Middle').to_forward_s
  end

  def test_full_formatting
    assert_equal 'Last, First Middle', Name.new('Last', 'First', 'Middle').to_backward_s
    assert_equal 'First Middle Last', Name.new('Last', 'First', 'Middle').to_forward_s
    assert_equal Name.new('Last', 'First', 'Middle').to_forward_s, Name.new('Last', 'First', 'Middle').to_s
  end

  def test_parsing
    assert_equal Name.new(nil, "Clara", nil), Name.parse("Clara")
    assert_equal Name.new("Stevenson", "Clara", nil), Name.parse("Clara Stevenson")
    assert_equal Name.new("Stevenson", "Clara", "G."), Name.parse("Clara G. Stevenson")
    assert_equal Name.new("Stevenson", "Clara", "G."), Name.parse("Stevenson, Clara G.")
  end
end
