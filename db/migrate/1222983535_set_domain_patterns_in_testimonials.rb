class SetDomainPatternsInTestimonials < ActiveRecord::Migration
  def self.up
    Testimonial.update_all("domain_patterns='**'")
  end

  def self.down
    Testimonial.update_all("domain_patterns=NULL")
  end
end
