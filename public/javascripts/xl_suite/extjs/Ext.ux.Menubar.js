Ext.namespace('Ext.ux');

Ext.ux.Menubar = function(config){
    Ext.ux.Menubar.superclass.constructor.call(this, config);
    this.cls += " x-menubar";
    if (this.orientation == "vertical") {
        this.subMenuAlign = "tl-tr?";
        this.cls += " x-vertical-menubar";
    } else {
        this.subMenuAlign = "tl-bl?";
        this.cls += " x-horizontal-menubar";
    }
};


Ext.extend(Ext.ux.Menubar, Ext.menu.Menu, {
    plain: true,
    cls: "",
    minWidth : 120,
    shadow : false,
    orientation: "horizontal",
    activated: false,
    activatedClass: "x-menu-activated",

    // private
    render : function(container){
        if(this.el){
            return;
        }
        if (container) {
            var el = this.el = Ext.get(container);
            el.addClass("x-menu");
        } else {
            var el = this.el = new Ext.Layer({
                cls: "x-menu",
                shadow:this.shadow,
                constrain: false,
                parentEl: this.parentEl || document.body,
                zindex:15000
            });
        }

        this.keyNav = new Ext.menu.MenuNav(this);

        if(this.plain){
            el.addClass("x-menu-plain");
        }
        if(this.cls){
            el.addClass(this.cls);
        }
        // generic focus element
        this.focusEl = el.createChild({
            tag: "a", cls: "x-menu-focus", href: "#", onclick: "return false;", tabIndex:"-1"
        });
        var ul = el.createChild({tag: "ul", cls: "x-menu-list"});
        ul.on("click", this.onClick, this);
        ul.on("mouseover", this.onMouseOver, this);
        ul.on("mouseout", this.onMouseOut, this);
        this.items.each(function(item){
            var li = document.createElement("li");
            if(item.menu) {
                li.className = "x-menu-list-item x-menu-item-arrow";
            } else {
                li.className = "x-menu-list-item";
            }
            if(item.align == 'right') {
                li.style.cssFloat = "right";
            }
            ul.dom.appendChild(li);
            item.render(li, this);
        }, this);
        this.ul = ul;
        // this.autoWidth(); // not for menu bars.
    },

    show: function(container) {
        this.fireEvent("beforeshow", this);
        if(!this.el){
            this.render(container);
        }
        this.fireEvent("show", this);
    },

    hide: function(){
        this.fireEvent("beforehide", this);
        if(this.activeItem){
            this.activeItem.deactivate();
            delete this.activeItem;
        }
        this.deactivate();
        this.fireEvent("hide", this);       
    },

    onClick : function(e){
        var t = this.findTargetItem(e);
        
        if(t && t.menu === undefined){
            t.onClick(e);
            this.fireEvent("click", this, t, e);
        } else {
            if (this.activated) {
                this.deactivate();
                this.activeItem.hideMenu();
            } else if(t){
                this.activate();
                if(t.canActivate && !t.disabled){
                    this.setActiveItem(t, true);
                }
                this.fireEvent("click", this, e, t);
            }
            e.stopEvent();
        }
    },

    onMouseOver : function(e){ 
        var t;
        if(t = this.findTargetItem(e)){
            if(t.canActivate && !t.disabled){
                this.setActiveItem(t, this.activated);
            }
        }
        this.fireEvent("mouseover", this, e, t);
    },

    onMouseOut : function(e){
        var t;
        if(!this.activated)
        {
            if(t = this.findTargetItem(e)){
                if(t == this.activeItem && t.shouldDeactivate(e)){
                    this.activeItem.deactivate();
                    delete this.activeItem;
                }
            }
            this.fireEvent("mouseout", this, e, t);
        }
    },    
    
    activate : function(){
        // Sort of a hack to deactivate the menu when clicked somewere else or when an other menu opens.
        this.fireEvent("beforeshow", this);
        this.fireEvent("show", this);

        this.activated = true;
        this.ul.addClass("x-menu-activated");
    },    
    
    deactivate : function(){
        this.activated = false;
        this.ul.removeClass("x-menu-activated");
    }    
});