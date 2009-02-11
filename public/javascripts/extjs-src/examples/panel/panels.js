Ext.onReady(function(){
    var p = new Ext.Panel({
        title: 'My Panel',
        collapsible:true,
        renderTo: 'container',
        width:400,
        html: Ext.example.bogusMarkup
    });
});