function updateTagsField(element, tagName) {
  var value = $(element).value;
  var re = new RegExp('(^|[ ,])' + tagName + '(?=[ ,]|$)'); 
  if (null == value.match(re)) {
    value += ' ' + tagName;
  } else {
    value = value.gsub(re, RegExp.$1);
  }

  $(element).value = value.gsub(/\s+/, ' ').sub(/^\s+/, '').sub(/\s+$/, '');
}
