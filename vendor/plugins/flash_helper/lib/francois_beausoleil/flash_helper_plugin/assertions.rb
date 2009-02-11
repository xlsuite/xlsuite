module FrancoisBeausoleil #:nodoc
  module FlashHelperPlugin #:nodoc
    module Assertions
      # Asserts that +string_or_regexp+ can be found in the flash under
      # one of <tt>:notice</tt>, <tt>:message</tt> or <tt>:warning</tt> keys.
      def assert_any_flash_contains(string_or_regexp, msg=nil)
        contents = []
        contents << flash_contents(:notice)
        contents << flash_contents(:message)
        contents << flash_contents(:warning)

        assert_in_contents(string_or_regexp, contents.join("\n"), msg)
      end

      # Asserts that +string_or_regexp+ cannot be found in the flash under
      # one of <tt>:notice</tt>, <tt>:message</tt> or <tt>:warning</tt> keys.
      def assert_any_flash_does_not_contain(string_or_regexp, msg=nil)
        contents = []
        contents << flash_contents(:notice)
        contents << flash_contents(:message)
        contents << flash_contents(:warning)

        assert_not_in_contents(string_or_regexp, contents.join("\n"), msg)
      end

      # Asserts that +string_or_regexp+ can be found in the flash under
      # key <tt>:warning</tt>.
      def assert_warning_flash_contains(string_or_regexp, msg=nil)
        assert_flash_contains :warning, string_or_regexp, msg
      end
      alias :assert_failure_flash_contains :assert_warning_flash_contains

      # Asserts that +string_or_regexp+ cannot be found in the flash under
      # key <tt>:warning</tt>.
      def assert_warning_flash_does_not_contain(string_or_regexp, msg=nil)
        assert_flash_does_not_contain :warning, string_or_regexp, msg
      end
      alias :assert_failure_flash_does_not_contain :assert_warning_flash_does_not_contain

      # Asserts that +string_or_regexp+ can be found in the flash under
      # key <tt>:notice</tt>.
      def assert_success_flash_contains(string_or_regexp, msg=nil)
        assert_flash_contains :notice, string_or_regexp, msg
      end

      # Asserts that +string_or_regexp+ cannot be found in the flash under
      # key <tt>:notice</tt>.
      def assert_success_flash_does_not_contain(string_or_regexp, msg=nil)
        assert_flash_does_not_contain :notice, string_or_regexp, msg
      end

      # Asserts that +string_or_regexp+ can be found in the flash under
      # key <tt>:message</tt>.
      def assert_message_flash_contains(string_or_regexp, msg=nil)
        assert_flash_contains :message, string_or_regexp, msg
      end

      # Asserts that +string_or_regexp+ cannot be found in the flash under
      # key <tt>:message</tt>.
      def assert_message_flash_does_not_contain(string_or_regexp, msg=nil)
        assert_flash_does_not_contain :message, string_or_regexp, msg
      end

      # Asserts that +string_or_regexp+ can be found in the flash under
      # key +key+.
      def assert_flash_contains(key, string_or_regexp, msg=nil)
        message = " under flash key <#{key}>"
        message << ": #{msg}" if msg
        assert_in_contents(string_or_regexp, flash_contents(key), message)
      end

      # Asserts that +string_or_regexp+ cannot be found in the flash under
      # key +key+.
      def assert_flash_does_not_contain(key, string_or_regexp, msg=nil)
        message = " under flash key <#{key}>"
        message << ": #{msg}" if msg
        assert_not_in_contents(string_or_regexp, flash_contents(key), message)
      end

      # Asserts that +string_or_regexp+ matches +contents+
      def assert_in_contents(string_or_regexp, contents, msg=nil)
        message = "Expected to find <#{string_or_regexp.inspect}>
              in <#{contents.inspect}>"
        message << ": #{msg}" if msg
        assert_block(message) do
          case string_or_regexp
          when String
            Regexp.new(Regexp.escape(string_or_regexp)) === contents
          when Regexp
            string_or_regexp === contents
          else
          end
        end
      end

      # Asserts that +string_or_regexp+ does not match +contents+
      def assert_not_in_contents(string_or_regexp, contents, msg=nil)
        message = "Expected NOT to find <#{string_or_regexp.inspect}>
                  in <#{contents.inspect}>"
        message << ": #{msg}" if msg
        assert_block(message) do
          !(string_or_regexp === contents)
        end
      end

      # Returns the flash contents as a string, even if the contents was an
      # Array.
      def flash_contents(key)
        [flash[key], flash.now[key]].flatten.join("\n").chomp
      end

      def assert_flash_message_displayed(key, message)
        flash_list_tag = {
          :tag => 'li',
          :attributes => {:class => key.to_s},
          :parent => {
            :tag => 'ul',
            :attributes => {:class => key.to_s.pluralize}
            }
          }
        assert_tag :tag => 'p', :content => message, :parent => flash_list_tag
      end

    end
  end
end

class Test::Unit::TestCase
  include FrancoisBeausoleil::FlashHelperPlugin::Assertions
  extend FrancoisBeausoleil::FlashHelperPlugin::Assertions
end
