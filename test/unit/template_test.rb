require File.dirname(__FILE__) + '/../test_helper'

module TemplateTest
  class TemplateWithSpecificAccessorsTest < Test::Unit::TestCase
    def setup
      @account = Account.find(:first)
      @template = @account.templates.build(:subject => "subject template", :body => "subject body", :label => "label")
      @template.party = parties(:admin)
      @template.writer_ids = Group.find(:all).map(&:id)
      @template.save
    end
    
    def test_user_not_in_any_group_cannot_access_template
      Party.find(:all).each do |party|
        assert !@template.writeable_by?(party) if party.groups.blank?
      end
    end
    
    def test_user_in_any_group_can_access_template
      Group.find(:all).map(&:parties).flatten.uniq.each do |party|
        assert @template.writeable_by?(party)
      end
    end
  end

  class TemplateWithBlankAccessorsTest < Test::Unit::TestCase
    def setup
      @account = Account.find(:first)
      @template = @account.templates.build(:subject => "subject template", :body => "subject body")
      @template.party = parties(:admin)
    end
    
    def test_every_has_access
      Party.find(:all).each do |party|
        assert @template.writeable_by?(party)
      end
    end
  end
end
