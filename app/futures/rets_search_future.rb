#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RetsSearchFuture < RetsFuture
  class QueryError < ArgumentError; end
  class UnknownFieldError < QueryError; end
  class SyntaxError < QueryError; end
  class StringifiedDateError < QueryError; end

  NO_RESULTS_FOUND_CODE = "20201".freeze

  validate :query_must_have_at_least_one_line
  validate :query_is_valid
  before_save :set_low_priority

  def run_rets(rets, priority=nil, import_photo=true)
    self.results[:listings] = []
    begin
      q = self.query
      logger.debug {"==> #{self.class.name}:#{self.id}\#run_rets\n    Q: #{q.inspect}"}
      rets.search(args[:search][:resource], args[:search][:class],
                  q, :limit => args[:search][:limit]) do |property|
        percent_done = 20
        percent_done += (self.results[:listings].size / self.args[:search][:limit].to_f * 80.0).to_i
        status!(:processing_results, percent_done)

        listing = self.account.listings.find_or_initialize_by_property(args[:search][:resource],
                                                                       args[:search][:class], property)
        listing.account = self.account if listing.account.nil?
        listing.tag_list += " #{args[:search][:tag_list]}" unless args[:search][:tag_list].blank?
        listing.save!
        
        retriever_id = nil
        if import_photo
          retriever = RetsPhotoRetriever.create!(:account => self.account, :owner => self.owner, :system => self.owner.blank?,
                                                 :priority => (priority || 100),
                                                 :args => {:key => listing.external_id, :listing_id => listing.id,
                                                   :tags => "listing"})
          retriever_id = retriever.id
        end                              

        self.results[:listings] << {:id => listing.id, :mls_no => listing.mls_no, :retriever_id => retriever_id}
        self.update_attribute(:results, self.results)
      end
    rescue XlSuite::Rets::RetsClient::LookupFailure
      # If there were no results, we don't crash anymore, simply return
      # and the :listings results will be an empty Array.
      raise unless $!.message[NO_RESULTS_FOUND_CODE]
    end

    self.complete!
    return self.results[:listings]
  end

  def contain_recipient?(recipient)
    return false if !self.args.has_key?(:recipients) || self.args[:recipients].blank?
    party_id = if recipient.kind_of?(Party)
      recipient.id
    elsif recipient.kind_of?(Fixnum)
      recipient
    else
      raise "Recipient type not supported"
    end
    self.args[:recipients].include?("party_#{party_id}")
  end

  def listings
    Listing.find(self.results[:listings].map {|r| r[:id]})
  end

  def retrievers
    Future.find(self.results[:listings].map {|r| r[:retriever_id]})
  end

  def query
    self.class.parse(self.args[:search], self.args[:lines])
  end

  def query_is_valid
    self.query
  rescue QueryError
      self.errors.add_to_base("Could not understand query: #{$!}")
  end
  protected :query_is_valid

  def query_must_have_at_least_one_line
    self.errors.add_to_base("No query lines -- did you 'Add' to your query ?") \
        if args[:lines].blank? || args[:lines].size.zero?
  end
  protected :query_must_have_at_least_one_line
  
  def set_low_priority
    self.priority = 950 unless self.priority
  end
  protected :set_low_priority

  def self.parse(params, lines)
    raise ArgumentError, "params does not respond_to?(:[]), it is a #{params.class.name}" unless params.respond_to?(:[])
    raise ArgumentError, "lines does not respond_to?(:each), it is a #{lines.class.name}" unless lines.respond_to?(:each)
    
    query = Array.new
    date_parser = lambda do |datestr|
      date = Chronic.parse(datestr[1..-2])
      raise StringifiedDateError, "Unable to parse #{datestr.inspect} into a date object" unless date
      date.to_date.to_s(:iso)
    end

    fields = RetsMetadata.find_all_fields(params[:resource], params[:class])
    lines.each_with_index do |line, index|
      field = fields.detect {|f| f.value == line[:field]}
      raise UnknownFieldError, "Unknown field: #{line[:field].inspect}" unless field
      field.value.strip!

      from = line[:from].gsub(/\(([^\)]+?)\)/, &date_parser)
      to = line[:to].gsub(/\(([^\)]+?)\)/, &date_parser) if line.has_key?(:to)

      case line[:operator]
      when "eq"
        query << [field.value, "=", from]
      when "greater"
        query << [field.value, "=", from, "+"]
      when "less"
        query << [field.value, "=", from, "-"]
      when "between"
        query << [field.value, "=", from, "-", to]
      when "contain", "contains"
        query << [field.value, "=", "*", from, "*"]
      when "start", "starts"
        query << [field.value, "=", from, "*"]
      else
        raise SyntaxError, "Unknown operator: #{line[:operator].inspect}"
      end
    end

    query.map {|q| ["(", q, ")"].join("")}.join(",")
  end
  
  def humanize_status
    if self.status =~ /unstarted/i
      if self.scheduled_at < Time.now
        return "Waiting"
      else
        return "Sleeping"
      end
    end
    if self.errored?
      return "Errored"
    end
    return self.status.humanize
  end
end
