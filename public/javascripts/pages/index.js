var XlSuite = {
  valid_statuses: ['draft', 'published', 'reviewed', 'protected']
};

function onViewerChange(e) {
  var elem = e;
  var option = elem.options[elem.selectedIndex];
  var url = window.location.protocol;
  if(option.getAttribute("value") == null)
    return false;
  url += "//" + option.getAttribute("value");
  if (window.location.port) { url += ":" + window.location.port; }
  
  url += '/' + elem.up(1).previous(3).down(0).innerHTML.gsub('&nbsp;', '').strip();
  url = url.unescapeHTML();
  window.open(url, "_blank");
}
