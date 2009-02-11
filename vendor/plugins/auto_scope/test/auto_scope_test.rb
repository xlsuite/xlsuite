require File.dirname(__FILE__) + "/test_helper"

class AutoScopeTest < Test::Unit::TestCase
  def setup
    Testimonial.delete_all; Contact.delete_all

    @approved = Testimonial.create!(:name => "John", :approved_at => 5.minutes.ago)
    @unapproved = Testimonial.create!(:name => "Abigail", :approved_at => nil)
  end

  def test_can_count_normally
    assert_equal 2, Testimonial.count
    assert_equal 1, Testimonial.count(:all, :conditions => ["approved_at IS NULL"])
    assert_equal 1, Testimonial.count(:all, :conditions => ["approved_at IS NOT NULL"])
  end

  def test_can_find_normally
    assert_equal @unapproved, Testimonial.find(:first, :order => "name")
    assert_equal [@approved].map(&:name),
        Testimonial.find(:all, :conditions => ["approved_at IS NOT NULL"], :order => "name DESC").map(&:name)
    assert_equal [@unapproved, @approved].map(&:name),
        Testimonial.find(:all, :order => "name").map(&:name)
  end

  def test_scoped_unapproved_find
    assert_equal [@unapproved].map(&:name), Testimonial.unapproved.find(:all).map(&:name)
  end

  def test_scoped_approved_find
    assert_equal [@approved].map(&:name), Testimonial.approved.find(:all).map(&:name)
  end

  def test_multiple_scoped_finds_in_succession
    assert_equal [@approved].map(&:name), Testimonial.approved.find(:all).map(&:name)
    assert_equal [@unapproved].map(&:name), Testimonial.unapproved.find(:all).map(&:name)
    assert_equal [@approved].map(&:name), Testimonial.approved.find(:all).map(&:name)
    assert_equal [@unapproved].map(&:name), Testimonial.unapproved.find(:all).map(&:name)
  end

  def test_scoped_approved_count
    assert_equal 1, Testimonial.approved.count
  end

  def test_scoped_unapproved_count
    assert_equal 1, Testimonial.unapproved.count
  end

  def test_multiple_scoped_counts_in_succession
    assert_equal 1, Testimonial.approved.count
    assert_equal 2, Testimonial.count
    assert_equal 1, Testimonial.unapproved.count
    assert_equal 1, Testimonial.approved.count
  end

  def test_evaluates_procs_in_conditions
    @approved.approved_at = 5.minutes.from_now
    @approved.save!
    assert_equal [], Testimonial.approved.find(:all)
  end

  def test_can_reuse_scope_multiple_times_in_succession
    assert_equal [@approved], Testimonial.approved.find(:all, :order => "id")
    assert_equal [@unapproved], Testimonial.unapproved.find(:all, :order => "id")
    @unapproved.update_attribute(:approved_at, 5.seconds.ago)
    assert_equal [@approved, @unapproved].map(&:name), Testimonial.approved.find(:all, :order => "id").map(&:name)
    assert_equal [], Testimonial.unapproved.find(:all, :order => "id")
    @unapproved.update_attribute(:approved_at, 5.seconds.from_now)
    assert_equal [@approved], Testimonial.approved.find(:all, :order => "id")
    assert_equal [], Testimonial.unapproved.find(:all, :order => "id")
    @approved.update_attribute(:approved_at, nil)
    assert_equal [], Testimonial.approved.find(:all, :order => "id")
    assert_equal [@approved], Testimonial.unapproved.find(:all, :order => "id")
  end
end

class AutoScopeNestedScopesTest < Test::Unit::TestCase
  def setup
    Testimonial.delete_all; Contact.delete_all

    @sammy = Contact.create!(:name => "Sammy")
    @approved = @sammy.testimonials.approved.create!(:name => "John", :approved_at => 5.minutes.ago)

    @harry = Contact.create!(:name => "Harry")
    @unapproved = @harry.testimonials.unapproved.create!(:name => "Abigail", :approved_at => nil)

    # Make sure we have fresh objects
    @sammy.reload; @harry.reload
    @approved.reload; @unapproved.reload
  end

  def test_harry_can_reach_his_unapproved_testimonial
    assert_equal [@unapproved], @harry.testimonials
    assert_equal [@unapproved], @harry.testimonials.find(:all)
    assert_equal [@unapproved], @harry.testimonials.unapproved.find(:all)
    assert_equal [], @harry.testimonials.approved.find(:all)
  end

  def test_sammy_can_reach_his_approved_testimonial
    assert_equal [@approved], @sammy.testimonials
    assert_equal [@approved], @sammy.testimonials.find(:all)
    assert_equal [@approved], @sammy.testimonials.approved.find(:all)
    assert_equal [], @sammy.testimonials.unapproved.find(:all)
  end

  def test_approved_was_approved
    assert_not_nil @approved.approved_at
  end

  def test_unapproved_not_approved
    assert_nil @unapproved.approved_at
  end

  def test_approved_associated_with_sammy
    assert_equal @sammy, @approved.contact
  end

  def test_unapproved_associated_with_harry
    assert_equal @sammy, @approved.contact
  end

  def test_nested_has_many_scope_for_searching
    assert_equal 1, @sammy.testimonials.size
    assert_equal 1, @sammy.testimonials.count
    assert_equal [@approved], @sammy.testimonials
    assert_equal [@approved], @sammy.testimonials.find(:all)
    assert_equal [@approved], @sammy.testimonials.approved.find(:all)
    assert_equal [], @sammy.testimonials.unapproved.find(:all),
        "Scope ensures we cannot find unapproved testimonials from another contact"

    assert_equal 1, @harry.testimonials.size
    assert_equal 1, @harry.testimonials.count
    assert_equal [@unapproved], @harry.testimonials
    assert_equal [@unapproved], @harry.testimonials.find(:all)
    assert_equal [@unapproved], @harry.testimonials.unapproved.find(:all)
    assert_equal [], @harry.testimonials.approved.find(:all),
        "Scope ensures we cannot find approved testimonials from another contact"
  end

  def test_nested_has_many_scope_for_building
    testimonial = @sammy.testimonials.approved.build
    assert_equal @sammy, testimonial.contact,
        "Sammy is not the owner of the new approved testimonial"
    assert_not_nil testimonial.approved_at,
        "Sammy's new testimonial isn't approved by default (like the scope says it should)"
  end

  def test_nested_has_many_scope_for_creating
    testimonial = @harry.testimonials.unapproved.create!
    assert !testimonial.new_record?,
        "New testimonial should have been saved automatically"
    assert_equal @harry, testimonial.contact,
        "Harry is not the owner of the new unapproved testimonial"
    assert_nil testimonial.approved_at,
        "Harry's new testimonial is approved when it shouldn't be (like the scope says it should)"
  end
end
