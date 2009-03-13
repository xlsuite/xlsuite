#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module SuitesHelper
  def install_explanation_message
    %Q`
      <div class='suite-install-explanation'><b>FREE</b> install of our suite for 90 days</div>
      <ul class='suite-install-explanation'>3 <b>EASY</b> steps to install a suite:
        <li>1. Select a suite and click the "NEXT STEP" button</li>
        <li>2. Select a domain to install to and press the "INSTALL"</li>
        <li>3. Step 3, there is no step 3 hehe.. Told you it's easy</li>
      </ul>
    `.gsub(/\s{2,}/i,"")
  end
  
  def initialize_suite_install_grid
    suites_url_json = formatted_public_suites_path(:format => :json).to_json
    limit = params[:limit] || 50
    %Q`
      var selectedIds = null;
      
      // create file record
      var SuiteRecord = new Ext.data.Record.create([
        {name: 'id', mapping: 'id'},
        {name: 'name', mapping: 'name'},
        {name: 'demo_url', mapping: 'demo_url'},
        {name: 'setup_fee', mapping: 'setup_fee'},
        {name: 'subscription_fee', mapping: 'subscription_fee'},
        {name: 'designer_name', mapping: 'designer_name'},
        {name: 'installed_count', mapping: 'installed_count'},
        {name: 'rating', mapping: 'rating'},
        {name: 'main_image_url', mapping: 'main_image_url'},
        {name: 'tag_list', mapping: 'tag_list'},
        {name: 'features_list', mapping: 'features_list'},
        {name: 'approved', mapping: 'approved'},
        {name: 'f_blogs', mapping: 'f_blogs'},
        {name: 'f_directories', mapping: 'f_directories'},
        {name: 'f_forums', mapping: 'f_forums'},
        {name: 'f_product_catalog', mapping: 'f_product_catalog'},
        {name: 'f_profiles', mapping: 'f_profiles'},
        {name: 'f_real_estate_listings', mapping: 'f_real_estate_listings'},
        {name: 'f_rss_feeds', mapping: 'f_rss_feeds'},
        {name: 'f_testimonials', mapping: 'f_testimonials'},
        {name: 'f_cms', mapping: 'f_cms'},
        {name: 'f_workflows', mapping: 'f_workflows'}
      ]);
      
      // data reader to parse the json response
      var reader = new Ext.data.JsonReader({totalProperty: "total", root: "collection", id: "id"}, SuiteRecord);

      // set up connection of the data
      var connection = new Ext.data.Connection({url: #{suites_url_json}, method: 'get'});
      var proxy = new Ext.data.HttpProxy(connection);

      // set up the data store and then send request to the server
      var ds = new Ext.data.Store({proxy: proxy, reader: reader, remoteSort: true, baseParams: {query: ''}});

      // set up the ext grid object
      var xg = Ext.grid;

      // define paging toolbar that is going to be appended to the footer of the grid panel
      var paging = new Ext.PagingToolbar({
        store: ds,
        pageSize: #{limit},
        displayInfo: true,
        displayMsg: 'Displaying {0} to {1} of {2}',
        emptyMsg: "No record to display",
        cls: "bottom-toolbar paging-toolbar-bottom",
        plugins: [new Ext.ux.PageSizePlugin]
      });
      
      #{create_grid_tbar_filter_field}
      
      #{create_grid_tbar_clear_button}

      var gridTopToolbar = new Ext.Toolbar({
        cls: "top-toolbar",
        items: [{text:"&nbsp;&nbsp;&nbsp;Filter: "}, filterField]
      });
      
      var demoUrlRenderer = function(value, metaData, record, rowIndex, colIndex, store){
        var text = "<a href='" + value + "' target='_blank'>" + value + "</a>"
        return(text);
      };
      
      var grid = new Ext.grid.GridPanel({
        store: ds,
        cm: new Ext.grid.ColumnModel([
            {id: "suite-name", header: "Name", sortable: true, dataIndex: 'name'},
            {id: "suite-demo_url", header: "Demo url", renderer:demoUrlRenderer, sortable: false, dataIndex: 'demo_url'},
            {id: "suite-subscription_fee", header: "Subscription fee", sortable: false, dataIndex: 'subscription_fee'},
            {id: "suite-setup_fee", header: "Setup fee", sortable: false, dataIndex: 'setup_fee'},
            {id: "suite-installed_count", header: "# installed", sortable: false, dataIndex: 'installed_count'},
            {id: "suite-approved", header: "Approved", sortable: false, dataIndex: 'approved'},
            {id: "suite-designer_name", header: "Designer", sortable: false, dataIndex: 'designer_name'},
            {id: "suite-tag_list", header: "Tags", sortable: false, dataIndex: 'tag_list'},
            {id: "suite-features_list", header: "Features", sortable: false, dataIndex: 'features_list'}
          ]),
        autoScroll: true,
        autoWidth: true,
        height: 250,
        tbar: gridTopToolbar, 
        bbar: paging,
        selModel: new Ext.grid.RowSelectionModel({singleSelect:true}),
        loadMask: true,
        viewConfig: { autoFill: true, forceFit: true},
        listeners: {
          rowclick: function(cpt, rowIndex, event){
            var record = ds.getAt(rowIndex);
            selectedSuiteField.setValue(record.get("name"));
            selectedSuiteId = record.get("id");
            step1NextButton.setDisabled(false);
          },
          render: function(cpt){
            ds.load();
          }
        }
      });
    `
  end
  
  def initialize_suite_install_selected_suite_panel
    %Q`
      var selectedSuiteId = null;
      
      var selectedSuiteField = new Ext.form.TextField({
        fieldLabel:"Your selected suite",
        disabled:true,
        width:300,
        value:"Please select a suite"
      });
      
      var step1NextButton = new Ext.Button({
        disabled:true,
        text:"NEXT STEP | Step 2: Choose existing domain or install a new one",
        handler:function(btn){
          step2PanelContainer.show();
        }
      });
    
      var selectedSuitePanel = new Ext.Panel({
        layout:"form",
        labelWidth:150,
        items:[selectedSuiteField,step1NextButton],
        height:60
      });
    `
  end
  
  def initialize_suite_install_step2_panel
    domain_name_list = self.current_account.domains.map(&:name)
    domain_name_list_with_xlsuite = domain_name_list + ["xlsuite.com"]
    %Q`
      var domainAvailable = false;
      var newDomainName = "";
      var domainList = #{(["New domain"] + domain_name_list).to_json};
      var realDomainList = #{domain_name_list_with_xlsuite.to_json};
      
      var disableEnableInstallButton = function(){
        if(selectedSuiteId){
          installButton.setDisabled(!domainAvailable);
        }
        else{
          installButton.setDisabled(true);
        }
      };
      
      var updateNewDomainNameWithTwoFields = function(){
        newDomainName = newDomainField.getValue() + "." + domainPickerComboBox.getValue();
      };
      
      var updateDomainCheckerMessage = function(){
        var messageContainer = document.getElementById("suite-install-domain-checker-message");
        if(domainAvailable){
          messageContainer.innerHTML = newDomainName + " is available";
        }
        else{
          messageContainer.innerHTML = newDomainName + " is not valid";
        }
      };
      
      var clearDomainCheckerMessage = function(){
        document.getElementById("suite-install-domain-checker-message").innerHTML = "";
      };
      
      var performAjaxCheck = function(){
        var valid = true;
        if((newDomainName.charAt(0) == ".") || (newDomainName.indexOf(" ") != -1)){
          valid = false;
        }
        if(valid)
        {
          Ext.Ajax.request({
            url:#{check_public_domains_path.to_json},
            method:"post",
            params:{name:newDomainName},
            success:function(response, options){
              var response = Ext.decode(response.responseText);
              domainAvailable = !response.taken;
              updateDomainCheckerMessage();
              disableEnableInstallButton();
            }
          });
        }
        else{
          domainAvailable = false;
          updateDomainCheckerMessage();
          disableEnableInstallButton();
        }
      };
      
      var installButton = new Ext.Button({
        text:"INSTALL",
        disabled:true,
        handler:function(btn){
          console.log("INSTALL BUTTON CLICKED");
          console.log("new domain name is %o", newDomainName);
        }
      });
      
      var selectionDomainComboBox = new Ext.form.ComboBox({
        fieldLabel: "Install to",
        name:"domain[name]",
        store:domainList,
        forceSelection:true,
        editable:false,
        width:250,
        listWidth:250,
        triggerAction:"all",
        value:"New domain",
        mode:"local",
        listeners:{
          select:function(cpt, record, selectedIndex){
            if(domainList[selectedIndex]=="New domain"){
              newDomainField.setDisabled(false);
              domainPickerComboBox.setDisabled(false);
              updateNewDomainNameWithTwoFields();
              domainAvailable = false;
              disableEnableInstallButton();
              performAjaxCheck();
              clearDomainCheckerMessage();
            }
            else{
              newDomainField.setDisabled(true);
              domainPickerComboBox.setDisabled(true);
              newDomainName = domainList[selectedIndex];
              clearDomainCheckerMessage();
              domainAvailable = true;
              disableEnableInstallButton();
            }
          }
        }
      });
      
      var newDomainField = new Ext.form.TextField({
        width:100,
        value:"",
        enableKeyEvents:true,
        listeners:{
          keyup:function(cpt, event){
            updateNewDomainNameWithTwoFields();
            performAjaxCheck();
          }
        }
      });
      
      var domainPickerComboBox = new Ext.form.ComboBox({
        width:200,
        listWidth:200,
        store:realDomainList,
        forceSelection:true,
        editable:false,
        triggerAction:"all",
        mode:"local",
        value:#{domain_name_list_with_xlsuite.first.to_json},
        listeners:{
          select:function(cpt, record, selectedIndex){
            updateNewDomainNameWithTwoFields();
            performAjaxCheck();
          }
        }
      });
      
      var domainCheckerMessage = new Ext.Panel({
        html:"<span id='suite-install-domain-checker-message'></span>"
      });
      
      var step2Panel = new Ext.Panel({
        layout:"column",
        items:[
          {layout:"form", labelWidth:70, width:350, items:selectionDomainComboBox},
          {items:newDomainField, width:100},
          {html:"<span align='center'><b>.</b></span>", width:10},
          {items:domainPickerComboBox, width:225},
        ]
      });
      
      var step2PanelContainer = new Ext.Panel({
        height:95,
        hidden:true,
        title:"Step 2: Select your existing domain to install to or just register a new one for FREE",
        items:[step2Panel, domainCheckerMessage, installButton]
      });
    `
  end
end
