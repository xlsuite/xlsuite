/**
 * RowAction plugin for Ext grid
 *
 * Contains renderer for an icon and fires events when icon is clicked
 *
 * @author    Ing. Jozef Sakalos <jsakalos at aariadne dot com>
 * @date      December 29, 2007
 * @version   $Id: Ext.ux.grid.RowAction.js 3 2007-12-30 00:34:28Z jozo $
 */

Ext.namespace('Ext.ux', 'Ext.ux.grid');

/**
 * @class Ext.ux.grid.RowAction
 * @extends Ext.util.Observable
 *
 * Creates new RowAction plugin
 * @constructor
 * @param {Object} config The config object
 *
 * @cfg {String} iconCls css class that defines background image
 */
Ext.ux.grid.RowAction = function(config) {
    Ext.apply(this, config);

    this.addEvents({
        /**
         * @event beforeaction
         * Fires before action event. Return false to cancel the subsequent action event.
         * @param {Ext.grid.GridPanel} grid
         * @param {Ext.data.Record} record Record corresponding to row clicked
         * @param {Integer} rowIndex 
         */
         beforeaction:true
        /**
         * @event action
         * Fires when icon is clicked
         * @param {Ext.grid.GridPanel} grid
         * @param {Ext.data.Record} record Record corresponding to row clicked
         * @param {Integer} rowIndex 
         */
        ,action:true
    });

    Ext.ux.grid.RowAction.superclass.constructor.call(this);
};

Ext.extend(Ext.ux.grid.RowAction, Ext.util.Observable, {
     header:''
    ,sortable:false
    ,dataIndex:''
    ,width:20
    ,fixed:true
    ,lazyRender:true
    ,iconCls:''
    ,renderer: function(value, cell, record, row, col, event) { return '<div class="' + this.iconCls + '">&nbsp;</div>'; }
    
    // private - plugin initialization
    ,init:function(grid) {
        this.grid = grid;
        var view = grid.getView();
        grid.on({
            render:{scope:this, fn:function() {
                view.mainBody.on({
                    click:{scope:this, fn:this.onClick}
                });
            }}
        });
        this.renderer.createDelegate(this);
    } // end of function init

    // private - icon click handler
    ,onClick:function(e, target) {
        var row, record;
        e.stopEvent();
        
        // There's a good chance the target will have multiple
        // classes, so just look for the one
        if(target.className.include(this.iconCls)) {
            row = e.getTarget('.x-grid3-row');
            if(row) {
                record = this.grid.store.getAt(row.rowIndex);
                if(false !== this.fireEvent('beforeaction', this.grid, record, row.rowIndex)) {
                    this.fireEvent('action', this.grid, record, row.rowIndex, e);
                }
            }
        }
    } // end of function onClick
});

// end of file