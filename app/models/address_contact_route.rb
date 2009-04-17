#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AddressContactRoute < ContactRoute
  acts_as_reportable :columns => %w(line1 line2 line3 city state country zip)

  CANADA = 'CAN'
  UNITED_STATES = 'USA'
  COUNTRIES = ([['Canada', CANADA], ['USA', UNITED_STATES]] + ActionView::Helpers::FormOptionsHelper::COUNTRIES.reject {|c| c =~ /^(united\sstates|canada)$/i}.map {|c| [c, c]}).freeze
  STATES = [
            # Canada
            ['Alberta', 'AB'],
            ['British Columbia', 'BC'],
            ['Manitoba', 'MB'],
            ['New Brunswick', 'NB'],
            ['Newfoundland/Labrador', 'NL'],
            ['Northwest Territories', 'NT'],
            ['Nova Scotia', 'NS'],
            ['Nunavut', 'NU'],
            ['Ontario', 'ON'],
            ['Prince Edward Island', 'PE'],
            ['Quebec', 'QC'],
            ['Saskatchewan', 'SK'],
            ['Yukon', 'YT'],

            # USA
            ['Alabama', 'AL'],
            ['Alaska', 'AK'],
            ['American Samoa', 'AS'],
            ['Arizona', 'AZ'],
            ['Arkansas', 'AR'],
            ['California', 'CA'],
            ['Colorado', 'CO'],
            ['Connecticut', 'CT'],
            ['Delaware', 'DE'],
            ['District of Columbia', 'DC'],
            ['Florida', 'FL'],
            ['Georgia', 'GA'],
            ['Guam', 'GU'],
            ['Hawaii', 'HI'],
            ['Idaho', 'ID'],
            ['Illinois', 'IL'],
            ['Indiana', 'IN'],
            ['Iowa', 'IA'],
            ['Kansas', 'KS'],
            ['Kentucky', 'KY'],
            ['Louisiana', 'LA'],
            ['Maine', 'ME'],
            ['Marshall Islands', 'MH'],
            ['Maryland', 'MD'],
            ['Massachusetts', 'MA'],
            ['Michigan', 'MI'],
            ['Micronesia', 'FM'],
            ['Minnesota', 'MN'],
            ['Mississippi', 'MS'],
            ['Missouri', 'MO'],
            ['Montana', 'MT'],
            ['Nebraska', 'NE'],
            ['Nevada', 'NV'],
            ['New Hampshire', 'NH'],
            ['New Jersey', 'NJ'],
            ['New Mexico', 'NM'],
            ['New York', 'NY'],
            ['North Carolina', 'NC'],
            ['North Dakota', 'ND'],
            ['Ohio', 'OH'],
            ['Oklahoma', 'OK'],
            ['Oregon', 'OR'],
            ['Palau', 'PW'],
            ['Pennsylvania', 'PA'],
            ['Puerto Rico', 'PR'],
            ['Rhode Island', 'RI'],
            ['South Carolina', 'SC'],
            ['South Dakota', 'SD'],
            ['Tennessee', 'TN'],
            ['Texas', 'TX'],
            ['Utah', 'UT'],
            ['Vermont', 'VT'],
            ['Virgin Islands', 'VI'],
            ['Virginia', 'VA'],
            ['Washington', 'WA'],
            ['West Virginia', 'WV'],
            ['Wisconsin', 'WI'],
            ['Wyoming', 'WY'],
            ['Other', 'OTHER']
          ].freeze

  validates_numericality_of :latitude, :longitude, :allow_nil => true
  
  before_save :update_longitude_latitude
  after_save :update_routable_latitude_longitude

  attr_accessor :zip_required, :name_required
  alias_method :zip_required?, :zip_required

  acts_as_geolocatable

  def canada?
    [CANADA.downcase, "canada"].include?(self.country.downcase)
  end

  def united_states?
    [UNITED_STATES.downcase, "united states"].include?(self.country.downcase)
  end

  alias_method :usa?, :united_states?

  # Returns a copy of this object, but without the #routable reference.
  def dup
    self.class.new(
        :line1 => self.line1, :line2 => self.line2, :line3 => self.line3,
        :city => self.city, :state => self.state, :country => self.country, 
        :zip => self.zip, :name => self.name)
  end

  def to_url
    country = COUNTRIES.dup.delete_if {|c| c[1] != self.country}.first || []
    [self.line1, self.line2, self.line3, self.city, self.state, country.first].reject(&:blank?).join(', ')
  end

  def to_s
    buffer = []
    buffer << "#{self.name}:" unless self.name.blank?
    %w(line1 line2 line3 city state zip country).each do |attr|
      buffer << self.send(attr)
    end
    buffer.reject(&:blank?).join(", ")
  end

  def full_country
    (COUNTRIES.rassoc(self.country.mb_chars.upcase) || []).first || self.country
  end

  def full_state
    (STATES.rassoc(self.state.mb_chars.upcase) || []).first || self.state
  end

  def state
    read_attribute(:state) || ""
  end

  def country
    read_attribute(:country) || ""
  end

  def format(options={})
    attributes = case
      when usa? || canada?
        [self.line1, self.line2, self.line3, "#{self.city} #{self.state.mb_chars.upcase}  #{self.zip}", self.full_country]
      else
        [self.line1, self.line2, self.line3, "#{self.city} #{self.state.mb_chars.upcase}", self.zip, self.full_country]
      end.reject(&:blank?)
    unless options[:html].blank?
      attributes = attributes.map {|attribute| "<#{options[:html][:tag]} class='#{options[:html][:class]}'>" + attribute + "</#{options[:html][:tag]}>"}
    end
    attributes
  end

  def choices
    super %w(Home Office Mailing) 
  end

  def to_liquid
    AddressDrop.new(self)
  end

  def to_s(options={})
    array = self.format(options)
    if options[:html].blank?
      array.join(', ')
    else
      array.join(options[:html][:separator])
    end
  end

  def to_formatted_s(options={})
    array = self.format(options)
    if options[:html].blank?
      array.join('\n')
    else
      array.join(options[:html][:separator])
    end
  end

  # Two addresses are equal if they have the same lines, city, state, country
  # and zip.  The name and routable are not taken in to consideration.
  def ==(other)
    other.kind_of?(self.class) &&
    self.line1 == other.line1 &&
    self.line2 == other.line2 &&
    self.line3 == other.line3 &&
    self.city == other.city &&
    self.state == other.state &&
    self.country == other.country &&
    self.zip == other.zip
  end

  def self.find_by_first_line(line1)
    value = (line1 || "").mb_chars.gsub(/\s{2,}/, ' ').titleize #clean to match insert
    value = value.mb_chars[0..39] #truncate to match insert
    AddressContactRoute.find_by_line1(value)
  end

  # Address normalization methods
  %w(line1 line2 line3).each do |attr|
    define_method("#{attr}=") do |value|
      value = (value || "").mb_chars.gsub(/\s{2,}/, ' ')
      write_attribute(attr, value.blank? || value.empty? ? nil : value)
    end
  end

  def city=(value)
    value = (value || "").mb_chars.gsub(/\s{2,}/, ' ').titleize
    write_attribute(:city, value.blank? || value.empty? ? nil : value)
  end

  def state=(value)
    return write_attribute(:state, nil) if value.blank?
    value = value.mb_chars.titleize
    new_state = (STATES.assoc(value) || STATES.rassoc(value.upcase) || []).last
    write_attribute(:state, new_state || value)
  end

  def country=(value)
    return write_attribute(:country, nil) if value.blank?
    value = value.mb_chars.titleize
    new_country = (COUNTRIES.assoc(value) || COUNTRIES.rassoc(value.upcase) || []).last
    write_attribute(:country, new_country || value)
  end

  def zip=(value)
    return write_attribute(:zip, nil) if value.blank?
    value = value.mb_chars.gsub(/\W/, '').upcase
    write_attribute(:zip, value)
  end

  def zip
    zip_code = read_attribute(:zip)
    return nil if zip_code.blank? || zip_code.empty? || zip_code.strip.empty?

    case
    when self.canada?
      "#{zip_code[0...3]} #{zip_code[3..-1]}"

    when self.usa?
      return zip_code unless zip_code.length > 5
      "#{zip_code[0...5]}-#{zip_code[5..-1]}"

    else
      zip_code
    end
  end
  
  def to_xml(options={})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.address(:id => self.dom_id) do
      xml.name self.name
      xml.line1 self.line1
      xml.line2 self.line2
      xml.line3 self.line3
      xml.city self.city
      xml.state self.state
      xml.country self.country
      xml.zip self.zip
    end
  end
  
  def main_identifier
    self.to_s
  end
  
  def normalized_zip
    read_attribute(:zip)
  end
  
  protected
  def update_longitude_latitude
    logger.debug {"==> normalized_zip: #{normalized_zip}"}
    if self.normalized_zip.blank? then
      self.longitude, self.latitude = nil
    else
      if geocode = Geocode.find_by_zip(self.normalized_zip) then
        logger.debug {"==> Geocode: #{geocode.attributes.inspect}"}
        self.longitude, self.latitude = geocode.longitude, geocode.latitude
      else
        self.longitude, self.latitude = nil
      end
    end
  end

  def update_routable_latitude_longitude
    return unless self.routable.respond_to?(:latitude=) && self.routable.respond_to?(:longitude=)

    # Update in memory
    self.routable.latitude, self.routable.longitude = self.latitude, self.longitude

    unless self.routable.new_record? then
      # And on disk.  Since we update only the latitude and longitude, we should be pretty safe in the face of validation errors and such.
      self.routable.class.update_all(["latitude = ?, longitude = ?", self.latitude, self.longitude], ["id = ?", self.routable.id])
    end
  end
end
