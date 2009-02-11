Event.observe(window, "load", function() {
  var friendTemplate = new Template('<li id="friend_#{id}">#{name} &lt;#{email}&gt; <a onclick="$(\'friend_#{id}\').remove(); return false;" href="#">Remove</a><div style="display:none"><input type="hidden" name="referral[friends][][name]" value="#{name}"/><input type="hidden" name="referral[friends][][email]" value="#{email}"/></div></li>');
  var id = new Date().getTime();

  $("x_add_another_friend").observe("click", function(e) {
    var name = $F("friend_name"), email = $F("friend_email");
    if (email == null || email.toString() == "") {
      alert("Can't send to a blank E-Mail address");
    }

    var ul = $("friends");
    if (ul.getElementsBySelector("li").size >= 10) {
      alert("Can't send to more than 10 friends at a time");
    }

    id += 1;
    new Insertion.Bottom(ul, friendTemplate.evaluate({'name': name, 'email': email, 'id': id}));
    $("friend_name").value = "";
    $("friend_email").value = "";
    $("friend_name").focus();

    Event.stop(e);
  });
});
