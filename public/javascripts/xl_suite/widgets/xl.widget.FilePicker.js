xl.widget.FilePicker = Ext.extend(Ext.Window,{
  title:"File Picker"
  ,modal:false
  ,height:350
  ,width:680
  ,resizable:false
  ,closeAction:"hide"
  ,layout:"column"
  ,initComponent:function(){
    var oThis = this;
    this.selectedRecords = new Array();
    
    //create folder panel
    if(!this.folderPanel){
      this.folderPanel = new Ext.ux.FileTreePanel({
        title:"Folders"
        ,url:"/admin/folders/filetree"
        ,rootPath:'root'
        ,rootId:"folder_0"
        ,rootText:"Root"
        ,topMenu:true
        ,selectOnEdit:false
        ,autoScroll:true
        ,enableRename:false
        ,enableDelete:false
        ,enableNewDir:false
        ,enableProgress:false
        ,enableOverwrite:false
        ,enableOpen:false
        ,enableUpload:false
        ,height:292
        ,width:200
        ,listeners:{
          "click":function(node,event){
            oThis.filesGrid.getStore().baseParams["ids"] = node.id.split("_")[1];
            oThis.setFilesGridTitle(node);
            oThis.filesGrid.getStore().reload();
          }
        }
      });      
    }
        
    if(!this.closeButton){
      this.closeButton = new Ext.Toolbar.Button({
        text:"Close"
        ,handler:function(btn){
          oThis.hide();
        }
      });
    }
    
    this.initFilesGrid();
    
    this.items = [this.folderPanel, this.filesGrid];
    this.bbar = new Ext.Toolbar({items:[this.closeButton]});
    
    this.addEvents('filechecked','upload');
    
		// call parent
		xl.widget.FilePicker.superclass.initComponent.apply(this, arguments);
  }
  ,initFilesGrid:function(){
    if(this.filesGrid){return false;}
    
    var oThis = this;
    
    var FileRecord = new Ext.data.Record.create([
      {id:'id', name:'id', mapping:'id'}
      ,{id:'real_id', name:'real_id', mapping:'real_id'}
      ,{id:'label', name:'label', mapping:'label'}
      ,{id:'type', name:'type', mapping:'type'}
      ,{id:'folder', name:'folder', mapping:'folder'}
      ,{name:'size', mapping:'size'}
      ,{id:'path', name:'path', mapping:'path'}
      ,{id:'z_path', name:'z_path', mapping:'z_path'}
      ,{id:'absolute_path', name:'absolute_path', mapping:'absolute_path'}
      ,{name:'notes', mapping:'notes'}
      ,{name:'tags', mapping:'tags'}
      ,{name:'created_at', mapping:'created_at'}
      ,{name:'updated_at', mapping:'updated_at'}
      ,{name:'url', mapping:'url'}      
    ]);

    var filesGridStoreReader = new Ext.data.JsonReader({totalProperty:"total", root:"collection", id:"id"}, FileRecord);
    var filesGridStoreConnection = new Ext.data.Connection({url:"/admin/folders.json", method:'get'});
    var filesGridStoreProxy = new Ext.data.HttpProxy(filesGridStoreConnection);
    var filesGridStore = new Ext.data.Store({proxy:filesGridStoreProxy, reader:filesGridStoreReader, remoteSort: true, baseParams: {q:''}});
    
    // create row expander of the grid object
    var filesGridExpander = new Ext.grid.RowExpander({ contains: ["notes", "tags", "updated_at", "created_at", "real_id", "absolute_path", "z_path"],
      tpl:new Ext.Template(
        '<table><tr><td>',
        '<img src="{absolute_path}"/></td><td>',
        '<div>{notes}</div>',
        '<div>Tags: {tags}</div>',
        '<div>Updated at: {updated_at}</div>',
        '<div>Created at: {created_at}</div>',
        '<div>Absolute download path: {absolute_path}</div>',
        '<div>Asset URL liquid tag: {% asset_url file_path:"{z_path}" size:"full" %}</div></td></tr></table>'
      )
    });
    
    var expandAllButton = new Ext.Toolbar.Button({
      text:"Expand all"
      ,handler:function(btn){
        Ext.DomQuery.select("#" + oThis.filesGrid.id + ' .x-grid3-row-collapsed').each (function(e)
          { filesGridExpander.expandRow(e); }
        );
      }
    });

    var collapseAllButton =  new Ext.Toolbar.Button({
      text: "Collapse all"
      ,handler: function(btn){
        Ext.DomQuery.select("#" + oThis.filesGrid.id + ' .x-grid3-row-expanded').each (function(e)
          { filesGridExpander.collapseRow(e); }
        );
      }
    });
    
    // define paging toolbar that is going to be appended to the footer of the grid panel
    var filesGridPaging = new Ext.PagingToolbar({
      store:filesGridStore
      ,pageSize:50
      ,displayInfo:true
      ,displayMsg:''
      ,emptyMsg:"No record to display"
      ,cls:"paging-toolbar-bottom"
      ,plugins:[new Ext.ux.PageSizePlugin]
    });

    var filterField = new Ext.form.TextField({selectOnFocus: true, grow: false, emptyText: "Search"});
    filterField.on("specialkey",
      function(field, e){
        var gridStore = oThis.filesGrid.getStore();
        if (e.getKey() == Ext.EventObject.RETURN || e.getKey() == Ext.EventObject.ENTER) {
          if (this.getValue().length < 4){
            Ext.Msg.show({
              title:"Warning"
              ,msg:"Filter term cannot be shorter than 4 characters"
              ,buttons:Ext.Msg.OK
              ,fn:function(btn, text){
                if (btn =="ok"){ field.focus();}
              }
            });
          }
          else{
            e.preventDefault();
            gridStore.baseParams['q'] = this.getValue();
            var previousLimit = 50;
            if(gridStore.lastOptions.params && gridStore.lastOptions.params.limit){
              previousLimit = gridStore.lastOptions.params.limit;
            }
            gridStore.reload({params:{start:0, limit:previousLimit}});
          }
        }
      }
    );

    var clearButton = new Ext.Toolbar.Button({
      text: 'Clear',
      handler: function() {
        filterField.setValue("");
        filesGridStore.baseParams['q'] = "";
        filesGridStore.reload();
      }
    });
    
    var fileCheckColumn = new Ext.grid.CheckColumn({
      id:'included' 
      ,header:""
      ,dataIndex:'included'
      ,width:30
    });

    fileCheckColumn.addListener("click", function(cpt, event, record){
      if(record.get("included")){
        oThis.selectedRecords.push(record);
      }else{
        oThis.selectedRecords.remove(record);
      }
      oThis.fireEvent("filechecked", record, oThis, cpt, event);
    });
    
    this.filesGrid = new Ext.grid.EditorGridPanel({
      title:" "
      ,store:filesGridStore
      ,cm:new Ext.grid.ColumnModel([filesGridExpander
          ,{id:"file-label", header:"Label", sortable:true, dataIndex:'label'}
          ,{header:"Type", width:125, sortable:true, dataIndex:'type'}
          ,{header:"Size", width:75, sortable:true, dataIndex:'size'}
          ,fileCheckColumn
        ])
      ,plugins:[filesGridExpander, fileCheckColumn]
      ,autoScroll:true
      ,autoExpandColumn:'file-label'
      ,tbar:[new Ext.Toolbar({items:[{xtype:"tbtext", text:"Filter"}, filterField, clearButton, expandAllButton, collapseAllButton]})]
      ,bbar:[filesGridPaging]
      ,footer:true
      ,enableDragDrop:false
      ,loadMask:true
      ,columnWidth:1
      ,height:294
      ,listeners:{
        render:function(grid){
          oThis.setFilesGridTitle(null);
          grid.getStore().load();
        }
      }
    });
  },
  setFilesGridTitle:function(node){
    var title = "Browsing files in /";
    var temp = null;
    if(node){
      temp = this.folderPanel.getPath(node).split("/");
      temp.shift();
      title += temp.join("/");
    }
    this.filesGrid.setTitle(title);
  },
  getSelections:function(){
    return(this.selectedRecords);
  }
});
// register xtype
Ext.reg('filepickerwindow', xl.widget.FilePicker);
