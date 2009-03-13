#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class RetsMetadataUpdator < RetsFuture
  def run_rets(rets)
    rets.lookup(:system, "*") do |data|
      data.each_with_index do |metadata, index|
        update_status!(index, data.size)

        name = []
        name << metadata.type
        name << metadata.attributes["Resource"]
        name << metadata.attributes["Class"]
        name << metadata.attributes["Lookup"]
        name = name.compact.join(":")

        meta = RetsMetadata.find_or_initialize_by_name(name)
        meta.version = metadata.attributes["Version"]
        meta.date = Time.parse(metadata.attributes["Date"])
        meta.values = metadata
        meta.save!
      end
    end
  end

  def update_status!(index, total_count)
    percent_done = index.to_f / total_count
    percent_done *= (100 - progress)
    status!(:saving, (progress + percent_done).to_i)
  end
end
