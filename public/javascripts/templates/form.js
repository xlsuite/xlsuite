function insertToTemplateTargetField(text) {
  target = $($('template_target_field').value)
  target.value = target.value.substring(0, target.selectionStart) + text + target.value.substring(target.selectionEnd);
}

function changeTemplateTargetField(element) {
  $('template_target_field').value = element.id
}