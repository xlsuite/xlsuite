require 'test/unit'
require 'feed_tools'
require 'feed_tools/helpers/feed_tools_helper'

class AmpTest < Test::Unit::TestCase
  include FeedTools::FeedToolsHelper
  
  def setup
    FeedTools.reset_configurations
    FeedTools.configurations[:tidy_enabled] = false
    FeedTools.configurations[:feed_cache] = "FeedTools::DatabaseFeedCache"
    FeedTools::FeedToolsHelper.default_local_path = 
      File.expand_path(
        File.expand_path(File.dirname(__FILE__)) + '/../feeds')
  end

  def test_amp_01
    with_feed(:from_file => 'wellformed/amp/amp01.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end
  
  def test_amp_02
    with_feed(:from_file => 'wellformed/amp/amp02.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end
  
  def test_amp_03
    with_feed(:from_file => 'wellformed/amp/amp03.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end
  
  def test_amp_04
    with_feed(:from_file => 'wellformed/amp/amp04.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_05
    with_feed(:from_file => 'wellformed/amp/amp05.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_06
    with_feed(:from_file => 'wellformed/amp/amp06.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_07
    with_feed(:from_file => 'wellformed/amp/amp07.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_08
    with_feed(:from_file => 'wellformed/amp/amp08.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_09
    with_feed(:from_file => 'wellformed/amp/amp09.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_10
    with_feed(:from_file => 'wellformed/amp/amp10.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_11
    with_feed(:from_file => 'wellformed/amp/amp11.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_12
    with_feed(:from_file => 'wellformed/amp/amp12.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_13
    with_feed(:from_file => 'wellformed/amp/amp13.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_14
    with_feed(:from_file => 'wellformed/amp/amp14.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_15
    with_feed(:from_file => 'wellformed/amp/amp15.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_16
    with_feed(:from_file => 'wellformed/amp/amp16.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_17
    with_feed(:from_file => 'wellformed/amp/amp17.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_18
    with_feed(:from_file => 'wellformed/amp/amp18.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_19
    with_feed(:from_file => 'wellformed/amp/amp19.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_20
    with_feed(:from_file => 'wellformed/amp/amp20.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_21
    with_feed(:from_file => 'wellformed/amp/amp21.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_22
    with_feed(:from_file => 'wellformed/amp/amp22.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_23
    with_feed(:from_file => 'wellformed/amp/amp23.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_24
    with_feed(:from_file => 'wellformed/amp/amp24.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_25
    with_feed(:from_file => 'wellformed/amp/amp25.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_26
    with_feed(:from_file => 'wellformed/amp/amp26.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_27
    with_feed(:from_file => 'wellformed/amp/amp27.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_28
    with_feed(:from_file => 'wellformed/amp/amp28.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_29
    with_feed(:from_file => 'wellformed/amp/amp29.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_30
    with_feed(:from_file => 'wellformed/amp/amp30.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_31
    with_feed(:from_file => 'wellformed/amp/amp31.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_32
    with_feed(:from_file => 'wellformed/amp/amp32.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_33
    with_feed(:from_file => 'wellformed/amp/amp33.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_34
    with_feed(:from_file => 'wellformed/amp/amp34.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_35
    with_feed(:from_file => 'wellformed/amp/amp35.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_36
    with_feed(:from_file => 'wellformed/amp/amp36.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_37
    with_feed(:from_file => 'wellformed/amp/amp37.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_38
    with_feed(:from_file => 'wellformed/amp/amp38.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_39
    with_feed(:from_file => 'wellformed/amp/amp39.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_40
    with_feed(:from_file => 'wellformed/amp/amp40.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_41
    with_feed(:from_file => 'wellformed/amp/amp41.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_42
    with_feed(:from_file => 'wellformed/amp/amp42.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_43
    with_feed(:from_file => 'wellformed/amp/amp43.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_44
    with_feed(:from_file => 'wellformed/amp/amp44.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_45
    with_feed(:from_file => 'wellformed/amp/amp45.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_46
    with_feed(:from_file => 'wellformed/amp/amp46.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_47
    with_feed(:from_file => 'wellformed/amp/amp47.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_48
    with_feed(:from_file => 'wellformed/amp/amp48.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_49
    with_feed(:from_file => 'wellformed/amp/amp49.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_50
    with_feed(:from_file => 'wellformed/amp/amp50.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_51
    with_feed(:from_file => 'wellformed/amp/amp51.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_52
    with_feed(:from_file => 'wellformed/amp/amp52.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_53
    with_feed(:from_file => 'wellformed/amp/amp53.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_54
    with_feed(:from_file => 'wellformed/amp/amp54.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_55
    with_feed(:from_file => 'wellformed/amp/amp55.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_56
    with_feed(:from_file => 'wellformed/amp/amp56.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_57
    with_feed(:from_file => 'wellformed/amp/amp57.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_58
    with_feed(:from_file => 'wellformed/amp/amp58.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_59
    with_feed(:from_file => 'wellformed/amp/amp59.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_60
    with_feed(:from_file => 'wellformed/amp/amp60.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_61
    with_feed(:from_file => 'wellformed/amp/amp61.xml') { |feed|
      assert_equal("<b>&amp;</b>", feed.entries.first.title)
    }
  end

  def test_amp_62
    with_feed(:from_file => 'wellformed/amp/amp62.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_63
    with_feed(:from_file => 'wellformed/amp/amp63.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_64
    with_feed(:from_file => 'wellformed/amp/amp64.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end
  
  def test_amp_65
    with_feed(:from_data => <<-FEED
      <feed version="0.3">
        <title>&lt;strong>1 &amp;amp; 2 &amp; 3&lt;/strong></title>
        <tagline>&lt;strong>1 &amp;amp; 2 &amp; 3&lt;/strong></tagline>
    	  <entry>
          <title>&lt;strong>1 &amp;amp; 2 &amp; 3&lt;/strong></title>
          <content>&lt;strong>1 &amp;amp; 2 &amp; 3&lt;/strong></content>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&lt;strong&gt;1 &amp;amp; 2 &amp; 3&lt;/strong&gt;",
        feed.title)
      assert_equal("&lt;strong&gt;1 &amp;amp; 2 &amp; 3&lt;/strong&gt;",
        feed.tagline)
      assert_equal("&lt;strong&gt;1 &amp;amp; 2 &amp; 3&lt;/strong&gt;",
        feed.entries.first.title)
      assert_equal("&lt;strong&gt;1 &amp;amp; 2 &amp; 3&lt;/strong&gt;",
        feed.entries.first.content)
    }
  end

  def test_amp_tidy_01
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp01.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end
  
  def test_amp_tidy_02
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp02.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end
  
  def test_amp_tidy_03
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp03.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end
  
  def test_amp_tidy_04
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp04.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_05
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp05.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_06
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp06.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_07
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp07.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_08
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp08.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_09
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp09.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_10
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp10.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_11
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp11.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_12
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp12.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_13
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp13.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_14
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp14.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_15
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp15.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_16
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp16.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_17
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp17.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_18
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp18.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_19
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp19.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_20
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp20.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_21
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp21.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_22
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp22.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_23
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp23.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_24
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp24.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_25
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp25.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_26
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp26.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_27
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp27.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_28
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp28.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_29
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp29.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_30
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp30.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_31
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp31.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_32
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp32.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_33
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp33.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_34
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp34.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_35
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp35.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_36
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp36.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_37
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp37.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_38
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp38.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_39
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp39.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_40
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp40.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_41
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp41.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_42
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp42.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_43
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp43.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_44
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp44.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_45
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp45.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_46
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp46.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_47
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp47.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_48
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp48.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_49
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp49.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_50
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp50.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_51
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp51.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_52
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp52.xml') { |feed|
      assert_equal("&amp;", feed.entries.first.title)
    }
  end

  def test_amp_tidy_53
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp53.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_54
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp54.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_55
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp55.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_56
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp56.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_57
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp57.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_58
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp58.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_59
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp59.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_60
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp60.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_61
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp61.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_62
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp62.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_63
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp63.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end

  def test_amp_tidy_64
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_file => 'wellformed/amp/amp64.xml') { |feed|
      assert_equal("<strong>&amp;</strong>", feed.entries.first.title)
    }
  end
  
  def test_amp_tidy_65
    FeedTools.configurations[:tidy_enabled] = true
    assert_equal(true, FeedTools::HtmlHelper.tidy_enabled?,
      "Could not enable tidyhtml, library may be missing.")
    with_feed(:from_data => <<-FEED
      <feed version="0.3">
        <title>&lt;strong>1 &amp;amp; 2 &amp; 3&lt;/strong></title>
        <tagline>&lt;strong>1 &amp;amp; 2 &amp; 3&lt;/strong></tagline>
    	  <entry>
          <title>&lt;strong>1 &amp;amp; 2 &amp; 3&lt;/strong></title>
          <content>&lt;strong>1 &amp;amp; 2 &amp; 3&lt;/strong></content>
        </entry>
      </feed>
    FEED
    ) { |feed|
      assert_equal("&lt;strong&gt;1 &amp;amp; 2 &amp; 3&lt;/strong&gt;",
        feed.title)
      assert_equal("&lt;strong&gt;1 &amp;amp; 2 &amp; 3&lt;/strong&gt;",
        feed.tagline)
      assert_equal("&lt;strong&gt;1 &amp;amp; 2 &amp; 3&lt;/strong&gt;",
        feed.entries.first.title)
      assert_equal("&lt;strong&gt;1 &amp;amp; 2 &amp; 3&lt;/strong&gt;",
        feed.entries.first.content)
    }
  end
end