require File.dirname(__FILE__)+'/test_helper'

class Place < ActiveRecord::Base
  acts_as_taggable
  has_many    :things
end

class Thing < ActiveRecord::Base
  acts_as_taggable
  belongs_to  :place
end

class PlaceFrom < ActiveRecord::Base
  acts_as_taggable :from => :place
end

class ActsAsTaggableTest < Test::Unit::TestCase
  fixtures  :places, :things, :tags, :taggings

  def test_escape
    assert_equal [], Place.send(:escape_tags, [])
    assert_equal [], Place.send(:escape_tags, ['   '])
    assert_equal ["'a'"], Place.send(:escape_tags, ['a'])
    assert_equal ["'b  c'"], Place.send(:escape_tags, ['b  c']) # don't compact.. yet
    assert_equal ["'a'", "'b c'", "'d e f'"], Place.send(:escape_tags, ['a', 'b c', ' ', nil, ' d E f '])
  end

  def test_tags
    assert_equal [2, 4, 1], (pt = Place.tags).map { |t| t.id }
    assert_equal [1, 1, 3], pt.map { |t| t.count.to_i }

    assert_equal [2, 3, 4, 1], Thing.tags.map { |t| t.id }
    assert_equal [3, 1], places(:home).things.tags.map { |t| t.id }
    assert_equal [1], places(:work).things.tags.map { |t| t.id }
    assert_equal [2, 3, 4, 1], places(:pub).things.tags.map { |t| t.id }
    assert_equal [1], places(:home).tags.map { |t| t.id }
    assert_equal [1], places(:work).tags.map { |t| t.id }
    assert_equal [2, 4, 1], places(:pub).tags.map { |t| t.id }
    assert_equal [3], things(:sushi).tags.map { |t| t.id }
    assert_equal [3, 4], things(:chips).tags.map { |t| t.id }
  end
  
  def test_tag
    assert_equal [tags(:sit)], places(:home).tags
    assert_equal tags(:drink), places(:home).tag('drink')
    assert_equal [tags(:drink), tags(:sit)], places(:home).tags(true)
    assert_equal tags(:drink), places(:home).tag('drink')
    assert_equal [tags(:drink), tags(:drink), tags(:sit)], places(:home).tags(true) # dups not removed
  end

  def test_tags_order
    assert_equal [tags(:sit), tags(:lay), tags(:drink)], Place.tags(:order => 'tags.name DESC')
  end

  def test_tags_with_conditions
    assert_equal [tags(:sit)], Place.tags(:conditions => "tags.name = 'sit'")
    assert_equal [tags(:sit)], places(:home).things.tags(:conditions => "tags.name = 'sit'")
  end

  def test_tags_with_find_class_scope
    Place.with_scope :find => {:conditions => "tags.name = 'sit'" } do
      assert_equal [tags(:sit)], Place.tags
    end
  end

  def test_tags_with_limit
    assert_equal [tags(:drink)], Place.tags(:limit => 1)
    assert_equal [tags(:sit)], Place.tags(:limit => 1, :order => 'tags.name DESC')
    assert_equal [tags(:eat)], Thing.tags(:limit => 1, :order => 'count DESC, tags.name')
    assert_equal [tags(:sit)], places(:home).things.tags(:limit => 1, :order => 'count DESC, tags.name DESC')
  end

  def test_find_related_tags
    Place.logger.info("Begin find related_tags")
    assert_equal [2, 4], Place.find_related_tags(['sit']).map { |t| t.id } # through pub
    assert_equal [2, 1], Place.find_related_tags(['lay']).map { |t| t.id } # through pub
    assert_equal [2], Place.find_related_tags(['sit', 'lay']).map { |t| t.id } # through pub
    assert_equal [2, 3], Thing.find_related_tags(['sit']).map { |t| t.id }
    assert_equal [2, 4, 1], Thing.find_related_tags(['eat']).map { |t| t.id } 

    assert_equal [3, 1], places(:pub).things.find_related_tags(['drink']).map { |t| t.id } # through bar

    assert_equal [], Place.find_related_tags(['nonexistant'])
    assert_equal [], Place.find_related_tags(['nothing'])
    assert_equal [], Place.find_related_tags([])
  end

  def test_find_tagged_with_depreciated_which_is_actually_any
    assert_equal [places(:home), places(:work), places(:pub)], Place.find_tagged_with(['sit'])
    assert_equal [places(:home), places(:work), places(:pub)], Place.find_tagged_with(['sit', 'lay'])
    assert_equal [things(:bath), things(:desk), things(:bar)], Thing.find_tagged_with(['sit'])
    assert_equal [things(:bar)], places(:pub).things.find_tagged_with(['sit'])
    assert_equal [things(:bath)], places(:home).things.find_tagged_with(['sit'])
  end

  def test_find_tagged_with_any
    assert_equal [places(:home), places(:work), places(:pub)], Place.find_tagged_with(:any => ['sit'])
    assert_equal [places(:home), places(:work), places(:pub)], Place.find_tagged_with(:any => ['sit', 'lay'])
    assert_equal [], Place.find_tagged_with(:any => ['nonexistant'])
    assert_equal [], Place.find_tagged_with(:any => ['nothing'])
    assert_equal [], Place.find_tagged_with(:any => [])
  end

  def test_find_tagged_with_all
    assert_equal [places(:home), places(:work), places(:pub)], Place.find_tagged_with(:all => ['sit'])
    assert_equal [places(:pub)], Place.find_tagged_with(:all => ['sit', 'lay'])
    assert_equal [places(:pub)], Place.find_tagged_with(:all => ['sit', 'drink'])
    assert_equal [things(:bath), things(:desk), things(:bar)], Thing.find_tagged_with(:all => ['sit'])
    assert_equal [things(:bar)], places(:pub).things.find_tagged_with(:all => ['sit'])
    assert_equal [things(:chips)], places(:pub).things.find_tagged_with(:all => ['eat', 'lay'])
    assert_equal [things(:bath)], places(:home).things.find_tagged_with(:all => ['sit'])

    assert_equal [], Place.find_related_tags(:all => ['nonexistant'])
    assert_equal [], Place.find_tagged_with(:all => ['nothing'])
    assert_equal [], Place.find_tagged_with(:all => [])
  end

  def test_find_tagged_with_options
    assert_equal [places(:work), places(:pub)], Place.find_tagged_with(:all => ['sit'], :conditions => 'places.id != 1')
    assert_equal [places(:pub), places(:work)], Place.find_tagged_with(:all => ['sit'], :conditions => 'places.id != 1', :order => 'places.name')

    assert_equal [places(:home)], Place.find_tagged_with(:any => ['sit'], :limit => '1')
    assert_equal [], Place.find_tagged_with(:any => ['sit', 'lay'], :conditions => '0 != 0')
  end

  def test_find_tagged_with_eager_loading
    assert_not_nil Place.find_tagged_with(:all => ['sit', 'lay'], :include => :things).first.instance_variable_get('@things')
  end

  def test_find_tagged_with_conditions
    assert_equal [places(:home)], Place.find_tagged_with(:all => ['sit'], :conditions => "places.id = 1")
  end

  def test_find_tagged_with_limit
    assert_equal [places(:home)], Place.find_tagged_with(:all => ['sit'], :limit => 1)
  end

  def test_tag_list
    assert_equal 'sit', places(:home).tag_list
    assert_equal 'sit', places(:work).tag_list
    assert_equal 'drink, lay, sit', places(:pub).tag_list
    assert_equal 'drink, eat, sit', places(:pub).things[1].tag_list

    assert_equal 'sit', (places(:home).tag_list = 'sit')

    assert_equal tags(:sit), (places(:home).tag_list = 'sit') && places(:home).tags

    places(:home).tag_list = 'sit, "then beg"'
    assert_equal "sit, 'then beg'", places(:home).tag_list

    places(:home).tag_list = '"then eat", "first beg"'
    assert_equal "'first beg', 'then eat'", places(:home).tag_list
  end

  def test_parse
    assert_equal Set.new(['a', 'b']), Set.new(Tag.parse('a b'))
    assert_equal Set.new(['a', 'b c']), Set.new(Tag.parse('a "b c"'))
    assert_equal Set.new(['a', 'b c']), Set.new(Tag.parse("a 'b c'"))
    assert_equal Set.new(['a', 'b']), Set.new(Tag.parse("  a    b  "))
    assert_equal Set.new(['ab', 'bc']), Set.new(Tag.parse("  ab    bc  "))
    assert_equal Set.new(['aa bb', 'bb cc']), Set.new(Tag.parse("   'aa bb'    'bb cc'   "))
    assert_equal Set.new(['aa bb', 'bb', 'cc']), Set.new(Tag.parse("   'aa bb',    bb,  cc   "))
    assert_equal Set.new([]), Set.new(Tag.parse("   "))
    assert_equal Set.new([]), Set.new(Tag.parse(" ''  "))
  end

  def test_tagged
    assert_equal [things(:bath), things(:desk), things(:bar), places(:home), places(:work), places(:pub)], tags(:sit).tagged
    assert_equal [places(:pub), things(:bar)], tags(:drink).tagged
  end

  def test_create
    bar = things(:bar)
    assert_equal [], bar.tag_with('')
    assert_equal [], bar.reload && bar.tags

    assert_equal [tags(:sit)], bar.tag_with('sit')
    assert_equal [tags(:lay), tags(:sit)], bar.tag_with('lay sit')

    tagging = tags(:drink).on(things(:watercooler))
    assert_equal Tagging, tagging.class
    assert_equal tags(:drink), tagging.tag
    assert_equal things(:watercooler), tagging.taggable
  end
end
