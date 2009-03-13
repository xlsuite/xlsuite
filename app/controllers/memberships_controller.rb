#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class MembershipsController < ApplicationController
  required_permissions :edit_party_security
  verify :method => %w(post delete),
      :render => {:status => "406 Method Not Allowed",
          :inline => "<h1>406 Method Not Allowed</h1><p>This resource does not understand the method you sent it.</p>"}

  def update
    @party = Party.find(params[:party_id])
    @group = Group.find(params[:group_id])

    case request.method
    when :post
      @party.groups << @group
    when :delete
      @party.groups.delete(@group)
    end
    @party.update_effective_permissions = true
    @party.save

    respond_to do |format|
      format.js { render :partial => "permission_grants/reset_effective_permissions" }
    end
  end
end
