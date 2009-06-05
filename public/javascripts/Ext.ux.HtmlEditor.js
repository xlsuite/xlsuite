Ext.namespace('Ext.ux'); 

Ext.ux.HtmlEditor = function(config){
  
    if (config) {
        Ext.apply(this, config);
        if (config.listeners) Ext.apply(this,{listeners: config.listeners});
        if (config.value) Ext.apply(this, {value: config.value});
    }
    Ext.ux.HtmlEditor.superclass.constructor.call(this);
};

Ext.extend(Ext.ux.HtmlEditor, Ext.form.HtmlEditor, {
      // private used internally
    createLink : function(){
        var url = prompt(this.createLinkText, this.defaultLinkValue);
        if(url && url != 'http:/'+'/'){
            this.relayCmd('createlink', url.trim());
        }
    },
    
    syncValue : function(){
        if(this.initialized){
            var bd = this.getEditorBody();
            var html = bd.innerHTML;
            if(Ext.isSafari){
                var bs = bd.getAttribute('style'); // Safari puts text-align styles on the body element!
                var m = bs.match(/text-align:(.*?);/i);
                if(m && m[1]){
                    html = '<div style="'+m[0]+'">' + html + '</div>';
                }
            }
            html = this.cleanHtml(html);
            html = html.replace(/<br>/g, "<br />");
            html = html.trim()
            if(this.fireEvent('beforesync', this, html) !== false){
              var regHex = /(7B)|(7D)/i;
    		      var out = new Array(); 
    		      var inTag = false;
    		      var inLiquid = false;
    		      var gtLtAmpToken = "";
    		      for (var i = 0, len = html.length; i < len; ++i) {
    			      var token = html.charAt(i);
    			      if (inTag && i + 2 < len && token == '%' && regHex.test(html.substr(i+1, 2))) {
    				      out.push(unescape('%' + html.charAt(i + 1) + html.charAt(i + 2)));
    				      i += 2;
    				      continue;
    			      }
    			      else if (inLiquid && token == '&' && i+3 < len){
    			        gtLtAmpToken = token + html.charAt(i+1) + html.charAt(i+2) + html.charAt(i+3);
    			        if (gtLtAmpToken == "&lt;"){
    			          out.push("<");
    			          i += 3;
    			          continue;
    			        }
    			        else if (gtLtAmpToken == "&gt;") {
    			          out.push(">");
    			          i += 3;
    			          continue;
    			        }
    			        else{
    			          if (i+4<len){
    			            gtLtAmpToken += html.charAt(i+4);
    			            if(gtLtAmpToken == "&amp;"){
    			              out.push("&");
    			              i += 4;
    			              continue;
    			            }
    			          }
    			        } 
    			      }
    			      else if (token == '{'){
    			        if ((i+2<len) && html.charAt(i+1) == "%"){
    			          inLiquid = true;
    			        }
    			      }
    			      else if (token == '}'){
    			        if (html.charAt(i-1) == "%"){
    			          inLiquid = false;
    			        }
    			      }
    			      else if (token == '<') {
    				      inTag = true;
    			      }
    			      else if (token == '>') {
    				      inTag = false;
    			      }
    			      out.push(token);
    		      }
		          this.el.dom.value = out.join('');
            }
        }
    }
});