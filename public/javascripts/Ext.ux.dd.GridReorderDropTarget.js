Ext.namespace('Ext.ux.dd');

Ext.ux.dd.GridReorderDropTarget = function(grid, config) {
    this.target = new Ext.dd.DropTarget(grid.getEl(), {
        ddGroup: grid.ddGroup || 'GridDD'
        ,grid: grid
        ,gridDropTarget: this
        ,notifyDrop: function(dd, e, data){
            // determine the row
            var t = Ext.lib.Event.getTarget(e);
            var rindex = this.grid.getView().findRowIndex(t);
            if (rindex === false) return false;
            if (rindex == data.rowIndex) return false;
            
            var ds = this.grid.getStore();
            var moveToSelected = false;
            data.selections.each(function(obj){
              if (rindex == ds.indexOfId(obj.id))
                moveToSelected = true;
            });
            if (moveToSelected === true) return false;
            
            // fire the before move/copy event
            if (this.gridDropTarget.fireEvent(this.copy?'beforerowcopy':'beforerowmove', this.gridDropTarget, data.rowIndex, rindex, data.selections) === false) return false;

            // move to correct row if multiple rows are being moved
            var itemsAboveTarget = 0;
            data.selections.each(function(obj){
              if (ds.indexOfId(obj.id) < rindex) {
                itemsAboveTarget++;
              }
            });
            // for moving multiple rows down
            if(itemsAboveTarget>0)
              itemsAboveTarget--;
            rindex = rindex - itemsAboveTarget;

            // update the store
            if (!this.copy) {
                for(i = 0; i < data.selections.length; i++) {
                    ds.remove(ds.getById(data.selections[i].id));
                }
            }
            for(i = data.selections.length; i > 0; i--){
              ds.insert(rindex,data.selections[i-1]);
            }
            

            // re-select the row(s)
            var sm = this.grid.getSelectionModel();
            if (sm) sm.selectRecords(data.selections);

            // fire the after move/copy event
            this.gridDropTarget.fireEvent(this.copy?'afterrowcopy':'afterrowmove', this.gridDropTarget, data.rowIndex, rindex, data.selections);

            return true;
        }
        ,notifyOver: function(dd, e, data) {
            var t = Ext.lib.Event.getTarget(e);
            var rindex = this.grid.getView().findRowIndex(t);
            if (rindex == data.rowIndex) rindex = false;
            var ds = this.grid.getStore();
            data.selections.each(function(obj){
              if (rindex == ds.indexOfId(obj.id))
                rindex = false;
            });

            return (rindex === false)? this.dropNotAllowed : this.dropAllowed;
        }
    });
    if (config) {
        Ext.apply(this.target, config);
        if (config.listeners) Ext.apply(this,{listeners: config.listeners});
    }

    this.addEvents({
        "beforerowmove": true
        ,"afterrowmove": true
        ,"beforerowcopy": true
        ,"afterrowcopy": true
    });

    Ext.ux.dd.GridReorderDropTarget.superclass.constructor.call(this);
};

Ext.extend(Ext.ux.dd.GridReorderDropTarget, Ext.util.Observable, {
    getTarget: function() {
        return this.target;
    }
    ,getGrid: function() {
        return this.target.grid;
    }
    ,getCopy: function() {
        return this.target.copy?true:false;
    }
    ,setCopy: function(b) {
        this.target.copy = b?true:false;
    }
});