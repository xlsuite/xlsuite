require "time"


module Scraper

  module Microformats

    class HCard < Scraper::Base

      process ".fn",          :fn=>:text
      process ".given-name",  :given_name=>:text
      process ".family-name", :family_name=>:text
      process "img.photo",    :photo=>"@src"
      process "a.url",        :url=>"@href"

      result :fn, :given_name, :family_name, :photo, :url

      def collect()
        unless fn
          if self.fn = given_name
            self.given_name << " #{family_name}" if family_name
          else
            self.fn = family_name
          end
        end
      end

    end


    class HAtom < Scraper::Base

      class Entry < Scraper::Base

        array :content, :tags

        process ".entry-title",                   :title=>:text
        process ".entry-content",                 :content=>:element
        process ".entry-summary",                 :summary=>:element
        process "a[rel~=bookmark]",               :permalink=>["@href"]
        process ".author.vcard, .author .vcard",  :author=>HCard
        process ".published",                     :published=>["abbr@title", :text]
        process ".updated",                       :updated=>["abbr@title", :text]
        process "a[rel~=tag]",                    :tags=>:text

        def collect()
          self.published = Time.parse(published)
          self.updated = updated ? Time.parse(updated) : published
        end

        result :title, :content, :summary, :permalink, :author, :published, :updated, :tags

      end

      class Feed < Scraper::Base

        array :entries

        process ".hentry", :entries=>Entry

        def result()
          entries
        end

      end

      array :feeds, :entries

      # Skip feeds, so we don't process them twice.
      process ".hfeed", :skip=>true, :feeds=>Feed
      # And so we can collect unwrapped entries into a separate feed.
      process ".hentry", :skip=>true, :entries=>Entry
      # And collect the first remaining hcard as the default author.
      process ".vcard", :hcard=>HCard

      def collect()
        @feeds ||= []
        @feeds << entries if entries
        for feed in feeds
          for entry in feed
            entry.author = hcard unless entry.author
          end 
        end
      end

      result :feeds

    end

  end

end

