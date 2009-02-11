function addInputSection(wrapper_id){
  var num = parseInt($("num_of_optional_inputs").value) + 1;
  $("num_of_optional_inputs").value = num+'';
  var content = '<tr id="optional_input'+num+'" class="optional_input">\n'
  + '<td><input id="info[title]['+num+']" class="text" type="text" value="New Section" name="info[title]['+num+']" autocomplete="off"/></td>\n'
  + '<td><textarea id="info_body_'+num+'" class="text countdown" rows="8" name="info[body]['+num+']" cols="45" /></textarea>\n'
  + '<p>200 Character Limit. Remaining: <span class="remaining_counter" id="info_body_'+num+'_remaining">200</span></p></td>\n'
  + '</div></tr>';
  new Insertion.Before(wrapper_id, content);
  $$("input.countdown", "textarea.countdown").each(function(element) {
    element.observe("keyup", function() {
      var countElement = $(element.id + "_remaining");
      var remaining = 200 - $F(element).length;

      if (remaining < 0) {
        countElement.innerHTML = "Too many characters";
        countElement.addClassName("toomany");
      } else if (remaining == 0) {
        countElement.innerHTML = "0";
        countElement.removeClassName("toomany");
      } else {
        countElement.innerHTML = remaining.toString();
        countElement.removeClassName("toomany");
      }
    });
  });
}


function addFeedSection(wrapper_id){
  var num = parseInt($("num_of_feeds").value);
  $("num_of_feeds").value = num+1;
  var content = '<div id="optional_feed'+num+'">\n'
  + '<p><label>Title:</label><input id="feed['+num+'][label]" class="text" type="text" size="20" name="feed['+num+'][label]" autocomplete="off"/>\n'
  + '</p><div id="feed['+num+'][messages]" class="auto_complete validation" style="display: none;"></div>'
  + '<script type="text/javascript">new Ajax.Validator("feed['+num+'][label]","feed['+num+'][messages]","/admin/profiles/validate_feed",'
  + '{method:\'get\', paramName: \'label\', frequency: 0.2, minChars: 1});</script>'
  + '<p><label>Feed URL:</label><input id="feed['+num+'][url]" class="text" type="text" size="40" name="feed['+num+'][url]" autocomplete="off"/>\n'
  + '</p></div>';
  new Insertion.Bottom(wrapper_id, content);
}

function addLinkSection(wrapper_id){
  var num = parseInt($("num_of_links").value);
  $("num_of_links").value = num+1;
  var content = '<tr><td><input class="text" size="15" value="name" type="text" name="profile[link]['+num+'][name]"/></td>'
  + '<td><input class="text" size="30" value="url" type="text" name="profile[link]['+num+'][url]"/></td></tr>';
  new Insertion.Before(wrapper_id, content);
}

Event.observe(window, "load", function() {
  $$("input.countdown", "textarea.countdown").each(function(element) {
    element.observe("keyup", function() {
      var countElement = $(element.id + "_remaining");
      var remaining = 200 - $F(element).length;

      if (remaining < 0) {
        countElement.innerHTML = "Too many characters";
        countElement.addClassName("toomany");
      } else if (remaining == 0) {
        countElement.innerHTML = "0";
        countElement.removeClassName("toomany");
      } else {
        countElement.innerHTML = remaining.toString();
        countElement.removeClassName("toomany");
      }
    });
  });
});
