#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "xl_suite/rets/client"

class RetsFuture < Future
  def client(reload=false)
    if reload
      @client = XlSuite::Rets::Client.new(rets_config[:login_url],
        :user_agent => rets_config[:user_agent], :username => rets_config[:username],
        :password => rets_config[:password], :logger => logger)
    else
      @client ||= XlSuite::Rets::Client.new(rets_config[:login_url],
          :user_agent => rets_config[:user_agent], :username => rets_config[:username],
          :password => rets_config[:password], :logger => logger)
    end
  end

  def run
    unless self.system?
      raise MissingAccountAuthorization.new("rets_import") unless self.account.options.rets_import?
    end

    status!(:logging_in, 10)
    client.transaction do |rets|
      status!(:querying, 20)
      run_rets(rets)
    end

    self.complete!
  end

  def rets_config
    @rets_config ||= self.load_config_file
  end

  def logger
    ActiveRecord::Base.logger
  end

  protected
  def config_file_path
    File.join(RAILS_ROOT, "config", "rets.yml")
  end

  def load_config_file
    conf = YAML.load_file(self.config_file_path)
    raise "No RETS configuration for environment #{RAILS_ENV} found in #{config_file_path}" unless conf.has_key?(RAILS_ENV)
    returning(conf[RAILS_ENV].symbolize_keys) do |conf|
      raise "Environment key #{RAILS_ENV} is empty in #{config_file_path}" if conf.empty?
    end
  end
end
