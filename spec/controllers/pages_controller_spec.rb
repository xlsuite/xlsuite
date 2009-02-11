require File.dirname(__FILE__) + '/../spec_helper'

GOOGLEBOT_USER_AGENT = "Mozilla/5.0 (compatible; Googlebot/2.1;  http://www.google.com/bot.html)"

describe PagesController do
  it_should_behave_like "All controllers"
  integrate_views
  
  it "with sessions turned off should not break for robots" do
    request.stub!(:user_agent).and_return(GOOGLEBOT_USER_AGENT)
    get :index
  end
end
