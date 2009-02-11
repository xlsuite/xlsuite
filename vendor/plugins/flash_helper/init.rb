require 'francois_beausoleil/flash_helper_plugin/application'
require 'francois_beausoleil/flash_helper_plugin/application_helper'

ActionController::Base.send(:include, FrancoisBeausoleil::FlashHelperPlugin::ApplicationController)
ActionView::Base.send(:include, FrancoisBeausoleil::FlashHelperPlugin::ApplicationHelper)
