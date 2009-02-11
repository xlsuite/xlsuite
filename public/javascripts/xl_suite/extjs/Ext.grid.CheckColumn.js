Ext.grid.CheckColumn = function(config){
  this.addEvents({
    click: true
  });
  Ext.grid.CheckColumn.superclass.constructor.call(this);
  
  Ext.apply(this, config, {
    init : function(grid){
      this.grid = grid;
      this.grid.on('render', function(){
          var view = this.grid.getView();
          view.mainBody.on('mousedown', this.onMouseDown, this);
      }, this);
    },

    onMouseDown : function(e, t){
      if(t.className && t.className.indexOf('x-grid3-cc-'+this.id) != -1){
        e.stopEvent();
        var index = this.grid.getView().findRowIndex(t);
        var record = this.grid.store.getAt(index);
        record.set(this.dataIndex, !record.data[this.dataIndex]);
        this.fireEvent('click', this, e, record);
      }
    },

    renderer : function(v, p, record){
      p.css += ' x-grid3-check-col-td'; 
      return '<div class="x-grid3-check-col'+(v?'-on':'')+' x-grid3-cc-'+this.id+'"> </div>';
    }
  });
  
  if(!this.id){
      this.id = Ext.id();
  }
  this.renderer = this.renderer.createDelegate(this);
};


Ext.extend(Ext.grid.CheckColumn, Ext.util.Observable);