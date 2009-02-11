module ResponseLogger
  def self.included(base)
    base.send :append_after_filter, :log_body_response
  end

  def log_body_response
    return if response.headers['Content-Type'].to_s =~ /html|css/i
    log_header = "===> #{response.headers['Content-Type']}"
    log_header << " (#{response.body.length} bytes)" if response.body.respond_to?(:length)

    logger.debug log_header
    logger.debug response.body if response.headers['Content-Type'].to_s =~ /text|xml|charset|json/i
    logger.debug "<==="
  end
end
