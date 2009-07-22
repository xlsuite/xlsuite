/**
 * @author chander
 */
Ext.ux.MultiGroupingStore = Ext.extend(Ext.data.GroupingStore, {
    constructor: function(config){
        Ext.ux.MultiGroupingStore.superclass.constructor.apply(this, arguments);
    },

    sortInfo: [],
    
    sort: function(field, dir){
        //  alert('sort '+ field);
        var f = [];
        if (Ext.isArray(field)) {
            for (var i = 0, len = field.length; i < len; ++i) {
                f.push(this.fields.get(field[i]));
            }
        } else {
            f.push(this.fields.get(field));
        }
        
        if (f.length < 1) {
            return false;
        }
        
        if (!dir) {
            if (this.sortInfo && this.sortInfo.length > 0 && this.sortInfo[0].field == f[0].name) { // toggle sort dir
                dir = (this.sortToggle[f[0].name] || "ASC").toggle("ASC", "DESC");
            } else {
                dir = f[0].sortDir;
            }
        }
        
        var st = (this.sortToggle) ? this.sortToggle[f[0].name] : null;
        var si = (this.sortInfo) ? this.sortInfo : null;
        
        this.sortToggle[f[0].name] = dir;
        this.sortInfo = [];
        for (var i = 0, len = f.length; i < len; ++i) {
            this.sortInfo.push({
                field: f[i].name,
                direction: dir
            });
        }
        
        if (!this.remoteSort) {
            this.applySort();
            this.fireEvent("datachanged", this);
        } else {
            if (!this.load(this.lastOptions)) {
                if (st) {
                    this.sortToggle[f[0].name] = st;
                }
                if (si) {
                    this.sortInfo = si;
                }
            }
        }
        
    },
    
    setDefaultSort: function(field, dir){
        // alert('setDefaultSort '+ field);
        dir = dir ? dir.toUpperCase() : "ASC";
        this.sortInfo = [];
        
        if (!Ext.isArray(field)) 
            this.sortInfo.push({
                field: field,
                direction: dir
            });
        else {
            for (var i = 0, len = field.length; i < len; ++i) {
                this.sortInfo.push({
                    field: field[i].field,
                    direction: dir
                });
                this.sortToggle[field[i]] = dir;
            }
        }
    },
    
    
    groupBy: function(field, forceRegroup){
      //  alert("groupBy   " + field + "   " + forceRegroup);
        if (!forceRegroup && this.groupField == field) {
            return; // already grouped by this field
        }
        
        
        if (this.groupField) {
            for (var z = 0; z < this.groupField.length; z++) 
                if (field == this.groupField[z]) 
                    return;
            this.groupField.push(field);
        }
        else 
            this.groupField = [field];
        
        if (this.remoteGroup) {
            if (!this.baseParams) {
                this.baseParams = {};
            }
            this.baseParams['groupBy'] = field;
        }
        if (this.groupOnSort) {
            this.sort(field);
            return;
        }
        if (this.remoteGroup) {
            this.reload();
        }
        else {
            var si = this.sortInfo || [];
            if (si.field != field) {
                this.applySort();
            }
            else {
              //  alert(field);
                this.sortData(field);
            }
            this.fireEvent('datachanged', this);
        }
    },
    
    applySort: function(){
        //alert('applySort ');
        
        var si = this.sortInfo;
        
        if (si && si.length > 0 && !this.remoteSort) {
            this.sortData(si, si[0].direction);
        }
        
        if (!this.groupOnSort && !this.remoteGroup) {
            var gs = this.getGroupState();
            if (gs && gs != this.sortInfo) {
            
                this.sortData(this.groupField);
            }
        }
    },
    
    getGroupState: function(){
        // alert('getGroupState '+ this.groupField);
        return this.groupOnSort && this.groupField !== false ? (this.sortInfo ? this.sortInfo : undefined) : this.groupField;
    },
    
    sortData: function(flist, direction){
        //alert('sortData '+ direction);
        direction = direction || 'ASC';
        
        var st = [];
        
        var o;
        for (var i = 0, len = flist.length; i < len; ++i) {
            o = flist[i];
            
        //    alert(o);
            st.push(this.fields.get(o.field ? o.field : o).sortType);
        }
        
        
        var fn = function(r1, r2){
        
            var v1 = [];
            var v2 = [];
            var len = flist.length;
            var o;
            var name;
            
            for (var i = 0; i < len; ++i) {
                o = flist[i];
                name = o.field ? o.field : o;
                
                v1.push(st[i](r1.data[name]));
                v2.push(st[i](r2.data[name]));
            }
            
            var result;
            for (var i = 0; i < len; ++i) {
                result = v1[i] > v2[i] ? 1 : (v1[i] < v2[i] ? -1 : 0);
                if (result != 0) 
                    return result;
            }
            
            return result; //if it gets here, that means all fields are equal
        };
        
        this.data.sort(direction, fn);
        if (this.snapshot && this.snapshot != this.data) {
            this.snapshot.sort(direction, fn);
        }
    }
    
});


Ext.ux.MultiGroupingView = Ext.extend(Ext.grid.GroupingView, {
   constructor: function(config){
     Ext.ux.MultiGroupingView.superclass.constructor.apply(this, arguments);
     // Added so we can clear cached rows each time the view is refreshed
     this.on("beforerefresh", function() {
       //console.debug("Cleared Row Cache");
       if(this.rowsCache) delete rowsCache;
     }, this);
   }

  ,displayEmptyFields: false
    
  ,displayFieldSeperator: ', '
    
  ,renderRows: function(){
     //alert('renderRows');
     var groupField = this.getGroupField();
     var eg = !!groupField;
     // if they turned off grouping and the last grouped field is hidden
     if (this.hideGroupedColumn) {
       var colIndexes = [];
       for (var i = 0, len = groupField.length; i < len; ++i) {
         var cidx=this.cm.findColumnIndex(groupField[i]);
         if(cidx>=0){   
           colIndexes.push(cidx);}
         //else
           //console.debug("Ignore unknown column : ",groupField[i]);
       }
       if (!eg && this.lastGroupField !== undefined) {
         this.mainBody.update('');
         for (var i = 0, len = this.lastGroupField.length; i < len; ++i) {
           var cidx=this.cm.findColumnIndex(this.lastGroupField[i]);
           if(cidx>=0)
             this.cm.setHidden(cidx, false);
           else  
             alert("Unhide Col: "+cidx);
         }
         delete this.lastGroupField;
         delete this.lgflen;
       }
       
       else if (eg && colIndexes.length > 0 && this.lastGroupField === undefined) {
         this.lastGroupField = groupField;
         this.lgflen = groupField.length;
         for (var i = 0, len = colIndexes.length; i < len; ++i) {
           //alert("Hide Col: "+colIndexes[i]);
           this.cm.setHidden(colIndexes[i], true);
         }
       }

       else if (eg && this.lastGroupField !== undefined && (groupField !== this.lastGroupField || this.lgflen != this.lastGroupField.length)) {
         this.mainBody.update('');
         for (var i = 0, len = this.lastGroupField.length; i < len; ++i) {
           var cidx=this.cm.findColumnIndex(this.lastGroupField[i]);
           if(cidx>=0)
             this.cm.setHidden(cidx, false);
           else  
             alert("Unhide Col: "+cidx);
         }
         this.lastGroupField = groupField;
         this.lgflen = groupField.length;
         for (var i = 0, len = colIndexes.length; i < len; ++i) {
           //alert("Hide Col: "+colIndexes[i]);
           this.cm.setHidden(colIndexes[i], true);
         }
       }
     }
     return Ext.ux.MultiGroupingView.superclass.renderRows.apply(this, arguments);
   }

    

   /** This sets up the toolbar for the grid based on what is grouped
    * It also iterates over all the rows and figures out where each group should appeaer
    * The store at this point is already stored based on the groups.
    */
  ,doRender: function(cs, rs, ds, startRow, colCount, stripe){
     //console.debug ("doRender: ",cs, rs, ds, startRow, colCount, stripe);
     var ss = this.grid.getTopToolbar();
     if (rs.length < 1) {
       return '';
     }
        
        
     var groupField = this.getGroupField();
     var gfLen = groupField.length;
    
     // Remove all entries alreay in the toolbar
     for (var hh = 0; hh < ss.items.length; hh++) {
       Ext.removeNode(Ext.getDom(ss.items.itemAt(hh).id));
     }
     
     if(gfLen==0) {
       ss.addItem(new Ext.Toolbar.TextItem("Drop Columns Here To Group"));
       //console.debug("No Groups");
     } else {
       // Add back all entries to toolbar from GroupField[]
       ss.addItem(new Ext.Toolbar.Button({text:"Refresh", scope:this, handler:function(btn){this.grid.getStore().reload()}}));
       ss.addItem(new Ext.Toolbar.TextItem("Grouped By:"));
       for (var gfi = 0; gfi < gfLen; gfi++) {
         var t = groupField[gfi];
         if(gfi>0)
           ss.addItem(new Ext.Toolbar.Separator());
         var b = new Ext.Toolbar.Button({
            text: this.cm.lookup[this.cm.findColumnIndex(t)].header
         });
         b.fieldName = t;
         ss.addItem(b);
         //console.debug("Added Group to Toolbar :",this, t, b.text);
       }
     }

     this.enableGrouping = !!groupField;
        
     if (!this.enableGrouping || this.isUpdating) {
       return Ext.grid.GroupingView.superclass.doRender.apply(this, arguments);
     }
        
     var gstyle = 'width:' + this.getTotalWidth() + ';';
     var gidPrefix = this.grid.getGridEl().id;
     var groups = [], curGroup, i, len, gid;
     var lastvalues = [];
     var added = 0;
     var currGroups = [];

     // Create a specific style
     var st = Ext.get(gidPrefix+"-style");
     if(st) st.remove();
     Ext.getDoc().child("head").createChild({
       tag:'style',
       id:gidPrefix+"-style",
       html:"div#"+gidPrefix+" div.x-grid3-row {padding-left:"+(gfLen*12)+"px}"+
            "div#"+gidPrefix+" div.x-grid3-header {padding-left:"+(gfLen*12)+"px}"
     });
     
     for (var i = 0, len = rs.length; i < len; i++) {
       added = 0;
       var rowIndex = startRow + i;
       var r = rs[i];
       var differ = 0;
       var gvalue = [];
       var fieldName;
       var fieldLabel;
       var grpFieldNames = [];
       var grpFieldLabels = [];
       var v;
       var changed = 0;
       var addGroup = [];
           
       for (var j = 0; j < gfLen; j++) {
         fieldName = groupField[j];
         fieldLabel = this.cm.lookup[this.cm.findColumnIndex(fieldName)].header;
         v = r.data[fieldName];
         if (v) {
           if (i == 0) {
             // First record always starts a new group
             addGroup.push({idx:j,dataIndex:fieldName,header:fieldLabel,value:v});
             lastvalues[j] = v;
             
             gvalue.push(v);
             grpFieldNames.push(fieldName);
             grpFieldLabels.push(fieldLabel + ': ' + v);
             //gvalue.push(v); ????
           } else {
             if (lastvalues[j] != v) {
               // This record is not in same group as previous one
               //console.debug("Row ",i," added group. Values differ: prev=",lastvalues[j]," curr=",v);
               addGroup.push({idx:j,dataIndex:fieldName,header:fieldLabel,value:v});
               lastvalues[j] = v;
               //differ = 1;
               changed = 1;
               
               gvalue.push(v);
               grpFieldNames.push(fieldName);
               grpFieldLabels.push(fieldLabel + ': ' + v);
             } else {
                if (gfLen-1 == j && changed != 1) {
                  // This row is in all the same groups to the previous group
                  curGroup.rs.push(r);
                  //console.debug("Row ",i," added to current group ",glbl);
                } else if (changed == 1) {
                  // This group has changed because an earlier group changed.
                  addGroup.push({idx:j,dataIndex:fieldName,header:fieldLabel,value:v});
                  //console.debug("Row ",i," added group. Higher level group change");
   
                  gvalue.push(v);
                  grpFieldNames.push(fieldName);
                  grpFieldLabels.push(fieldLabel + ': ' + v);
                } else if(j<gfLen-1) {
                    // This is a parent group, and this record is part of this parent so add it
                    if(currGroups[fieldName]){
                        currGroups[fieldName].rs.push(r);}
                    //else
                        //console.error("Missing on row ",i," current group for ",fieldName);
                        
                }
             }
           }
         } else { 
           if (this.displayEmptyFields) {
             addGroup.push({idx:j,dataIndex:fieldName,header:fieldLabel,value:this.emptyGroupText||'(none)'});
             grpFieldNames.push(fieldName);
             grpFieldLabels.push(fieldLabel + ': ');
           }
         }  
       }//for j
            
       
       //if(addGroup.length>0) console.debug("Added groups for row=",i,", Groups=",addGroup);
       
/*            
       if (gvalue.length < 1 && this.emptyGroupText) 
         g = this.emptyGroupText;
       else 
         g = grpFieldNames;//.join(this.displayFieldSeperator);
*/
       for (var k = 0; k < addGroup.length; k++) {
         //g = grpFieldNames[k];
         //var glbl = grpFieldLabels[k];
         var gp=addGroup[k];
         g = gp.dataIndex;
         var glbl = addGroup[k].header;
         //var gv = addGroup[k].value;
         
         //console.debug("Create Group for ", glbl, r);
                
//         if (!curGroup || curGroup.group != gp.dataIndex || currGroup.gvalue != gp.value) {
           // There is no current group, or its not for the right field, so create one
           gid = gidPrefix + '-gp-' + gp.dataIndex + '-' + Ext.util.Format.htmlEncode(gp.value);
           
           // if state is defined use it, however state is in terms of expanded
           // so negate it, otherwise use the default.
           var isCollapsed = typeof this.state[gid] !== 'undefined' ? !this.state[gid] : this.startCollapsed;
           var gcls = isCollapsed ? 'x-grid-group-collapsed' : '';
         /*  
           if (gp.idx == gfLen-1) {
             // final group
             curGroup = {
               group: g,
               gvalue: gvalue[k],
               text: glbl,
               groupId: gid,
               startRow: rowIndex,
               rs: [r],
               cls: gcls,
               style: gstyle + 'padding-left:' + (gp.idx * 12) + 'px;'
             };
           } else {*/
             curGroup = {
               group: gp.dataIndex,
               gvalue: gp.value,
               text: gp.header,
               groupId: gid,
               startRow: rowIndex,
               rs: [r],
               cls: gcls,
               style: gstyle + 'padding-left:' + (gp.idx * 12) + 'px;'
             };
           //}
           currGroups[gp.dataIndex]=curGroup;
           groups.push(curGroup);
           
//         } else {
//           curGroup.rs.push(r);
//           console.debug("**** Added row ",i," to group ",curGroup);
//         }
         r._groupId = gid; // Associate this row to a group
       }//for k
     }//for i

     var buf = [];
     var toEnd = 0;
     for (var ilen = 0, len = groups.length; ilen < len; ilen++) {
       toEnd++;
       var g = groups[ilen];
       var leaf = g.group == groupField[gfLen - 1] 
       this.doGroupStart(buf, g, cs, ds, colCount);
       
       //console.debug(g,buf.length,"=",buf[buf.length-1]);
       
       if (g.rs.length != 0 && leaf) 
         buf[buf.length] = Ext.grid.GroupingView.superclass.doRender.call(this, cs, g.rs, ds, g.startRow, colCount, stripe);
       
       if (leaf) {
         var jj;
         var gg = groups[ilen + 1];
         if (gg != null) {
           for (var jj = 0; jj < groupField.length; jj++) {
             if (gg.group == groupField[jj]) 
               break;
           }
           toEnd = groupField.length - jj;
         }
         for (var k = 0; k < toEnd; k++) {
           this.doGroupEnd(buf, g, cs, ds, colCount);
         }
         toEnd = jj;
       }
         
     }
     
     return buf.join('');
   }
   
   
    
   /** Should return an array of all elements that represent a row, it should bypass
    *  all grouping sections
    */
  ,getRows: function(){
  
        // This function is called may times, so use a cache if it is available
        if(this.rowsCache)
          r = this.rowsCache.slice(0);
        else {
          //alert('getRows');
          if (!this.enableGrouping) {
              return Ext.grid.GroupingView.superclass.getRows.call(this);
          }
          var groupField = this.getGroupField();
          var r = [];
          var g, gs = this.getGroups();
          // this.getGroups() contains an array of DIVS for the top level groups
          //console.debug("Get Rows", groupField, gs);

          r = this.getRowsFromGroup(r, gs, groupField[groupField.length - 1]);
     
          // Clone the array, but not the objects in it
          //this.rowsCache = r.slice(0);
        }    
        //console.debug("Found ", r.length, " rows");
        return r;
    }
    
   /** Return array of records under a given group
    * @param r Record array to append to in the returned object
    * @param gs Grouping Sections, an array of DIV element that represent a set of grouped records
    * @param lsField The name of the grouping section we want to count
    */
  ,getRowsFromGroup: function(r, gs, lsField){
        var rx = new RegExp(".*-gp-"+lsField+"-.*");

        // Loop over each section
        for (var i = 0, len = gs.length; i < len; i++) {

            // Get group name for this section
            var groupName = gs[i].id;
            if(rx.test(groupName)) {
                //console.debug(groupName, " matched ", lsField);
                g = gs[i].childNodes[1].childNodes;
                for (var j = 0, jlen = g.length; j < jlen; j++) {
                    r[r.length] = g[j];
                }
                //console.debug("Found " + g.length + " rows for group " + lsField);
            } else {
                if(!gs[i].childNodes[1]) {
                    //console.error("Can't get rowcount for field ",lsField," from ",gs,i);
                } else 
                // if its an interim level, each group needs to be traversed as well
                r = this.getRowsFromGroup(r, gs[i].childNodes[1].childNodes, lsField);
            }
        }
        return r;
    }
});


Ext.ux.MultiGroupingPanel = function(config) {
    config = config||{};
    config.tbar = new Ext.Toolbar({id:'grid-tbr'});
    Ext.ux.MultiGroupingPanel.superclass.constructor.call(this, config);
    //console.debug("Create MultiGroupingPanel",config);
};
Ext.extend(Ext.ux.MultiGroupingPanel, Ext.grid.GridPanel, {

   initComponent : function(){
     //console.debug("MultiGroupingPanel.initComponent",this);
     Ext.ux.MultiGroupingPanel.superclass.initComponent.call(this);
     
     // Initialise DragZone
     this.on("render", this.setUpDragging, this);
   }
    
  ,setUpDragging: function() {
        //console.debug("SetUpDragging", this);
        this.dragZone = new Ext.dd.DragZone(this.getTopToolbar().getEl(), {
            ddGroup:"grid-body"
           ,panel:this 
           ,scroll:false
            // @todo - docs
           ,onInitDrag : function(e) {
                // alert('init');
                var clone = this.dragData.ddel;
                clone.id = Ext.id('ven');
                // clone.class='x-btn button';
                this.proxy.update(clone);
                return true;
            }

            // @todo - docs
           ,getDragData: function(e) {
                var target = Ext.get(e.getTarget().id);
                if(target.hasClass('x-toolbar x-small-editor')) {
                    return false;
                }
                
                d = e.getTarget().cloneNode(true);
                d.id = Ext.id();
                //console.debug("getDragData",this, target);
                
                this.dragData = {
                    repairXY: Ext.fly(target).getXY(),
                    ddel: d,
                    btn:e.getTarget()
                };
                return this.dragData;
            }

            //Provide coordinates for the proxy to slide back to on failed drag.
            //This is the original XY coordinates of the draggable element.
           ,getRepairXY: function() {
                return this.dragData.repairXY;
            }

        });
        
        // This is the target when columns are dropped onto the toolbar (ie added to the group)
        this.dropTarget2s = new Ext.dd.DropTarget('grid-tbr', {
            ddGroup: "gridHeader" + this.getGridEl().id
           ,panel:this 
           ,notifyDrop: function(dd, e, data) {
                //console.debug("Adding Filter", data);
                var btname= this.panel.getColumnModel().getDataIndex( this.panel.getView().getCellIndex(data.header));
                this.panel.store.groupBy(btname);
                return true;
            }
        });

        // This is the target when columns are dropped onto the grid (ie removed from the group)
        this.dropTarget22s = new Ext.dd.DropTarget(this.getView().el.dom.childNodes[0].childNodes[1], {
            ddGroup: "grid-body"
           ,panel:this 
           ,notifyDrop: function(dd, e, data) {
                var txt = Ext.get(data.btn).dom.innerHTML;
                var tb = this.panel.getTopToolbar();
                //console.debug("Removing Filter", txt);
                var bidx = tb.items.findIndexBy(function(b) {
                    console.debug("Match button ",b.text);
                    return b.text==txt;
                },this);
                //console.debug("Found matching button", bidx);
                if(bidx<0) return; // Error!
                var fld = tb.items.get(bidx).fieldName;
                
                // Remove from toolbar
                Ext.removeNode(Ext.getDom(tb.items.get(bidx).id));
                if(bidx>0) Ext.removeNode(Ext.getDom(tb.items.get(bidx-1).id));;

                //console.debug("Remove button", fld);
                //console.dir(button);
                var cidx=this.panel.view.cm.findColumnIndex(fld);
                
                //if(cidx<0)
                //    console.error("Can't find column for field ", fld);
                
                this.panel.view.cm.setHidden(cidx, false);

                //Ext.removeNode(Ext.getDom(data.btn.id));

                var temp=[];

                for(var i=this.panel.store.groupField.length-1;i>=0;i--) {
                    if(this.panel.store.groupField[i]==fld) {
                        this.panel.store.groupField.pop();
                        break;
                    }
                    temp.push(this.panel.store.groupField[i]);
                    this.panel.store.groupField.pop();
                }

                for(var i=temp.length-1;i>=0;i--) {
                        this.panel.store.groupField.push(temp[i]);
                }

                if(this.panel.store.groupField.length==0)
                    this.panel.store.groupField=false;

                this.panel.store.fireEvent('datachanged', this);
                return true;
            }
        }); 

    }
});


