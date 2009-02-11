function addDownloadLink() {
  var numOfDownloadLinks = parseInt($("num_of_download_links").value);
  numOfDownloadLinks++;
  $("num_of_download_links").value = numOfDownloadLinks;
  new Insertion.Bottom("collection_of_download_links", 
    // TODO: redo the stuff below later when email template is finalized 
    "<p><input type=\"text\" value=\"\" name=\"download_links[" + numOfDownloadLinks + "]\" id=\"download_links[" + numOfDownloadLinks + "]\" autocomplete=\"off\"/>&nbsp;<a onclick=\"; return false;\" href=\"#\">Browse</a></p>");
}

function showEmailBccs() {
  $("email_bccs_link").hide();
  $('email_bccs_wrapper').show();
}

function hideEmailBccs() {
  $('email_bccs_wrapper').hide();
  $("email_bccs_link").show();
}

function showEmailCcs() {
  $("email_ccs_link").hide();
  $('email_ccs_wrapper').show();
}

function hideEmailCcs() {
  $('email_ccs_wrapper').hide();
  $("email_ccs_link").show();
}

function removeAttachment(id) {
  var rowElement = $(id).up("li");
  if (rowElement) { 
    var fileElement = $(rowElement.id.sub("_row", ""));
    if (fileElement) fileElement.remove();
    new Effect.Fade(rowElement, {afterFinish: function() {rowElement.remove()}});
  }
}

function destroyAttachment(element, url) {
  new Ajax.Request(url, {
      method: 'delete',
      onLoading: function() {
        new Effect.Fade(element);
      },
      onFailure: function(xhr) {
        new Effect.Appear(element);
        alert("Could not destroy " + element + ". Server said '" + xhr.status + " " + xhr.statusText + "'");
      }
    }
  );
}

var attachmentsMultiSelector = null;
Event.observe(window, "load", function() {
  attachmentsMultiSelector = new MultiSelector($("x_attachments"), {
    templateText: '<li id="#{id}">#{title} <a href="javascript:void(0)" onclick="removeAttachment(this)" class="rm_att">Remove</a></li>',
    id: function(id) {return "attachments_" + id},
    name: "attachments[][uploaded_data]"
});
  attachmentsMultiSelector.addElement($("attachment_file"));

  $$("#x_attachments a.remove").each(function(anchor) {
    anchor.observe("click", function(e) {
      Event.stop(e);
      var root = anchor.up("li");
      new Ajax.Request(anchor.getAttribute("href"), {
        method: 'delete',
        onLoading: function() {new Effect.Fade(root)},
        onFailure: function(xhr) {
          new Effect.Appear(root);
          alert("Failed to remove attachment.  Server replied '" + xhr.status + " " + xhr.statusText + "'");
        }
      });
    });
  });

  $$("a.submit").each(function(anchor) {
    anchor.observe("click", function(e) {
      Event.stop(e);
      if (anchor.hasClassName("send")) {
        if (($F("email_tos") + $F("email_ccs") + $F("email_bccs")).strip() == "") {
          alert("Cannot send this mail to no recipients.  Add at least one recipient.");
          $("email_tos").focus();
          return false;
        }

        if ($F("email_subject").strip() == "" && !confirm("Send this mail without a subject ?")) {
          $("email_subject").focus();
          return false;
        }
      }

      $("commit").value = Event.element(e).innerHTML.toLowerCase();
      Event.element(e).up("form").submit();
    });
  });
});
