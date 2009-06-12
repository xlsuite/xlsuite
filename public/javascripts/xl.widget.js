Ext.namespace('xl.widget');

xl.widget = function() { };

xl.widget.debug = false;
xl.widget.badConfigTpl = 'Bad Configuration in #{widget}: #{problem}';
xl.widget.badUrlSpecTpl = 'Bad URL Specification for #{urlName} in #{widget}';
xl.widget.imagePickerDataStores = new Hash();
/*
 * Generates: A Text box, TextField and Button for a Toolbar.
 * It outputs it as an array for easy appending to a Toolbar,
 * and separately in an Object.
 *
 * Named Configuration:
 *  limit - Number - limit of records to retrieve 
 */
xl.widget.FilterFields = function(config) {
  config = config || {};
  config.limit = config.limit || 10;
  config.emptyText = config.emptyText || 'Search';
  
  var filterField = new Ext.form.TextField({selectOnFocus: true, grow: false, emptyText: config.emptyText});
  filterField.on("specialkey",
    function(field, e) {
      if (e.getKey() == Ext.EventObject.RETURN || e.getKey() == Ext.EventObject.ENTER) {
        e.preventDefault();
        config.store.baseParams['q'] = this.getValue();
        config.store.reload({params: {start: 0, limit: config.limit}});
      }
    }
  );

  // clear button for the filter field
  var clearButton = new Ext.Toolbar.Button({
    text: 'Clear',
    handler: function() {
      filterField.setValue("");
      config.store.baseParams['q'] = "";
      config.store.reload();
    }
  });
};

/*
  Generates: A string containing the URL with substitutions made
             if necessary
             
  Configuration:
    url - String or Object:
      base  - String
      sub   - String (defaults to '__ID__')
      value - String
*/
xl.widget._ParseURL = function(url) {
  if (!url) return null;
  
  if (url instanceof String)
    return url;
  else if (url instanceof Object)
    return url.base.sub((url.sub || '__ID__'), url.value);
  else
    return null;
}

/*
  Usage: Sets the update event for an editor grid panel
  
  Configuration:
    gridPanel -
    object - object[attribute] = value
    method - (defaults to 'put')
    params - 
    urlScheme - Object
      base -
      sub - (defaults to '__ID__')
      valueEval - the expression to evaluate inside the event
                  to get the value for substitution. Usually:
                  record.get('id');
*/
xl.widget.SetUpdateEventForEditorGridPanel = function(config) {
  // Check Requirements
  if (!config.gridPanel) return null;
  if (!config.object) return null;
  if (!config.urlScheme) return null;
  
  
  config.gridPanel.on('afteredit', function(editObject) {
    var params = $H({}), key = config.object + '[' + editObject.field + ']';
    params.set(key, editObject.value);
    params.set('id', editObject.record.get('id'));
    params.update(config.params || {});
    
    // Make the request to update the data db-side, and the response
    // is the confirmation
    var record = editObject.record; // shortcut for valueEval
    var value = eval(config.urlScheme.valueEval);
    
    var url = config.urlScheme.base.sub(config.urlScheme.sub || '__ID__', value);
    
    Ext.Ajax.request({
      url: url,
      method: config.method || 'put',
      params: params.toObject(),
      failure: xl.logXHRFailure,
      success: function(transport) {
        var response = Ext.util.JSON.decode(transport.responseText);
        editObject.record.set(editObject.field, response);
        if (config.after) config.after(editObject);
      }
    });
  }); // end gridPanel.on('afteredit')
}

/*
  Usage: Adds a beforeedit event to the gridPanel to check to see
         if editing is allowed on a column based on dataIndex
  
  Configuration:
    gridPanel -
    dataIndexes - An Array of Strings containing the dataIndexes of
                  the columns in which to prohibit editing
*/
xl.widget.DisallowEditingForColumnsOnEditorGridPanel = function(config) {
  // Check Requirements
  if (!config.gridPanel) return null;
  if (!config.dataIndexes) return null;
  if (!config.dataIndexes instanceof Array) return null;
  
  config.gridPanel.on('beforeedit', function(editObject) {
    var dataIndex = editObject.grid.getColumnModel().getDataIndex(editObject.column);
    if (config.dataIndexes.include(dataIndex))
      editObject.cancel = true;
  });
}

/*
 * Generates: A JSON Store that expects data in the following
 *            format: {total: X, collection:[{object}]}
 * Named Configuration:
 *  doSmartMapping(s) -
 *  baseParams - Hash
 *  fields -
 *  url - 
 *  method - 
    array or data -
 */
xl.widget.SimpleJSONStore = function(config) {
  // Check requirements
  if (!config.fields) config.fields = ['id'];
  if (!config.method) config.method = 'get';
  
  // Generate fields for a record from an array of hashes
  // of field names and types or just from a string name. A field
  // of 'id' is automatically given an 'int' type
  // Ex - ['id', {name: 'uploaded_at', type: 'date'}, 'something']
  var fields = config.fields.collect(function(field) {
    if (field instanceof String) {
      var f = {name: field};  // Basic 1:1 string field
      
      // Guess the type based on the name
      if (config.doSmartMappings || config.doSmartMapping) {
        if (field == 'id')
          f.type = 'int';
        else if (field.include('_date') || field.include('_at'))
          f.type = 'date';
      } // end if config.doSmartMappings
      
      return f;
    } else {
      return field;
    }
  });
  
  var record = new Ext.data.Record.create(fields);
  
  var reader = new Ext.data.JsonReader(
    {totalProperty: "total", root: "collection", id: "id"},
    record
  );
  
  var proxy;
  if (config.url) {
    proxy = new Ext.data.HttpProxy(new Ext.data.Connection({
      url: config.url,
      method: config.method
    })); 
  } else if (config.array || config.data) {
    //var wrapper = {total: config.array.length, collection: config.array};
    proxy = new Ext.data.MemoryProxy({total: config.array.length, collection: config.array});
  } else {
    throw new Error(xl.widget.badConfigTpl.interpolate({widget: 'SimpleJSONStore', problem: 'url or array/data are required'}));
  }
  
  var store = new Ext.data.Store({
    proxy: proxy,
    reader: reader,
    baseParams: config.baseParams || {}
  });
  
  if (config.onLoad) { store.on('load', config.onLoad, this, {single:true}); }
  if (config.doLoad) { store.load(); }

  return {
    record: record,
    store: store
  };
}

/*
  Generates: an Ext.form.Field subclass based on the supplied config
  Versions
    2/11/08 - Config is used directly by Ext.form.Field
*/
xl.widget.FormField = function(config) {
  if (xl.widget.debug) { xl.log ('In FormField for ' + config.name); }
  config.xtype = config.xtype || config.type || 'text';
  if (config.xtype == 'textfield') config.xtype = 'text'
  if(config.renderTo && config.fieldLabel)
  {
    $(config.renderTo).insert("<label>" + config.fieldLabel + ": </label>");
  }
  config.renderTo = config.renderTo || '';
  
  //var field = new Ext.form.Field(config);
  var field;
  switch (config.xtype) {
    case 'text':
      field = new Ext.form.TextField(config);
    break;
    
    case 'combobox':
      field = new Ext.form.ComboBox(config);
    break;
      
    case 'textarea':
      field = new Ext.form.TextArea(config);
    break;
    
    case 'checkbox':
      field = new Ext.form.Checkbox(config);
    break;
    
    case 'datefield':
      field = new Ext.form.DateField(config);
    break;
    
    case 'htmleditor':
      field = new Ext.ux.HtmlEditor(config);  
    
  }
  
  if (config.noFieldLabel) {
    field.labelSeparator = '';
    field.fieldLabel = '';
    field.hideLabel = true;
  }
  /*if (xl.widget.debug) { xl.log('About to set value in FormField'); }
  // Don't want to set default values, so either use
  // the supplied value or leave it alone
  if (config.width)     field.setWidth(config.width);
  if (config.height)    field.setHeight(config.height);
  if (config.editable)  field.setEditable(config.editable);
  if (config.disabled)  field.setDisabled(config.disabled);
  if (config.visible)   field.setVisible(config.visible);
  */
  if (xl.widget.debug) { xl.log('Leaving FormField'); }
  return field;
};

xl.widget.InlineActiveField = function(config) {
  if (xl.widget.debug) { xl.log('In InlineActiveField'); }
  config.update = $H(config.update);
  config.get    = $H(config.get);
  
  // Expand form object
  if (config.form) {
    if (config.form.update) config.update.update(config.form.update);
    if (config.form.get) config.get.update(config.form.get);
    
    if (config.form.url) config.update.set('url', config.form.url);
    if (config.form.method) config.update.set('method', config.form.method || 'put');
    
    if (config.form.object) config.object = config.form.object;
  }
  
  // Check Requirements
  if (!config.object)     return null;
  if (!config.field.name) return null;
  if (!config.update.get('url')) return null;
  
  // Build the form field
  if (!config.field) return null;
  var field = xl.widget.FormField(config.field);
  if (!field) return null;
  
  field.style = 'border: solid 1px #EEE; background: none;';
  field.cls = 'xl-x-active-field';
  
  if (xl.widget.debug) { xl.log('About to set \'onshow\''); }
  
  if (config.get) {
    field.on('show', function(me) {
      xl.log('show');
      var params = $H({}), key = config.object + '[' + config.field.name + ']';
      params.set(key, newValue);
    
      Ext.Ajax.request({
        url: config.get.get('url'),
        method: config.get.get('method') || 'get',
        params: params.toObject(),
        
        failure: xl.logXHRFailure,
        success: function(xhr, options) {
          if (xl.widget.debug) {
            xl.log('Asked ' + object + ' for ' + key + ' = "' + xhr.responseText + '"');
          } // end if
        } // end success
      });
    });
  }
  
  if (xl.widget.debug) { xl.log('About to set \'onchange\''); }

  var triggerEvent;
  if (config.field.xtype == 'checkbox') 
    triggerEvent = 'check';
  else 
    triggerEvent = 'change';
  
  
  var doAjaxUpdate = function(me, newValue, oldValue){
    // Ex - config.object = 'products', config.field.name = 'name' ->
    //      key = 'products[name]'
    param_name = "";
    config.field.name.gsub('\\[', ',').gsub('\\]', ',').split(',').each(function(s){
      if (s.trim().length != 0) 
        param_name = param_name.concat("\[", s, "\]");
    })
    var params = $H({}), key = config.object + param_name;
    
    if (config.field.hiddenName) {
      key = config.field.hiddenName;
    }
    
    if (config.field.xtype == 'datefield') {
      newValue = me.value;
    }
    params.set(key, newValue.toString());
    params.update(config.params || {});
    
    if (config.field.xtype != 'htmleditor') {
      me.setDisabled(true);
      me.getEl().setStyle('background-color', '#FFFCC4');
    }
    
    Ext.Ajax.request({
      url: config.update.get('url'),
      params: params.toObject(),
      method: config.update.get('method') || 'put',
      
      failure: function(xhr, options){
        me.setRawValue(oldValue);
        me.setDisabled(false);
        me.getEl().setStyle('background-color', '#FFA091');
      },
      success: function(xhr, options){
        if (xl.widget.debug) {
          xl.log('Changed ' + key + ' from ' + oldValue + ' to ' + newValue);
          xl.log('Response was: ' + xhr.responseText);
        }
        if (config.field.xtype != 'htmleditor') {
          me.getEl().setStyle('background-color', 'white');
          me.setDisabled(false);
        }
        if (config.afteredit) 
          config.afteredit(oldValue, Ext.decode(xhr.responseText), xhr.responseText, me);
      }
    });
  }
  
  if (config.field.xtype == 'htmleditor') {
    field.on('render', function(me, html){
      me.getEl().on('change', function(meEl, newValue, oldValue){
        doAjaxUpdate(me, newValue.value, oldValue);
      });
    });
    field.on('beforesync', function(me, html){
      doAjaxUpdate(field, html, html);
    }, this, {buffer:1500});
  } else {
    field.on(triggerEvent, doAjaxUpdate);
  }
  
  if (xl.widget.debug) { xl.log('Leaving InlineActiveField'); }
  return field;
};

/*
  Usage: Only one of these is necessary per page, and can only be
         used with panels involved in a ux.rowfit layout.
  
  Configuration:
*/
xl.widget.SplitBarSystem = function(systemConfig) {  
  this.systemConfig = systemConfig;
  
  /*
    Usage: Creates an adapter for a split bar panel and panel involved in a
           ux.rowfit layout. This may only be called AFTER rendering!
    
    Configuration:
      splitBarPanelSuffix
      panelSuffix
      hv - Ext.SplitBar.VERTICAL or HORIZONTAL
      tb - Ext.SplitBar.TOP or BOTTOM
  */
  this.adapt = function(config) {
    var splitBarPanelId = systemConfig.prefix + (config.splitBarPanelSuffix || '.splitBar');
    var panelId = systemConfig.prefix + (config.panelSuffix || '.panel');
    
    var splitBar = new Ext.SplitBar(splitBarPanelId, panelId, config.hv || Ext.SplitBar.VERTICAL, config.tb || Ext.SplitBar.TOP);
    splitBar.setAdapter(new Ext.ux.layout.RowFitLayout.SplitAdapter(splitBar));
  }
  
  /*
    Generates: An Ext.Panel with html set to the html for a split bar
    
    Configuration:
      suffix
      height
      html
  */   
  this.generatePanel = function(config) {
    config.html = config.html || '<div style="height: 15px; background: url(/javascripts/extjs/resources/images/xl/horizontal-split-handle.gif); background-position: top; background-repeat: no-repeat;">&nbsp;</div>';

    return new Ext.Panel({
      id: systemConfig.prefix + (config.suffix || '.splitBar'),
      height: config.height || 15,
      border: false,
      bodyBorder: false,
      frame: false,
      cls: 'IHaveASplitBar',
      html: config.html
    });
  }
}

/*
  Usage: Adds a GridPanel for Group Authorizations to a Panel. This must only be called after
         the parent Panel has rendered, as it has to call doLayout!
  
  Configuration:
    parent - the Panel to which it attaches
    auths -
    get - 
    update - 
    object -
*/
xl.widget.AttachGroupAuthorizationsPanel = function(config) {
  
  // Need to check requirements
  
  Ext.Ajax.request({
    url: config.auths.url || config.auths,
    method: config.auths.method || 'get',
    success: function(xhr, options) { 
      var object = Ext.util.JSON.decode(xhr.responseText);
      object.reader_ids = $A(object.reader_ids);
      object.writer_ids = $A(object.writer_ids);
      
      var toggleRWAction = function(which_ids, grid, record, rowIndex, event) {
        // First set up the which_ids array to send
        var array = object[which_ids];
        if ( array.include(record.get('id')) ) {
          array = array.without(record.get('id'));
        } else {
          array.push(record.get('id'));
        }
        
        var params = {}, key = config.object + '[' + which_ids + ']';
        params[key] = ($A(array)).join(',');
        
        Ext.Ajax.request({
          url: config.update.url || config.update,
          method: config.update.method || 'put',
          params: params,
          success: function(xhr, options) {
            var data = Ext.util.JSON.decode(xhr.responseText);
            object[which_ids] = $A(data);
            console.log('Object is now: %o', object);
            groupAuthorizationsGridPanel.getStore().reload();
          }
        });
      };
      
      var rwRenderer = function(which_ids, s, value, cell, record) {
        if (object[which_ids].include(value))
          return '<div class="hasRowAction pointerOnHover ' + which_ids + '" style="font-weight: bold; color: green;">' + s + '</div>';
        else
          return '<div class="hasRowAction pointerOnHover ' + which_ids + '" style="font-weight: normal; color: gray;">' + s + '</div>';
      };
      
      var readAction = new Ext.ux.grid.RowAction({
        dataIndex: 'id', width: 32, iconCls: 'reader_ids',
        renderer: function(v, c, r) { return rwRenderer('reader_ids', 'R', v,c,r); }
      });
      var writeAction = new Ext.ux.grid.RowAction({
        dataIndex: 'id', width: 32, iconCls: 'writer_ids',
        renderer: function(v, c, r) { return rwRenderer('writer_ids', 'W', v,c,r); }
      });
      readAction.on('action', function(g, r, i, e) { toggleRWAction('reader_ids', g,r,i,e); });
      writeAction.on('action', function(g, r, i, e) { toggleRWAction('writer_ids', g,r,i,e); });
      
      var groupAuthorizationsGridPanel = new Ext.grid.GridPanel({
        store: xl.widget.SimpleJSONStore({
          url: config.get.url || config.get,
          method: config.get.method || 'get',
          doLoad: true,
          fields: [ 'id', 'name' ]
        }).store,
        cm: new Ext.grid.ColumnModel([
          readAction,
          writeAction,
          {
            id: 'name',
            header: 'Group',
            dataIndex: 'name'
          }
        ]),

        viewConfig: { forceFit: config.forceFit || true },
        autoScroll: true,
        width: config.width || 215,
        height: config.height || 500,
        autoExpandColumn: 'name',
        plugins: [readAction, writeAction]
      });
      
      config.parent.add(groupAuthorizationsGridPanel);
      config.parent.doLayout();
    } // end success
  });
}

/*
  Usage: Calls async_create for an object, and if successful --
         the integer id of the new object is returned -- the edit
         page is opened in a new window
  
  Configuration:
    object -
    async_create -
      params - {param: value} which will go into request:params['object[param]'] = value
      url
      method - (defaults to 'post')
    edit - url like: http://whatever.com/<SUBSTRING>/edit
      urlSub - (defaults to '__ID__')
    success - function executed on success before edit page is opened.
      Arguments: id - the Number id of the new record
*/
xl.widget.DoAsyncCreateAndOpenEdit = function(config) {
  if (xl.widget.debug) xl.log('In DoAsyncCreateAndOpenEdit');
  
  if (!config.object) throw new Error(xl.widget.badConfigTpl.interpolate({widget: 'DoAsyncCreateAndOpenEdit', problem: 'object is required'}));
  if (!config.async_create) throw new Error(xl.widget.badConfigTpl.interpolate({widget: 'DoAsyncCreateAndOpenEdit', problem: 'async_create is required'}));
  //if (!config.edit) throw new Error(xl.widget.badConfigTpl.interpolate({widget: 'DoAsyncCreateAndOpenEdit', problem: 'edit is required'}));
  var params = $H({});
  
  // Look at each passed param and create a param Rails can understand
  $H(config.async_create.params || {}).each(function(kvp) {
    var key = config.object + '[' + kvp.key + ']';
    params.set(key, kvp.value);
  });
  
  if (xl.widget.debug) xl.log('Params (as JSON): ' + params.toJSON());
  if (xl.widget.debug) xl.log('Checked requirements; Requesting...');
  
  // First make the create request
  Ext.Ajax.request({
    url: config.async_create.url || config.async_create,
    method: config.async_create.method || 'post',
    params: params.toObject(),
    success: function(xhr, options) {
      var data = Ext.util.JSON.decode(xhr.responseText);
      if (typeof data == 'number') {
        if (xl.widget.debug) xl.log('Request successful, got id; Opening edit tab...');
        if (config.success) config.success(data);
        if (config.edit.url || config.edit) {
          var editUrl = config.edit.url || config.edit;
          xl.openNewTabPanel('edit_' + config.object + '_' + data, editUrl.sub(config.edit.urlSub || '__ID__', data));
        }
      }
      else if ((typeof(data) == "object") && (typeof(data.id) == "number")){
        if (config.success) config.success(data);
        if (config.edit.url || config.edit) {
          var editUrl = config.edit.url || config.edit;
          xl.openNewTabPanel('edit_' + config.object + '_' + data.id, editUrl.sub(config.edit.urlSub || '__ID__', data.id));
        }
      } 
      else {
        Ext.Msg.alert('Response', data);
        if (xl.widget.debug) xl.log('Request successful, but did not get id; Returning null');
        return null;
      }
    }, // success
    failure: function(xhr, options){
      var data = Ext.util.JSON.decode(xhr.responseText);
      alert('failed');
    }
  });
  
  if (xl.widget.debug) xl.log('Leaving DoAsyncCreateAndOpenEdit');
}

/*
  Generates: An Ext.Action with an action for calling
             a delete_collection action
             
  Configuration:
    gridPanel -
    text - (defaults to 'Delete...')
    iconCls - (defaults to 'display_none')
    disabled - (defaults to false)
    visible - (defaults to true)
    object -
    url -
    method - (defaults to 'post')
    params - (defaults to {})
    success - function({request, options, json})
    title - (defaults to 'Confirm Delete')
    message - If not specified, object is required
*/
xl.widget.DeleteSelectedAction = function(config) {
  // Check Requirements
  config.title = config.title ||  'Confirm Delete';
  if (!config.message && config.object) {
    config.message = "Are you sure you want to delete the selected " + config.object + "(s)?";
  } else {
    config.message = "Are you sure you want to delete the selected records?";
  }
  
  //config.url = xl.widget._ParseURL(config.url);
  if (!config.url) return null;
  
  var action = new Ext.Action({
    text: config.text || 'Delete...',
    iconCls: config.iconCls || 'display_none',
    disabled: config.disabled || false,
    visible: config.visible || true,
    
    handler: function() {
      var records = [];
      var sm = config.gridPanel.getSelectionModel();
      
      if (!sm.hasSelection()) { /*xl.widget.AlertNoSelection();*/ return false; }
      
      if (config.gridPanel.startEditing) { // startEditing is unique to EditorGridPanel
        row = config.gridPanel.getSelectionModel().getSelectedCell()[0];
        records = [config.gridPanel.getStore().getAt(row)];
      } else {
        records = config.gridPanel.getSelectionModel().getSelections();
      }
      
      var ids = records.invoke('get', 'id');  // Returns an Array of the ids retrieved by calling .get('id') on each record in records
      var params = $H({});
      params.update(config.params || {});
      params.update({ids: ids.join(', ')});
      
      Ext.Msg.confirm(config.title, config.message, function(buttonText) {
        if (buttonText === 'yes') {
          Ext.Ajax.request({
            url: config.url,
            method: config.method || 'post',
            params: params.toObject(),
            failure: xl.logXHRFailure,
            success: function(request, options) {
              if (config.success) {
                config.success({
                  request: request,
                  options: options,
                  json: Ext.util.JSON.decode(request)
                });
              }
              config.gridPanel.getStore().reload();
            } // end success(r,o)
          }); // end Ext.Ajax.request
        } // end ifbuttonText.match...
      }); // end Ext.Msg.confirm
    } // end handler
  }); // end new Ext.Action
  
  return action;
}

/*
  Generates a single selection image picker
  Configuration:
    REQUIRED
      elId: dom Id of <img> tag which source attribute is to be replaced
      url: url to be used for the Ext.data.Store of the image selector grid
      objectType: the class name of object to which the file will be attached to
      objectId: the id of object to which the file will be attached to
    OPTIONAL
      setAVatar: send along set_avatar parameter with upload request
      setRelation: send along set_relation parameter with upload request
      windowTitle: String to be used for title of the image selector window
      afterSelect: function to be executed after a picture has been selected
        Listener will be called with the following arguments:
          - record: Ext.data.Record of the selected picture
*/

xl.widget.OpenSingleImagePicker = function(elId, url, objectType, objectId, config, options){
  if(options==null)options=new Hash();
  var mode = "single";
  var classification = "Image";
  
  if(options.content_type)
    baseParams = { q: '', sort: 'created_at', dir: 'DESC', content_type: options.content_type};
  else
    baseParams = { q: '', sort: 'created_at', dir: 'DESC' };
  
  var allImagesStore = xl.widget.SimpleJSONStore({
    url: url,
    method: "GET",
    fields: ['id', 'url', 'filename'],
    doSmartMappings: true,
    baseParams: baseParams
  }).store;

  xl.widget.imagePickerDataStores.set(objectType + "_" + objectId + "_" + mode + "_" + classification, allImagesStore); 

  var filterField = new Ext.form.TextField({selectOnFocus: true, grow: false, emptyText: "Search"});
  filterField.on("specialkey",
    function(field, e) {
      if (e.getKey() == Ext.EventObject.RETURN || e.getKey() == Ext.EventObject.ENTER) {
        e.preventDefault();
        allImagesStore.baseParams['q'] = this.getValue();
        allImagesStore.reload({params: {start: 0, limit: 10}});
      }
    }
  );
  
  var allImagesPanel = new Ext.grid.GridPanel({
    store: allImagesStore,
    layout: "fit",
    columns: [
      {
        dataIndex: 'url',
        header: 'Image',
        renderer: function(value, cell, record) {
          return ('<img src="' + value + '?size=mini" />');
        }
      },
      {
        id: 'filename',
        dataIndex: 'filename',
        header: 'Filename'
      }
    ],
    
    tbar: ["Filter: ", filterField],
    
    bbar: [new Ext.PagingToolbar({
      store: allImagesStore,
      pageSize: 10,
      displayInfo: true,
      displayMsg: "{0}-{1} of {2}",
      emptyMsg: "No images",
      cls: "paging-toolbar-bottom",
      plugins: [new Ext.ux.PageSizePlugin]
    })],
    
    sm: new Ext.grid.RowSelectionModel({singleSelect: true}),
    loadMask: true,
    autoWidth: true,
    height: 490,
    viewConfig: { forceFit: true },
    autoExpandColumn: 'filename'
  });
  
  allImagesPanel.on("rowdblclick", function(grid, rowIndex, event){
    var selectedRecord = grid.getStore().getAt(rowIndex);
    if (config.beforeSelect) {
      config.beforeSelect(window);
    }
    if(!options.doNotUpdateEl)
      Ext.get(elId).dom.src = selectedRecord.get("url") + "?size=mini";       
    

    if (config.afterSelect){
      config.afterSelect(selectedRecord, window);
    }
  });

  /************
   ** LAYOUT **
   ************/
  
  var uploadFormPanel = new Ext.form.FormPanel({
    autoScroll: true,
    fileUpload: true,
    labelAlign: 'left',
    items: [
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Upload',
        name: 'asset[uploaded_data]',
        inputType: 'file'
      }),
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Title',
        name: 'asset[title]'
      }),
      new Ext.form.TextArea({
        fieldLabel: "Description",
        width: 350,
        name: "asset[description]"
      }),
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Tags',
        name: 'asset[tag_list]'
      })
    ],
    bbar: [{
        text: "Upload",
        handler: function(button, event){
            var params = {};
            if (config.setAvatar){
              params["set_avatar"] = true;
            }
            if (config.setRelation){
              params["set_relation"] = true
            }
            params["object_type"] = objectType;
            params["object_id"] = objectId;      
            if(!options.doNotUpdateEl)
              params["dom_id"] = elId;
            params["mode"] = "single";            
            params["classification"] = classification;     
            if(config.uploadCallback){
              params["callback"] = config.uploadCallback;
            }    

            uploadPanel.el.mask("Uploading from file...");

            uploadFormPanel.getForm().doAction('submit',
              {
                url: "/admin/assets/image_picker_upload", 
                method: "POST",
                params: params,
                success: function(form, action){
                  response = action.result;
                  if(config.afterUpload){
                    config.afterUpload(window);
                  }  
                  xl.updateStatusBar(response.flash);
                  if(response.success){
                    xl.widget.imagePickerDataStores.get(response.reload_store).reload();
                    if(!options.doNotUpdateEl)
                      Ext.get("elId").dom.src = response.asset_download_path+"?size=mini";
                    Ext.Msg.alert("Status:", "Upload Complete");
                    if (config.uploadCallback) {
                      config.uploadCallback(response);
                    }
                  }
                  else{
                    xl.updateStatusBar(response.flash);                 
                    uploadPanel.el.unmask;
                    Ext.Msg.alert("Status:", "Upload Failed: "+response.flash);
                  }
                },
                failure: function(form, action){
                  response = action.result;
                  xl.updateStatusBar(response.flash);              
                  uploadPanel.el.unmask();              
                  Ext.Msg.alert("Upload Failed: ", response.flash);
                }
              }
            );
          }
      }]
  });
  
  var externalUploadFormPanel = new Ext.form.FormPanel({
    hidden: true,
    autoScroll: true,
    labelAlign: 'left',
    items: [
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'URL',
        name: 'asset[external_url]'
      }),
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Title',
        name: 'asset[title]'
      }),
      new Ext.form.TextArea({
        fieldLabel: "Description",
        width: 350,
        name: "asset[description]"
      }),
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Tags',
        name: 'asset[tag_list]'
      })
    ],
    bbar: [{
        text: "Upload",
        handler: function(button, event){
            var params = {};
            if (config.setAvatar){
              params["set_avatar"] = true;
            }
            if (config.setRelation){
              params["set_relation"] = true
            }
            params["object_type"] = objectType;
            params["object_id"] = objectId;       
            if(!options.doNotUpdateEl)
              params["dom_id"] = elId;
            params["mode"] = "single";
            params["classification"] = classification;            
            
            uploadPanel.el.mask("Uploading from an external source...");
            
            externalUploadFormPanel.getForm().doAction('submit',
              {
                url: "/admin/assets/image_picker_upload", 
                method: "POST",
                params: params,
                success: function(form, action) {
                    response = action.result;
                    if(typeof(response)=="undefined")
                    {
                      Ext.Msg.alert("Upload failed", "Proper connection with the external url cannot be established");
                    }
                    if(!options.doNotUpdateEl)
                      Ext.get(elId).dom.src = response.asset_url + "?size=mini";
                    uploadPanel.el.unmask();
                    allImagesStore.reload();
                    Ext.Msg.alert("Status:", "Upload Complete");
                  },
                failure: function(form, action) {
                    Ext.Msg.alert("Upload failed", "Proper connection with the external url cannot be established");
                    uploadPanel.el.unmask();
                  }
              }
            );
            
            if (!externalUploadFormPanel.getForm().isValid()){
              uploadPanel.el.unmask();
            }
          }
      }]
  });
  
  var uploadSelectionStore = new Ext.data.SimpleStore({
    fields: ['display'],
    data: [["File"], ["External source"]]
  });
  var uploadSelectionPanel = new Ext.form.ComboBox({
    value: "File",
    displayField: "display",
    fieldLabel: 'Upload from',
    store: uploadSelectionStore,
    triggerAction: 'all',
    mode: 'local',
    editable: false,
    forceSelection: true,
    listWidth: 150,
    listeners: {
      select: function(comboBox, record, index){
        if (record.get("display") == "File"){
          uploadFormPanel.show();
          externalUploadFormPanel.hide();
        }
        else if (record.get("display") == "External source"){
          uploadFormPanel.hide();
          externalUploadFormPanel.show();
        }
      }
    }
  });
  
  var uploadPanel = new Ext.Panel({
    items: [{layout:"form", items: uploadSelectionPanel}, uploadFormPanel, externalUploadFormPanel]
  });

  var tabPanel = new Ext.TabPanel({
    activeTab: 0,
    deferredRender: false,
    items:[
      {title: "All files", items: [allImagesPanel], height: '100%', autoScroll: true, listeners: {show: 
        function(panel){
          allImagesPanel.setHeight(440);
          allImagesPanel.setWidth(590);
          allImagesPanel.ownerCt.setHeight(410);
        }
      }},
      {title: "Upload", items: [uploadPanel]}
    ]
  });      
  
  // Window
  var window = new Ext.Window({
    title: config.windowTitle || "Choose an image...",
    resizable: true,
    width:600,
    height:500,
    items: tabPanel,
    
    buttons: [{
      text: 'Close',
      handler: function() { window.close(); }
    }],
    
    listeners: {
      "resize": function(window, width, height){ 
        allImagesPanel.setHeight(window.getInnerHeight()-25);
        uploadPanel.setHeight(window.getInnerHeight()-25);
      },
      "render": function(component){
        allImagesPanel.setHeight(component.getInnerHeight()-25);
        uploadPanel.setHeight(window.getInnerHeight()-25);
      },
      "beforedestroy": function(component){
        xl.widget.imagePickerDataStores.unset(objectType + "_" + objectId + "_" + mode + "_" + classification);
      }
    }
  });
  
  window.show(config.showFrom, function(){window.setWidth(600); window.setHeight(500);});
  
  allImagesStore.load({params:{start: 0, limit: 10, sort: 'created_at', dir: 'DESC'}});
  allImagesStore.addListener("load", function(store, records, options){
    uploadPanel.el.unmask();
  });
  
  return allImagesStore;
} 

/*
  Generates - An ImagePicker window based on the provided configuration
  Configuration:
    REQUIRED
      objectType - the type of the current object
      objectId - the id of the current object (not used)
      
      thisObjectImagesUrl - String or:
        url -
        method - (defaults to 'get')
        fields - (defaults to ['id', 'url', 'filename'])
      allImagesUrl - String or: (see thisObjectImagesUrl)
    
    OPTIONAL
      showFrom (String) - the id of the HTML object from which to show this window. Null to just appear.
      afterUpdate (function) - Signature: afterUpdate(xhr, options, record, allImagesStore, thisObjectImagesStore)
      
    NOT IMPLEMENTED
      uploadUrl - String or: (see updateUrl)
      afterUpload (function) - Signature: afterUpload(xhr, options, record, allImagesStore, thisObjectImagesStore)    
*/
xl.widget.OpenImagePicker = function(config) {
  var mode = "multiple";
  var classification = "Image";
  if(config.imageClassification){
    classification = config.imageClassification;    
  }
  
  /**************
     FUNCTIONS 
   *************/
  var objectHasImage = function(id) {
    return thisObjectImagesStore.find('id', id) != -1;
  };
  
  var allImagesActionRenderer = function(value, cell, record) {
    var iconCls = 'icon_add_32x32';
    if (objectHasImage(value)) iconCls = 'icon_remove_32x32';
      
    return '<div class="hasRowAction pointerOnHover ' + iconCls + '">&nbsp;</div>';
  };
  
  var thisObjectImagesStore = xl.widget.SimpleJSONStore({
    url: config.thisObjectImagesUrl.url || config.thisObjectImagesUrl,
    method: config.thisObjectImagesUrl.method || 'get',
    fields: config.thisObjectImagesUrl.fields || ['id', 'url', 'filename'],
    doSmartMappings: true
  }).store;
  xl.widget.imagePickerDataStores.set(config.objectType + "_" + config.objectId + "_" + mode + "_" + classification, thisObjectImagesStore);
  
  /**************
     ALL IMAGES
   **************/
  var allImagesStore = xl.widget.SimpleJSONStore({
    url: config.allImagesUrl.url || config.allImagesUrl,
    method: config.allImagesUrl.method || 'get',
    fields: config.allImagesUrl.fields || ['id', 'url', 'filename'],
    doSmartMappings: true,
    baseParams: { q: '', sort: 'created_at', dir: 'DESC' }
  }).store;
  
  var allImagesAction = new Ext.ux.grid.RowAction({
    dataIndex: 'id', width: 40, iconCls: 'hasRowAction',
    renderer: allImagesActionRenderer
  });
  
  // create filter field to be appended as the top window toolbar
  var filterField = new Ext.form.TextField({selectOnFocus: true, grow: false, emptyText: "Search"});
  filterField.on("specialkey",
    function(field, e) {
      if (e.getKey() == Ext.EventObject.RETURN || e.getKey() == Ext.EventObject.ENTER) {
        e.preventDefault();
        allImagesStore.baseParams['q'] = this.getValue();
        allImagesStore.reload({params: {start: 0, limit: 10}});
      }
    }
  );      
  
  var allImagesPanel = new Ext.grid.GridPanel({
    store: allImagesStore,
    loadMask: true,
    layout: "fit",
    columns: [
      allImagesAction,
      {
        dataIndex: 'url',
        header: 'Image',
        renderer: function(value, cell, record) {
          return ('<img src="' + value + '?size=mini" />');
        }
      },
      {
        id: 'filename',
        dataIndex: 'filename',
        header: 'Filename'
      }
    ],
    
    tbar: ["Filter: ", filterField],
    
    bbar: [new Ext.PagingToolbar({
      store: allImagesStore,
      pageSize: 10,
      displayInfo: true,
      displayMsg: "{0}-{1} of {2}",
      emptyMsg: "No images",
      cls: "paging-toolbar-bottom",
      plugins: [new Ext.ux.PageSizePlugin]
    })],
    
    plugins: allImagesAction,
    
    autoWidth: true,
    viewConfig: { forceFit: true },
    autoExpandColumn: 'filename'
  });
  
  allImagesAction.on('action', function(gridPanel, record, rowIndex, event) {
    var id = record.get('id');
    var imageIds = thisObjectImagesStore.collect('id');

    var params = {id: id, object_type: config.objectType, object_id: config.objectId, classification: classification };
    var allImagesActionPath = "/admin/views/add";
    if (imageIds.include(id)) {
      imageIds = imageIds.without(id);
      allImagesActionPath = "/admin/views/remove"
    } else {
      imageIds.push(id);
    }
    
    Ext.Ajax.request({
      url: allImagesActionPath,
      method: 'post',
      params: params,
      success: function(xhr, options) {
        thisObjectImagesStore.reload();
        if (config.afterUpdate) config.afterUpdate(xhr, options, record, allImagesStore, thisObjectImagesStore);
      }
    }); // end Ext.Ajax.request
  }); // end allImagesAction.on('action'...)

  /*************************
       UPLOAD FORM PANEL 
   *************************/  
  
  var uploadFormPanel = new Ext.form.FormPanel({
    autoScroll: true,
    fileUpload: true,
    labelAlign: 'left',
    items: [
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Upload',
        name: 'asset[uploaded_data]',
        inputType: 'file'
      }),
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Title',
        name: 'asset[title]'
      }),
      new Ext.form.TextArea({
        fieldLabel: "Description",
        width: 350,
        name: "asset[description]"
      }),
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Tags',
        name: 'asset[tag_list]'
      })
    ],
    bbar: [{
        text: "Upload",
        handler: function(button, event){
            var params = {};
            params["set_relation"] = true
            params["object_type"] = config.objectType;
            params["object_id"] = config.objectId;
            params["mode"] = mode;            
            params["classification"] = classification;

            uploadPanel.el.mask("Uploading from file...");

            uploadFormPanel.getForm().doAction('submit',
              {
                url: "/admin/assets/image_picker_upload", 
                method: "POST",
                params: params
              }
            );
          }
      }]
  });

  var externalUploadFormPanel = new Ext.form.FormPanel({
    hidden: true,
    autoScroll: true,
    labelAlign: 'left',
    items: [
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'URL',
        name: 'asset[external_url]'
      }),
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Title',
        name: 'asset[title]'
      }),
      new Ext.form.TextArea({
        fieldLabel: "Description",
        width: 350,
        name: "asset[description]"
      }),
      new Ext.form.TextField({
        width: 350,
        fieldLabel: 'Tags',
        name: 'asset[tag_list]'
      })
    ],
    bbar: [{
        text: "Upload",
        handler: function(button, event){
            var params = {};
            params["set_relation"] = true
            params["object_type"] = config.objectType;
            params["object_id"] = config.objectId;            
            params["mode"] = mode;            
            params["classification"] = classification;
            
            uploadPanel.el.mask("Uploading from an external source...");
            
            externalUploadFormPanel.getForm().doAction('submit',
              {
                url: "/admin/assets/image_picker_upload", 
                method: "POST",
                params: params,
                success: function(form, action) {
                    response = action.result;
                    if(typeof(response)=="undefined")
                    {
                      Ext.Msg.alert("Upload failed", "Proper connection with the external url cannot be established");
                    }
                    uploadPanel.el.unmask();
                    allImagesStore.reload();
                    thisObjectImagesStore.reload();
                    Ext.Msg.alert("Status:", "Upload Complete");
                  },
                failure: function(form, action) {
                    Ext.Msg.alert("Upload failed", "Proper connection with the external url cannot be established");
                    uploadPanel.el.unmask();
                  }
              }
            );
            
            if (!externalUploadFormPanel.getForm().isValid()){
              uploadPanel.el.unmask();
            }
          }
      }]
  });

  var uploadSelectionStore = new Ext.data.SimpleStore({
    fields: ['display'],
    data: [["File"], ["External source"]]
  });
  var uploadSelectionPanel = new Ext.form.ComboBox({
    value: "File",
    displayField: "display",
    fieldLabel: 'Upload from',
    store: uploadSelectionStore,
    triggerAction: 'all',
    mode: 'local',
    editable: false,
    forceSelection: true,
    listWidth: 150,
    listeners: {
      select: function(comboBox, record, index){
        if (record.get("display") == "File"){
          uploadFormPanel.show();
          externalUploadFormPanel.hide();
        }
        else if (record.get("display") == "External source"){
          uploadFormPanel.hide();
          externalUploadFormPanel.show();
        }
      }
    }
  });
  
  var uploadPanel = new Ext.Panel({
    items: [{layout:"form", items: uploadSelectionPanel}, uploadFormPanel, externalUploadFormPanel]
  });
  /*************************
     END UPLOAD FORM PANEL 
   *************************/  
  
  /************
   ** LAYOUT **
   ************/

  var tabPanel = new Ext.TabPanel({
    activeTab: 0,
    deferredRender: false,
    items:[
      {title: "All files", items: [allImagesPanel]},
      {title: "Upload", items: [uploadPanel]}
    ]
  });      

  // Window
  var window = new Ext.Window({
    title: config.windowTitle || "Image Picker",
    resizable: true,
    width: 500,
    height: 500,
    
    items: tabPanel,
    
    buttons: [{
      text: 'Close',
      handler: function() { window.close(); }
    }],
    
    listeners: {
      "resize": function(window, width, height){ 
        allImagesPanel.setHeight(window.getInnerHeight()-25); 
        uploadPanel.setHeight(window.getInnerHeight()-25);
      },
      "render": function(component){
        allImagesPanel.setHeight(component.getInnerHeight()-25);
        uploadPanel.setHeight(window.getInnerHeight()-25);
      },
      "beforedestroy": function(component){
        xl.widget.imagePickerDataStores.unset(config.objectType + "_" + config.objectId + "_" + mode + "_" + classification);
      }
    }
  });
  
  window.show(config.showFrom);
  
  thisObjectImagesStore.load();
  allImagesStore.load({params:{start: 0, limit: 10, sort: 'created_at', dir: 'DESC'}});
  thisObjectImagesStore.addListener("load", function(store, records, options){
    allImagesStore.reload({
      callback: function(r, options, success){
        allImagesPanel.getView().refresh();
        uploadPanel.el.unmask();
      }
    });
  });

  return allImagesStore;
}

/*
  USAGE: Call the function passing in the required configurations. It will return an image
         viewer panel followed by its store.

  CONFIGURATION:
    REQUIRED
      object: the type of the object that the images belongs to
      objectId: the ID of the object that the images belongs to
      imagesUrl: url that returns a json collection of images of this object
  
    OPTIONAL:
      height: will overwrite the default height of the grid panel
    
  RETURNS: an array containing the Ext.Panel for the image viewer and its Ext.data.Store
*/

xl.widget.ImageViewer = function(config){
  // Check Requirements
  if (!(config.objectType)){
    alert("Please specify the 'objectType' configuration")
    return false;
  };
  if (!(config.objectId)){
    alert("Please specify the 'objectId'")
    return false;
  };
  if (!(config.imagesUrl)){
    alert("Please specify the 'imagesUrl'")
    return false;
  };
  
  var imageViewerStore = xl.widget.SimpleJSONStore({
    url: config.imagesUrl.url || config.imagesUrl,
    method: config.imagesUrl.method || 'get',
    fields: config.imagesUrl.fields || ['id', 'url', 'filename'],
    doSmartMappings: true,
    doLoad: true
  }).store;
  
  var deleteImageAction = new Ext.ux.grid.RowAction({
    dataIndex: 'id', width: 40, iconCls: 'image_viewer_delete',
    renderer: function(value, cell, record) {
      return '<div class="pointerOnHover image_viewer_delete">&nbsp;</div>';
    }
  });
  
  var imageViewerPanelConfig = {
    store: imageViewerStore,
    columns: [
    deleteImageAction,
    {
      dataIndex: 'url',
      header: 'Image',
      renderer: function(value, cell, record) { return '<img src="' + value + '?size=mini" />'; }
    },{
      id: 'filename',
      dataIndex: 'filename',
      header: 'Filename'
    }],
    
    plugins: deleteImageAction,
    
    enableDragDrop: true,
    ddGroup: "imagePickerDDGroup",
    autoScroll: true,
    viewConfig: { forceFit: true },
    autoExpandColumn: 'filename'  
  };
  
  if(config.height){
    imageViewerPanelConfig.height = config.height;
  }
  else{
    imageViewerPanelConfig.autoHeight = true;  
  } 
  
  var imageViewerPanel = new Ext.grid.GridPanel(imageViewerPanelConfig);
  
  deleteImageAction.on('action', function(gridPanel, record, rowIndex, event) {
    
    Ext.Msg.confirm("", "Remove file from " + config.objectType.toLowerCase() + " ?", function(btn){
      if ( btn.match(new RegExp("yes","i")) ) { 
        var id = record.get('id');
        var params = {};
        params["id"] = id;
        params["object_id"] = config.objectId;
        params["object_type"] = config.objectType;  
        
        Ext.Ajax.request({
          url: "/admin/views/remove",
          method: 'POST',
          params: params,
          success: function(xhr, options) {
            imageViewerStore.reload();
            if (config.afterUpdate) config.afterUpdate(xhr, options, record, imageViewerStore);
          }
        }); // end Ext.Ajax.request
      }
    });
    
  });

  imageViewerPanel.on("render", function(g) {
    var ddrow = new Ext.ux.dd.GridReorderDropTarget(g, {
       copy: false
       ,listeners: {
         afterrowmove: function(objThis, oldIndex, newIndex, records) {
           var ds = imageViewerPanel.getStore();
           var positions = [];
           all_records = ds.getRange(0, ds.getCount()-1);
           all_records.each(function(record){
             positions.push(ds.indexOfId(record.id));
           });
           new Ajax.Request("/admin/views/reposition",{
             method: "POST",
             parameters: { ids: all_records.invoke("get", "id").join(","), positions: positions.join(","), object_type: config.objectType, object_id: config.objectId },
             onSuccess: function(transport) {ds.reload(); if (config.onOrderingSuccess) config.onOrderingSuccess(transport)}, 
             onFailure: function(transport) {if (config.onOrderingFailure) config.onOrderingFailure(transport)}
           });
         }
       }
    });
  });
  
  return [imageViewerPanel, imageViewerStore];
}
