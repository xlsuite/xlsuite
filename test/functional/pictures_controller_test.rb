require File.dirname(__FILE__) + '/../test_helper'
require 'pictures_controller'

# Re-raise errors caught by the controller.
class PicturesController; def rescue_action(e) raise e end; end

class PicturesControllerTest < Test::Unit::TestCase
  def setup
    @controller = PicturesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @account = Account.find(:first)
  end

  def test_show_pictures_for_current_account_only
    @alt_account = Account.new; @alt_account.expires_at = 5.minutes.from_now; @alt_account.save!
    picture = returning(Picture.build(uploaded_file('1.jpg'))) do |pict|
      pict.update_attributes(:account => @alt_account, :public => true)
    end

    assert_raises(ActiveRecord::RecordNotFound) do
      get :retrieve, :id => picture.id, :mime_type => 'image/jpeg', :format => 'JPEG'
    end
  end

  def test_show_public_picture_to_anyone
    p = Picture.build_picture_from_local_file(File.join(RAILS_ROOT, 'test', 'fixtures', 'pictures', '1.jpg'))
    p.update_attributes!(:account => @account, :public => true)

    get :retrieve, :id => p.id, :mime_type => 'image/jpeg', :format => 'JPEG'

    assert_response :success
    assert_match %r{image/jpeg}, @response.headers['Content-Type']
    assert_match /^public/, @response.headers['Cache-Control']
    assert_match /inline/, @response.headers['Content-Disposition']
    assert_match /#{p.filename}/, @response.headers['Content-Disposition']
  end

  def test_allow_retrieve_private_picture_to_authenticated_user
    p = Picture.build_picture_from_local_file(File.join(RAILS_ROOT, 'test', 'fixtures', 'pictures', '1.jpg'))
    p.update_attributes!(:account => @account)

    login!(:bob)
    get :retrieve, :id => p.id, :mime_type => 'image/jpeg', :format => 'JPEG'

    assert_response :success
    assert_match %r{image/jpeg}, @response.headers['Content-Type']
    assert_match /^private/, @response.headers['Cache-Control']
    assert_match /inline/, @response.headers['Content-Disposition']
    assert_match /#{p.filename}/, @response.headers['Content-Disposition']
  end

  def test_dont_show_private_picture_to_unauthenticated_user
    p = Picture.build_picture_from_local_file(File.join(RAILS_ROOT, 'test', 'fixtures', 'pictures', '1.jpg'))
    p.update_attributes!(:account => @account)
    assert !p.public?, 'Picture should be private by default'

    get :retrieve, :id => p.id, :mime_type => 'image/jpeg', :format => 'JPEG'

    assert_match /not found/i, @response.body
    assert_response :missing
  end
end
