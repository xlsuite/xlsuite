function updateRecipientHiddenField(textField, liElement) {
  var hiddenFieldId = (textField.id).replace(/^text_field_/i, "");
  $(hiddenFieldId).value = liElement.id;
}

function addRecipientToMlsImportLine(addRecipientLink, index) {
  var inputFieldsContainer = addRecipientLink.up('td').next('td');
  var hiddenFieldForNumOfRecipients = addRecipientLink.next('input');
  var numOfRecipients = parseInt(hiddenFieldForNumOfRecipients.value);
  numOfRecipients++;
  hiddenFieldForNumOfRecipients.value = numOfRecipients;
  var htmlCode = "<input type=\"text\" value=\"\" size=\"50\" name=\"text_field_recipient[" + index + "][" + numOfRecipients + "]\" id=\"text_field_recipient[" + index + "][" + numOfRecipients + "]\" class=\"inline text\" autocomplete=\"off\" />";
  htmlCode += "<img width=\"16\" height=\"16\" style=\"display: none;\" src=\"/images/throbber.gif\" id=\"text_field_recipient[" + index + "][" + numOfRecipients + "]_throbber\" class=\"throbber\" alt=\"AJAX request in progress\" />";
  htmlCode += "<div style=\"display: none;\" id=\"text_field_recipient[" + index + "][" + numOfRecipients + "]_auto_complete\" class=\"auto_complete\" ></div>";
  htmlCode += "<script type=\"text/javascript\">" +
      "//<![CDATA[\n" +
        "new Ajax.Autocompleter(" +
          "'text_field_recipient[" + index + "][" + numOfRecipients + "]'," + 
          "'text_field_recipient[" + index + "][" + numOfRecipients + "]_auto_complete'," + 
          "'/admin/parties;auto_complete'," + 
          "{" + 
            "method:'get', paramName:'q'," +
            "tokens:[',','\\n',' ']," +
            "indicator: 'text_field_recipient[" + index + "][" + numOfRecipients + "]_throbber'" +
        ", afterUpdateElement: updateRecipientHiddenField  })" +
      "//]]>\n" +
    "</script>";
  htmlCode += "<input type=\"hidden\" value=\"\" name=\"recipient[" + index + "][" + numOfRecipients + "]\" id=\"recipient[" + index + "][" + numOfRecipients + "]\" class=\"auto_complete_hidden_field\" autocomplete=\"off\" />";
  Insertion.Bottom(inputFieldsContainer, htmlCode);
}

function addNewMlsImportLine(mlsCode, addressCode) {
  var hiddenFieldNumOfMlsImportLines = $('num_of_mls_import_lines');
  var numOfMlsImportLines = parseInt(hiddenFieldNumOfMlsImportLines.value);
  numOfMlsImportLines++;
  hiddenFieldNumOfMlsImportLines.value = numOfMlsImportLines;
  var searchLineName = "searches[" + numOfMlsImportLines + "][line]";
  var htmlCode = 
    "<td class=\"mlsImportLabels\">" +
      "<label>MLS Number(s)</label><br/>" +
      "<label>Tag on Import</label><br/>" +
      "<label>Send Link to Recipient</label><br/>" +     
      "<a onclick=\"addRecipientToMlsImportLine(this, " + numOfMlsImportLines + "); return false;\" href=\"#\">Add Recipient</a>" +
      "<input type=\"hidden\" value=\"1\" name=\"num_of_recipients\" id=\"num_of_recipients\" autocomplete=\"off\"/>" +
    "</td>";
  htmlCode += 
    "<td>" +
      "<input type=\"hidden\" value=\"" + mlsCode+ "\" name=\"" + searchLineName + "[1][field]\" id=\"" + searchLineName + "[1][field]\" autocomplete=\"off\"/>" +
      "<input type=\"hidden\" value=\"eq\" name=\"" + searchLineName + "[1][operator]\" id=\"" + searchLineName + "[1][operator]\" autocomplete=\"off\"/>" +
      "<input type=\"hidden\" value=\"\" name=\"" + searchLineName + "[1][to]\" id=\"" + searchLineName + "[1][to]\" autocomplete=\"off\"/>" +
      "<input type=\"text\" value=\"\" size=\"30\" name=\"" + searchLineName + "[1][from]\" id=\"" + searchLineName + "[1][from]\" class=\"inline text\" autocomplete=\"off\"/><br/>" +

      "<input type=\"text\" value=\"\" size=\"50\" name=\"searches[" + numOfMlsImportLines + "][search][tag_list]\" id=\"searches[" + numOfMlsImportLines + "][search][tag_list]\" class=\"inline text\" autocomplete=\"off\"/><br/>" +
      
      "<input type=\"text\" value=\"\" size=\"50\" name=\"text_field_recipient[" + numOfMlsImportLines + "][1]\" id=\"text_field_recipient[" + numOfMlsImportLines + "][1]\" class=\"inline text\" autocomplete=\"off\"/>" +
      "<img width=\"16\" height=\"16\" style=\"display: none;\" src=\"/images/throbber.gif\" id=\"text_field_recipient[" + numOfMlsImportLines + "][1]_throbber\" class=\"throbber\" alt=\"AJAX request in progress\"/>" +
      "<div style=\"display: none;\" id=\"text_field_recipient[" + numOfMlsImportLines + "][1]_auto_complete\" class=\"auto_complete\">" + "</div>" +
      "<script type=\"text/javascript\">" +
"//<![CDATA[\n" +

        "new Ajax.Autocompleter(" +
          "'text_field_recipient[" + numOfMlsImportLines + "][1]',"  +
          "'text_field_recipient[" + numOfMlsImportLines + "][1]_auto_complete',"  +
          "'/admin/parties;auto_complete',"  +
          "{"  +
            "method:'get', paramName:'q'," +
            "tokens:[',','\\n',' ']," +
            "indicator: 'text_field_recipient[" + numOfMlsImportLines + "][1]_throbber'" +
        ", afterUpdateElement: updateRecipientHiddenField  })" +
"//]]>\n" +
"</script>" +
"<input type=\"hidden\" value=\"\" name=\"recipient[" + numOfMlsImportLines + "][1]\" id=\"recipient[" + numOfMlsImportLines + "][1]\" class=\"auto_complete_hidden_field\" autocomplete=\"off\"/>" +

    "</td>";
  Insertion.Bottom($('mls_import_table'), htmlCode);
}