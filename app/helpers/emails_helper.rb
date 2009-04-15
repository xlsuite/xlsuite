#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module EmailsHelper
  def initialize_email_inbox_grid
    %Q`
    var inboxGridPanel = new Ext.grid.GridPanel({
      title:"Inbox",
      store:store,
      header:false,
      cm: new Ext.grid.ColumnModel([
        {dataIndex:"from", sortable:false},
        {dataIndex:"subject_with_body", sortable:false},
        {dataIndex:"date", sortable:false}
      ])
    });
    `
  end
  
  def ccs_and_bccs_items
    out = ""
    unless @envelope.ccs_name_with_address.empty?
      out <<
        %Q`
        ,{html:"Cc"}, {html:":"}
        ,{html:#{html_escape(@envelope.ccs_name_with_address.join(",")).to_json}}
        `
    end
    unless @envelope.bccs_name_with_address.empty? 
      out <<
        %Q`
        ,{html:"Bcc"}, {html:":"}
        ,{html:#{html_escape(@envelope.bccs_name_with_address.join(",")).to_json}}
        `
    end
    out
  end

  def open_email_after_render
    out = ""
    if @email_to_open
      out = %Q`
        xl.email.asyncLoadMessage(#{@email_to_open}, messagePanelId);
      `
    end
    out
  end
  
  def truncated_mail_text(email)
    text = [email.formatted_subject, email.body]
    text.collect! {|s| h(s)}
    truncate(text.join(" &mdash; "), 60)
  end
  
  def generateEmailLabelPanels
    javascript_block = ""
    current_user.email_labels.each do |label|
      javascript_block << 
      %Q`
        $('updaterDump').innerHTML += '<div id="xl.email.gridPanel.#{label.name}"></div>';
        tabPanel.add(xl.email.generateMailboxPanel('#{label.name}', [
          {id: 'sender_name', dataIndex: 'sender_name', header: "From", sortable: true, renderer: xl.email.senderNameRenderer},
          {id: 'to_names', dataIndex: 'to_names', header: "To", sortable: true},
          {id: 'subject', dataIndex: 'subject', header: "Subject", sortable: true},
          {id: 'sent_at', dataIndex: 'sent_at', header: "Date Sent", sortable: true, renderer: xl.email.dateRenderer },
          {id: 'received_at', dataIndex: 'received_at', header: "Date Received", sortable: true, renderer: xl.email.dateRenderer }
          ], messagePanelId)
        );
      `
    end
    javascript_block
  end
  
  def no_permission_warning_message
    if !current_user.can?(:send_mail)
      %Q`
        Ext.Msg.alert("WARNING!", "You do not have permission to send emails.");
      `
    end
  end
end
