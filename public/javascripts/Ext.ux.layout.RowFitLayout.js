Ext.namespace('Ext.ux.layout'); 

/** 
 * @class Ext.ux.layout.RowFitLayout 
 * @extends Ext.layout.ContainerLayout 
 * <p>Layout that distributes heights of elements so they take 100% of the 
 * container height.</p> 
 * <p>Height of the child element can be given in pixels (as an integer) or 
 * in percent. All elements with absolute height (i.e. in pixels) always will 
 * have the given height. All "free" space (that is not filled with elements 
 * with 'absolute' height) will be distributed among other elements in 
 * proportion of their height percentage. Elements without 'height' in the 
 * config will take equal portions of the "unallocated" height.</p> 
 * <p>Supports panel collapsing, hiding, removal/addition. The adapter is provided 
 * to use with Ext.SplitBar: <b>Ext.ux.layout.RowFitLayout.SplitAdapter</b>.</p> 
 * <p>Example usage:</p> 
 * <pre><code> 
 var vp = new Ext.Viewport({ 
   layout: 'row-fit', 
   items: [ 
     { xtype: 'panel', height: 100, title: 'Height in pixels', html: 'panel height = 100px' }, 
     { xtype: 'panel', height: "50%", title: '1/2', html: 'Will take half of remaining height' }, 
     { xtype: 'panel', title: 'No height 1', html: 'Panel without given height' }, 
     { xtype: 'panel', title: 'No height 2', html: 'Another panel' } 
   ] 
 }); 
 * </code></pre> 
 * Usage of the split bar adapter: 
 * <pre><code> 
 var split = new Ext.SplitBar("elementToDrag", "elementToSize", Ext.SplitBar.VERTICAL, Ext.SplitBar.TOP); 
 // note the Ext.SplitBar object is passed to the adapter constructor to set 
 // correct minSize and maxSize: 
 split.setAdapter(new Ext.ux.layout.RowFitLayout.SplitAdapter(split)); 
 * </code></pre> 
 */ 

Ext.ux.layout.RowFitLayout = Ext.extend(Ext.layout.ContainerLayout, { 
  // private 
  monitorResize: true, 

  // private 
  trackChildEvents: ['collapse', 'expand', 'hide', 'show'], 

  // private 
  renderAll: function(ct, target) { 
    Ext.ux.layout.RowFitLayout.superclass.renderAll.apply(this, arguments); 
    // add event listeners on addition/removal of children 
    ct.on('add', this.containerListener); 
    ct.on('remove', this.containerListener); 
  }, 

  // private 
  renderItem: function(c, position, target) { 
    Ext.ux.layout.RowFitLayout.superclass.renderItem.apply(this, arguments); 

    // add event listeners 
    for (var i=0, n = this.trackChildEvents.length; i < n; i++) { 
      c.on(this.trackChildEvents[i], this.itemListener); 
    } 
    c.animCollapse = false; // looks ugly together with row-fit layout 

    // store some layout-specific calculations 
    c.rowFit = { 
      hasAbsHeight: false, // whether the component has absolute height (in pixels) 
      relHeight: 0, // relative height, in pixels (if applicable) 
      calcRelHeight: 0, // calculated relative height (used when element is resized) 
      calcAbsHeight: 0 // calculated absolute height 
    }; 

    // process height config option 
    if (c.height) { 
      // store relative (given in percent) height 
      if (typeof c.height == "string" && c.height.indexOf("%")) { 
        c.rowFit.relHeight = parseInt(c.height); 
      } 
      else { // set absolute height 
        c.setHeight(c.height); 
        c.rowFit.hasAbsHeight = true; 
      } 
    } 
  }, 

  // private 
  onLayout: function(ct, target) { 
    Ext.ux.layout.RowFitLayout.superclass.onLayout.call(this, ct, target); 

    if (this.container.collapsed || !ct.items || !ct.items.length) { return; } 

    // first loop: determine how many elements with relative height are there, 
    // sums of absolute and relative heights etc. 
    var absHeightSum = 0, // sum of elements' absolute heights 
        relHeightSum = 0, // sum of all percent heights given in children configs 
        relHeightRatio = 1, // "scale" ratio used in case sum <> 100% 
        relHeightElements = [], // array of elements with 'relative' height for the second loop 
        noHeightCount = 0; // number of elements with no height given 

    for (var i=0, n = ct.items.length; i < n; i++) { 
      var c = ct.items.itemAt(i); 

      if (!c.isVisible()) { continue; } 

      // collapsed panel is treated as an element with absolute height 
      if (c.collapsed) { absHeightSum += c.getFrameHeight(); } 
      // element that has an absolute height 
      else if (c.rowFit.hasAbsHeight) { 
        absHeightSum += c.height; 
      } 
      // 'relative-heighted' 
      else { 
        if (!c.rowFit.relHeight) { noHeightCount++; } // element with no height given 
        else { relHeightSum += c.rowFit.relHeight; } 
        relHeightElements.push(c); 
      } 
    } 

    // if sum of relative heights <> 100% (e.g. error in config or consequence 
    // of collapsing/removing panels), scale 'em so it becomes 100% 
    if (noHeightCount == 0 && relHeightSum != 100) { 
      relHeightRatio = 100 / relHeightSum; 
    } 

    var freeHeight = target.getStyleSize().height - absHeightSum, // "unallocated" height we have 
        absHeightLeft = freeHeight; // track how much free space we have 

    while (relHeightElements.length) { 
      var c = relHeightElements.shift(), // element we're working with 
          relH = c.rowFit.relHeight * relHeightRatio, // height of this element in percent 
          absH = 0; // height in pixels 

      // no height in config 
      if (!relH) { 
        relH = (100 - relHeightSum) / noHeightCount; 
      } 

      // last element takes all remaining space 
      if (!relHeightElements.length) { absH = absHeightLeft; } 
      else { absH = Math.round(freeHeight * relH / 100); } 

      // anyway, height can't be negative 
      if (absH < 0) { absH = 0; } 

      c.rowFit.calcAbsHeight = absH; 
      c.rowFit.calcRelHeight = relH; 

      c.setHeight(absH); 
      absHeightLeft -= absH; 
    } 

  }, 


  /** 
   * Event listener for container's children 
   * @private 
   */ 
  itemListener: function(item) { 
    item.ownerCt.doLayout(); 
  }, 


  /** 
   * Event listener for the container (on add, remove) 
   * @private 
   */ 
  containerListener: function(ct) { 
    ct.doLayout(); 
  } 

}); 

// Split adapter 
if (Ext.SplitBar.BasicLayoutAdapter) { 

  /** 
   * @param {Ext.SplitBar} splitbar to which adapter is applied. 
   *   If supplied, will set correct minSize and maxSize. 
   */ 
  Ext.ux.layout.RowFitLayout.SplitAdapter = function(splitbar) { 
    if (splitbar && splitbar.el.dom.nextSibling) { 
      var next = Ext.getCmp( splitbar.el.dom.nextSibling.id ), 
          resized = Ext.getCmp(splitbar.resizingEl.id); 

      if (next) { 
        splitbar.maxSize = (resized.height || resized.rowFit.calcAbsHeight) + 
                           next.getInnerHeight() - 1; // seems can't set height=0 in IE, "1" works fine 
      } 
      splitbar.minSize = resized.getFrameHeight() + 1; 
    } 
  } 

  Ext.extend(Ext.ux.layout.RowFitLayout.SplitAdapter, Ext.SplitBar.BasicLayoutAdapter, { 

    setElementSize: function(splitbar, newSize, onComplete) { 
      var resized = Ext.getCmp(splitbar.resizingEl.id); 

      // can't resize absent, collapsed or hidden panel 
      if (!resized || resized.collapsed || !resized.isVisible()) return; 

      // resizingEl has absolute height: just change it 
      if (resized.rowFit.hasAbsHeight) { 
        resized.setHeight(newSize); 
      } 
      // resizingEl has relative height: affects next sibling 
      else { 
        if (splitbar.el.dom.nextSibling) { 
          var nextSibling = Ext.getCmp( splitbar.el.dom.nextSibling.id ), 
              deltaAbsHeight = newSize - resized.rowFit.calcAbsHeight, // pixels 
              nsRf = nextSibling.rowFit, // shortcut 
              rzRf = resized.rowFit, 
              // pixels in a percent 
              pctPxRatio = rzRf.calcRelHeight / rzRf.calcAbsHeight, 
              deltaRelHeight = pctPxRatio * deltaAbsHeight; // change in height in percent 

          rzRf.relHeight = rzRf.calcRelHeight + deltaRelHeight; 

          if (nsRf.hasAbsHeight) { 
            var newHeight = nextSibling.height - deltaAbsHeight; 
            nextSibling.height = newHeight; 
            nextSibling.setHeight(newHeight); 
          } 
          else { 
            nsRf.relHeight = nsRf.calcRelHeight - deltaRelHeight; 
          } 
        } 
      } 
      // recalculate heights 
      resized.ownerCt.doLayout(); 
    } // of setElementSize 

  }); // of SplitAdapter 
} 

Ext.Container.LAYOUTS['ux.rowfit'] = Ext.ux.layout.RowFitLayout;