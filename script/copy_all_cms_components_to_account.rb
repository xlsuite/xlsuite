# This script is used to copy all cms components of an account to another.
# Three input parameters are needed:
#   - Source account domain name: one of the domains in the source account
#     This domain name will be used to set the domain patterns of all the copies.
#   - Domain match flag: "yes", "y", "no", "n" case insensitive
#     If set only cms components that contains the source domain name are 
#     included, otherwise all cms components are included.
#   - Target account domain name: one of the domains in the target account

require "main"

def copy(source_domain, target_domain, options)
  source_account = source_domain.account
  target_account = target_domain.account
  begin
  ActiveRecord::Base.transaction do
    puts "==> Copying pages now ..."
    new_item = nil
    source_account.pages.each do |page|
      if options[:domain_match]
        next unless page.domain_patterns.index(source_domain.name)
      end
      puts "Processing #{page.class.name} '#{page.title}' with fullslug '#{page.fullslug}' and domain patterns '#{page.domain_patterns}'"
      attr_options = {:domain_patterns => options[:copy_domain_patterns] ? page.domain_patterns : source_domain.name}
      attr_options.merge!(:uuid => page.uuid, :modified => page.modified) if options[:copy_uuid]
      new_item = page.class.create!(page.attributes_for_copy_to(target_account, attr_options))
      puts "#{page.class.name} title '#{new_item.title}' with fullslug '#{new_item.fullslug}' and domain patterns '#{new_item.domain_patterns}' successfully created"
    end

    puts "==> Copying snippets now ..."
    source_account.snippets.each do |snippet|
      if options[:domain_match]
        next unless snippet.domain_patterns.index(source_domain.name)
      end
      puts "Processing Snippet '#{snippet.title}' with domain patterns '#{snippet.domain_patterns}'"
      attr_options = {:domain_patterns => options[:copy_domain_patterns] ? snippet.domain_patterns : source_domain.name}
      attr_options.merge!(:uuid => snippet.uuid, :modified => snippet.modified) if options[:copy_uuid]
      new_item = Snippet.new(snippet.attributes_for_copy_to(target_account, attr_options))
      new_item.ignore_warnings = true
      saved = new_item.save!
      puts "Snippet title '#{new_item.title}' with domain patterns '#{new_item.domain_patterns}' created"
    end

    puts "==> Copying layouts now ..."
    source_account.layouts.each do |layout|
      if options[:domain_match]
        next unless layout.domain_patterns.index(source_domain.name)
      end
      puts "Processing Layout '#{layout.title}' with domain patterns '#{layout.domain_patterns}'"
      attr_options = {:domain_patterns => options[:copy_domain_patterns] ? layout.domain_patterns : source_domain.name}
      attr_options.merge!(:uuid => layout.uuid, :modified => layout.modified) if options[:copy_uuid]
      new_item = Layout.create!(layout.attributes_for_copy_to(target_account, attr_options))
      puts "Layout title '#{new_item.title}' with domain patterns '#{new_item.domain_patterns}' created"
    end
    
    puts "==> OPERATION COMPLETED"
  end
  rescue
    puts $!.to_s
    puts $!.backtrace
  end
end

Main do
  argument("source_domain") { required }
  argument("domain_patterns_include_source_domain") { required }
  argument("target_domain") { required }
  argument("copy_domain_pattern") { required }
  argument("copy_uuid") { required }
  def run
    source_domain_name = params["source_domain"].value
    source_domain = Domain.find_by_name(source_domain_name)
    raise "Couldn't not find domain named #{source_domain_name.inspect}" if source_domain.blank?
    
    domain_patterns_match = params["domain_patterns_include_source_domain"].value
    options = {}
    puts "Domain patterns match #{domain_patterns_match}"
    if domain_patterns_match =~ /^(yes|y)$/i 
      options[:domain_match] = true
    elsif domain_patterns_match =~ /^(no|n)$/i
      options[:domain_match] = false
    else
      raise "Please input yes/Y or no/N" if domain_patterns_match !~ /^(yes|no|n|y)$|/i
    end
    copy_domain_patterns_match = params["copy_domain_pattern"].value
    puts "Copy Domain Patterns #{copy_domain_patterns_match}"
    if copy_domain_patterns_match =~ /^(yes|y)$/i 
      options[:copy_domain_patterns] = true
    elsif copy_domain_patterns_match =~ /^(no|n)$/i
      options[:copy_domain_patterns] = false
    else
      raise "Please input yes/Y or no/N" if copy_domain_patterns_match !~ /^(yes|no|n|y)$|/i
    end
    copy_uuid_match = params["copy_uuid"].value
    puts "Copy UUID #{copy_domain_patterns_match}"
    if copy_uuid_match =~ /^(yes|y)$/i 
      options[:copy_uuid] = true
    elsif copy_uuid_match =~ /^(no|n)$/i
      options[:copy_uuid] = false
    else
      raise "Please input yes/Y or no/N" if copy_uuid_match !~ /^(yes|no|n|y)$|/i
    end

    target_domain_name = params["target_domain"].value
    target_domain = Domain.find_by_name(target_domain_name)
    raise "Couldn't not find domain named #{target_domain_name.inspect}" if target_domain.blank?

    raise "Can't copy cms components within the same account" if source_domain.account == target_domain.account
    copy(source_domain, target_domain, options)
  end
end
