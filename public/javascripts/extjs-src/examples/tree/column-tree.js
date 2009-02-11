Ext.onReady(function(){
    var tree = new Ext.tree.ColumnTree({
        el:'tree-ct',
        width:552,
        autoHeight:true,
        rootVisible:false,
        autoScroll:true,
        title: 'Example Tasks',
        
        columns:[{
            header:'Task',
            width:350,
            dataIndex:'task'
        },{
            header:'Duration',
            width:100,
            dataIndex:'duration'
        },{
            header:'Assigned To',
            width:100,
            dataIndex:'user'
        }],

        loader: new Ext.tree.TreeLoader({
            dataUrl:'column-data.json',
            uiProviders:{
                'col': Ext.tree.ColumnNodeUI
            }
        }),

        root: new Ext.tree.AsyncTreeNode({
            text:'Tasks'
        })
    });
    tree.render();
});