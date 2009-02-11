function findPartyId(formElement) {
  return formElement.up("form").id.split("_").last();
}

function extractObjectIds(elements) {
  return elements.map(function(e) {
    return e.id.split("_").last();
  }).join(',');
}

function initializeSecurityFields() {

  $$("#groups input.group[type=checkbox]").each(function(el) {
    el.observe("change", function(e) {
      var element = Event.element(e);
      var party_id = findPartyId(element);

      massUpdate(element.checked, [element], "/admin/memberships",
          "group_ids", "groups_indicator");
    });
  });

  $$("#permissions input[type=checkbox]").each(function(el) {
    el.observe("change", function(e) {
      var element = Event.element(e);
      var party_id = findPartyId(element);

      massUpdate(element.checked, [element], "/admin/roles",
          "permission_ids", "permissions_indicator");
    });
  });

  $$("#groups input.denial[type=checkbox]").each(function(el) {
    el.observe("change", function(e) {
      var element = Event.element(e);
      var party_id = findPartyId(element);

      massUpdate(!element.checked, [element], "/admin/denied_permissions",
          "permission_ids", "groups_indicator");
    });
  });

  $$("#groups a.toggle.open").each(function(e) {
    e.show();
    Event.observe(e, "click", toggleGroupPermissions.bindAsEventListener(e));
  });

  $$("#groups a.toggle.close").each(function(e) {
    Event.observe(e, "click", toggleGroupPermissions.bindAsEventListener(e));
  });
}

function toggleGroupPermissions(e) {
  var parts = this.id.split("_");
  var permissions_id = parts.slice(0, -2).join("_") + "_permissions";
  var open_id = permissions_id + "_open";
  var close_id = permissions_id + "_close";
  var elements = [open_id, close_id, permissions_id];

  elements.each(Element.toggle);
  Event.stop(e);
  return false;
}

function togglePermissionDenials(element) {
  var root = $("group_" + element.id.split("_").last() + "_permissions");
  if (!root) return

  var elements = root.getElementsBySelector("input.denial[type=checkbox]");
  elements.each(function(e) {
    e.checked = e.disabled;
    e.disabled = !e.disabled;
  });
}

function massUpdate(newValue, elements, url, paramName, indicator) {
  if (elements.length == 0) return;

  var params = {};
  params['party_id'] = findPartyId(elements.first());
  params[paramName] = extractObjectIds(elements);

  elements.each(togglePermissionDenials);

  indicator = $(indicator);
  indicator.show()
  new Ajax.Request(url, {
      method: newValue ? "post" : "delete",
      evalScripts: true,
      onComplete: function() {indicator.hide()},
      parameters: params
  });
}

function massPermissionsUpdate(newValue, elements) {
  return massUpdate(newValue, elements, "/admin/roles",
      "permission_ids", $("permissions_indicator"));
}

function massGroupsUpdate(newValue, elements) {
  return massUpdate(newValue, elements, "/admin/memberships",
      "group_ids", $("groups_indicator"));
}
