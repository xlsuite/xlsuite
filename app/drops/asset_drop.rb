#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "action_view/helpers/number_helper"
require "erb"

class AssetDrop < Liquid::Drop
  include ActionView::Helpers::NumberHelper
  include ERB::Util

  delegate :id, :filename, :title, :description, :width, :height, :content_type, :size, :file_extension, :label, 
    :shockwave_file?, :audio_file?, :flash_file?, :flv_file?, :mp3_file?, :pictures, :images, :src, :z_src, :folder,
    :to => :asset
  attr_reader :asset

  def initialize(asset)
    @asset = asset
  end

  Asset::THUMBNAIL_SIZES.merge(:full => "").keys.each do |name|
    class_eval <<-EOF
      def as_#{name}_image_tag
        thumbnail(#{name.inspect}).as_image_tag
      end

      def as_#{name}_download_link
        thumbnail(#{name.inspect}).as_download_link
      end

      def #{name}_src
        thumbnail(#{name.inspect}).src
      end
      
      def #{name}?
        asset.thumbnails.find_by_thumbnail('#{name}') ? true : false
      end
      
      alias_method :#{name}_download_url, :#{name}_src
      alias_method :#{name}_download_src, :#{name}_src
      alias_method :#{name}_url, :#{name}_src
      alias_method :#{name}, :#{name}?
    EOF
  end
  
  alias_method :download_url, :src
  alias_method :download_src, :src
  alias_method :url, :src

  def thumbnail(name)
    asset.find_or_initialize_thumbnail(name).to_liquid
  end
  
  def as_image_tag
    %Q(<img src="#{self.src}" alt="#{html_escape(asset.title)}"/>)
  end

  def as_download_link
    %Q(<a href="#{self.src}"><span class="icon"><img src="/images/icons/#{asset.icon}.png" alt=""/></span> #{html_escape(asset.filename)} <span class="size">#{number_to_human_size(asset.size)}</span></a>)
  end
end
