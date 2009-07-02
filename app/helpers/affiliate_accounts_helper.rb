module AffiliateAccountsHelper
  def group_by_panel_content
    %Q`
      <ul id='group-by-referred-items-menu'>
        <li>
		      <img src="/javascripts/extjs/resources/images/default/s.gif" class="group-by-item">
		      <a id="group-by-item" href="#">By Item</a>
        </li>
        <li>
		      <img src="/javascripts/extjs/resources/images/default/s.gif" class="group-by-domain">
		      <a id="group-by-domain" href="#">By Domain</a>
        </li>
      </ul>
    `
  end
end
