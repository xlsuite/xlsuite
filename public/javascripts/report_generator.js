var numOfReportLines = 1;
var previouslySelectedReportModel = "Party";

var orderModes = ["none", "asc", "desc"];
var orderModeIcons = ["none.png", "shape_align_bottom.png", "shape_align_top.png"];

var reportLineTemplate = new Template("\
\
        <input autocomplete=\"off\" class=\"advancedSearch_text\" id=\"report_lines_#{index}_field\" name=\"report[lines][#{index}][field]\" value=\"\" type=\"text\">\
        <div class=\"auto_complete\" style=\"display: none;\" id=\"report_lines_#{index}_field_auto_complete\"></div> \
        <script type=\"text/javascript\"> \n" 
+ "//<![CDATA[ \n" +
"\
            new Ajax.Autocompleter(\"report_lines_#{index}_field\", \"report_lines_#{index}_field_auto_complete\", \"/admin/reports/field_auto_complete\", \
              { \
                paramName:\"q\", \
                method:\"get\", \
                callback: function(inputField, qString){ \
                  return (qString + \"&model=\"+$(\"report_model\").options[$(\"report_model\").selectedIndex].value) \
                } \
              }) \
" + "\n" +
"//]]>\n</script>" + 
"        <select class=\"searchOptions_select\" id=\"report_lines_#{index}_operator\" name=\"report[lines][#{index}][operator]\"><option value=\"ReportStartsWithLine\">Starts with</option> \
<option value=\"ReportEndsWithLine\">Ends with</option> \
<option value=\"ReportContainsLine\" selected=\"selected\">Contains</option> \
<option value=\"ReportEqualsLine\">Equals</option> \
<option value=\"ReportDisplayOnlyLine\">Display only</option></select> \
        <input autocomplete=\"off\" class=\"advancedSearch_text\" id=\"report_lines_#{index}_value\" name=\"report[lines][#{index}][value]\" value=\"\" type=\"text\"> \
        <span class=\"display\">\
          <input class=\"box\" id=\"report_lines_#{index}_display\" name=\"report[lines][#{index}][display]\" value=\"1\" checked=\"checked\" type=\"checkbox\"> \
        </span>\
        <span class=\"exclude\"> \
          <img alt=\"Exclude\" class=\"exclude_label\" src=\"/images/icons/exclude.png\"> \
          <input class=\"box\" id=\"report_lines_#{index}_excluded\" name=\"report[lines][#{index}][excluded]\" value=\"1\" type=\"checkbox\"> \
        </span>\
        <span class=\"sort\"> \
          <input autocomplete=\"off\" id=\"report_lines_#{index}_order\" name=\"report[lines][#{index}][order]\" value=\"none\" type=\"hidden\"> \
          <a href=\"#\" onclick=\"changeReportLineOrderMode(#{index}); return false;\"><img alt=\"None\" class=\"sortOrder\" id=\"report_lines_#{index}_order_icon\" src=\"/images/icons/none.png\"></a> \
        </span> \
");

function addNewReportLine() {
  numOfReportLines++;
  new Insertion.Bottom("report-line-fieldsets", reportLineTemplate.evaluate({index:numOfReportLines}));
}

function clearAllReportLines() {
  numOfReportLines = 0;
  $("report-line-fieldsets").innerHTML = "";
  addNewReportLine();
}

function reportModelChange() {
  var allBlank = true;
  var reportLine = null;
  for(i=1;i<=numOfReportLines;i++){
    reportLine = $("report_lines_" + i + "_field");
    if (reportLine.value != ""){
      allBlank = false;
      break;
    }
  } 
  
  if (!allBlank) {
    Ext.Msg.confirm("", "Changing selection model will clear all lines, are you sure?", function(btn){
      if ( btn.match(new RegExp("yes","i")) ) { 
        clearAllReportLines();
        var reportModelSelection = getReportModelSelection();
        previouslySelectedReportModel = reportModelSelection.options[reportModelSelection.selectedIndex].value;
      }
      else {
        revertReportModelSelection();
      }
    });
  }  
}

function revertReportModelSelection(){
  var reportModelSelection = getReportModelSelection();
  var selectedIndex = null;
  
  for(option in reportModelSelection.options) {  
    if(option.value == previouslySelectedReportModel) {
      selectedIndex = option.index;
    }
  };
  reportModelSelection.selectedIndex = selectedIndex;
}

function getReportModelSelection(){
  return $("report_model");
}

function changeReportLineOrderMode(index){
  var imageElement = $("report_lines_" + index + "_order_icon");
  var hiddenElement = $("report_lines_" + index + "_order");
  var newIndex = (orderModes.indexOf(hiddenElement.value) + 1)%3;
  hiddenElement.value = orderModes[newIndex];
  imageElement.src = "/images/icons/" + orderModeIcons[newIndex];
}
