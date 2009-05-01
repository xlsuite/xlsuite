Ext.namespace('Ext.ux');

Ext.ux.PageSizePlugin = function() {
    Ext.ux.PageSizePlugin.superclass.constructor.call(this, {
        store: new Ext.data.SimpleStore({
            fields: ['text', 'value'],
            data: [['10', 10], ['25', 25], ['50', 50], ['100', 100], ['200', 200]]
        }),
        mode: 'local',
        displayField: 'text',
        valueField: 'value',
        editable: false,
        allowBlank: false,
        triggerAction: 'all',
        width: 50
    });
};

Ext.extend(Ext.ux.PageSizePlugin, Ext.form.ComboBox, {
    init: function(paging) {
        paging.on('render', this.onInitView, this);
        Ext.ux.PageSizePlugin.prototype.paging = paging;
    },
    
    onInitView: function(paging) {
        paging.add('-',
            this,
            'Items per page'
        );
        this.setValue(paging.pageSize);
        this.on('select', this.onPageSizeChanged, paging);
    },
    
    onPageSizeChanged: function(combo) {
        this.pageSize = null;
        if (combo.getValue() == "all") {
          this.pageSize = parseInt(Ext.ux.PageSizePlugin.prototype.paging.store.getTotalCount());
        }
        else {
          this.pageSize = parseInt(combo.getValue());
        }
        this.doLoad(0);
    }
});