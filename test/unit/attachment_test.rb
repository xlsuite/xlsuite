require File.dirname(__FILE__) + '/../test_helper'

class AttachmentUploadTest < Test::Unit::TestCase
  ATTACHMENT_ROOT = File.join(fixture_path, 'attachments')

  def setup
    @account = Account.find(:first)
    @asset = Asset.create!(:account => @account, :uploaded_data => fixture_file_upload('attachments/optional-scope-contracts.pdf', 'application/pdf'), :filename => "optional-scope-contracts.pdf")
    @attachment = Attachment.create!(
        :asset => @asset,
        :email => emails(:first))
  end
   
  def test_sets_attachment_size
    assert_equal File.size(File.join(ATTACHMENT_ROOT, 'optional-scope-contracts.pdf')), @attachment.size
  end

  def test_attachment_filename
    assert_equal 'optional-scope-contracts.pdf', @attachment.filename
  end

  def test_sets_attachement_content_type
    assert_equal 'application/pdf', @attachment.content_type
  end
end
