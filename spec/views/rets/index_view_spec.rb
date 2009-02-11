require File.dirname(__FILE__) + '/../../spec_helper'

describe "/rets/index" do
  before do
    render 'rets/index'
  end
  
  #Delete this example and add some real ones or delete this file
  it "should tell you where to find the file" do
    response.should have_tag('p', 'Find me in app/views/rets/index.rhtml')
  end
end
