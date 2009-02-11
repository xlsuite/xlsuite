/**
 * @class Ext.tree.TreeCheckNodeUI
 * @extends Ext.tree.TreeNodeUI
 *
 * Some extends features available:
 * (1) single check model (allow only one treeNode checked)
 *		usage:  checkModel: "single" 
 * (2) cascade check model (when check/uncheck a node,will auto check/uncheck it's childrenNodes, and it's all parentNodes,suport asyn's node loads situation)
 *		usage:  checkModel: "cascade"
 * (3) only leaf node can check model
 *		only when the node's attribute leaf is true,then the node has checkbox
 *		usage:  onlyLeafCheckable: true  , default is false,all nodes have checkbox
 *
 * checkModel default is 'multiple' , then all node with checkbox can checked
 *
 * Supported events:
 * check (when the node's checkbox value change, will fire this event)
 *
 * usage:
 *    just add attribute  baseAttrs: { uiProvider: Ext.ux.TreeCheckNodeUI }  to tree's loader
 *
 * for example:
 *
 *   var tree = new Ext.tree.TreePanel({
 *		el:'tree-ct',
 *		width:568,
 *		height:300,
 *		checkModel: 'cascade',   // cascade check
 *		onlyLeafCheckable: false,// all node have checkbox
 *		animate: false,
 *		rootVisible: false,
 *		autoScroll:true,
 *		loader: new Tree.TreeLoader({
 *			dataUrl:'get-nodes.php'
 *			baseAttrs: { uiProvider: Ext.ux.TreeCheckNodeUI } //add uiProvider attribute
 *		}),
 *		root: new Ext.tree.AsyncTreeNode({ id:'0' })
 *	});
 *	tree.on("check",function(node,checked){alert(node.text+" = "+checked)}); 
 *	tree.render();
 */

Ext.tree.TreeCheckNodeUI = function(config) {
	//'multiple': multiple check model; 'single': single check model; 'cascade':cascade check model
	this.checkModel = 'multiple';

	//only leaf node has checkbox
	this.onlyLeafCheckable = false;
	
	this.disableCheckWhenDblClick = false;
	this.disableAnimatingWhenDblClick = false;
	
	Ext.tree.TreeCheckNodeUI.superclass.constructor.apply(this, arguments);
};

Ext.extend(Ext.tree.TreeCheckNodeUI, Ext.tree.TreeNodeUI, {

    renderElements : function(n, a, targetNode, bulkRender){
    	var tree = n.getOwnerTree();
		this.checkModel = tree.checkModel || this.checkModel;
		this.onlyLeafCheckable = tree.onlyLeafCheckable || false;
    this.disableCheckWhenDblClick = tree.disableCheckWhenDblClick || this.disableCheckWhenDblClick;
    this.disableAnimatingWhenDblClick = tree.disableAnimatingWhenDblClick || this.disableAnimatingWhenDblClick;
        // add some indent caching, this helps performance when rendering a large tree
        this.indentMarkup = n.parentNode ? n.parentNode.ui.getChildIndent() : '';

        //var cb = typeof a.checked == 'boolean';
		var cb = (!this.onlyLeafCheckable || a.leaf);
        var href = a.href ? a.href : Ext.isGecko ? "" : "#";
        var buf = ['<li class="x-tree-node"><div ext:tree-node-id="',n.id,'" class="x-tree-node-el x-tree-node-leaf x-unselectable ', a.cls,'" unselectable="on">',
            '<span class="x-tree-node-indent">',this.indentMarkup,"</span>",
            '<img src="', this.emptyIcon, '" class="x-tree-ec-icon x-tree-elbow" />',
            '<img src="', a.icon || this.emptyIcon, '" class="x-tree-node-icon',(a.icon ? " x-tree-node-inline-icon" : ""),(a.iconCls ? " "+a.iconCls : ""),'" unselectable="on" />',
            cb ? ('<input class="x-tree-node-cb" type="checkbox" ' + (a.checked ? 'checked="checked" />' : '/>')) : '',
            '<a hidefocus="on" class="x-tree-node-anchor" href="',href,'" tabIndex="1" ',
             a.hrefTarget ? ' target="'+a.hrefTarget+'"' : "", '><span unselectable="on">',n.text,"</span></a></div>",
            '<ul class="x-tree-node-ct" style="display:none;"></ul>',
            "</li>"].join('');

        var nel;
        if(bulkRender !== true && n.nextSibling && (nel = n.nextSibling.ui.getEl())){
            this.wrap = Ext.DomHelper.insertHtml("beforeBegin", nel, buf);
        }else{
            this.wrap = Ext.DomHelper.insertHtml("beforeEnd", targetNode, buf);
        }
        
        this.elNode = this.wrap.childNodes[0];
        this.ctNode = this.wrap.childNodes[1];
        var cs = this.elNode.childNodes;
        this.indentNode = cs[0];
        this.ecNode = cs[1];
        this.iconNode = cs[2];
        var index = 3;
        if(cb){
            this.checkbox = cs[3];
            Ext.fly(this.checkbox).on('click', this.check.createDelegate(this,[null]));
            index++;
        }
        this.anchor = cs[index];
        this.textNode = cs[index].firstChild;
    },
    
    // private
    check : function(checked){
        var n = this.node;
		var tree = n.getOwnerTree();
		this.checkModel = tree.checkModel || this.checkModel;
		
		if( checked === null ) {
			checked = this.checkbox.checked;
		} else {
			this.checkbox.checked = checked;
		}
		
		n.attributes.checked = checked;
		tree.fireEvent('check', n, checked);
		
		if(!this.onlyLeafCheckable && this.checkModel == 'cascade'){
			var parentNode = n.parentNode;
			if(parentNode !== null) {
				this.parentCheck(parentNode,checked);
			}
			if( !n.expanded && !n.childrenRendered ) {
				n.expand(false,false,this.childCheck);
			}
			else {
				this.childCheck(n);
			}
		}else if(this.checkModel == 'single'){
			var checkedNodes = tree.getChecked();
			for(var i=0;i<checkedNodes.length;i++){
				var node = checkedNodes[i];
				if(node.id != n.id){
					node.getUI().checkbox.checked = false;
					node.attributes.checked = false;
					tree.fireEvent('check', node, false);
				}
			}
		}
        
    },
    
    // private
	childCheck : function(node){
		var a = node.attributes;
		if(!a.leaf) {
			var cs = node.childNodes;
			var csui;
			for(var i = 0; i < cs.length; i++) {
				csui = cs[i].getUI();
				if(csui.checkbox.checked ^ a.checked)
					csui.check(a.checked);
			}
		}
	},
	
	// private
	parentCheck : function(node ,checked){
		var checkbox = node.getUI().checkbox;
		if(typeof checkbox == 'undefined')return ;
		if(!(checked ^ checkbox.checked))return;
		if(!checked && this.childHasChecked(node))return;
		checkbox.checked = checked;
		node.attributes.checked = checked;
		node.getOwnerTree().fireEvent('check', node, checked);
		
		var parentNode = node.parentNode;
		if( parentNode !== null){
			this.parentCheck(parentNode,checked);
		}
	},
	
	// private
	childHasChecked : function(node){
		var childNodes = node.childNodes;
		if(childNodes || childNodes.length>0){
			for(var i=0;i<childNodes.length;i++){
				if(childNodes[i].getUI().checkbox.checked)
					return true;
			}
		}
		return false;
	},

	//private
    toggleCheck : function(value){
    	var cb = this.checkbox;
        if(cb){
            var checked = (value === undefined ? !cb.checked : value);
            this.check(checked);
        }
    },

  onDblClick: function(e){
      e.preventDefault();
      if(this.disabled){
          return;
      }
      if(this.checkbox && !this.disableCheckWhenDblClick){
          this.toggleCheck();
      }
      if(!this.animating && this.node.hasChildNodes() && !this.disableAnimatingWhenDblClick){
          this.node.toggle();
      }
      this.fireEvent("dblclick", this.node, e);
  }
});
