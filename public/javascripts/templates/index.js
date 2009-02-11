function executeSelectedAction(element) {
  var selectedOptionValue = element.options[element.selectedIndex].value;
  if (selectedOptionValue == "delete") {
    $('templateIndexForm').action = "/admin/templates;destroy_all";
    $('templateIndexForm').submit();
  }
  else {
    $('templateIndexForm').action = "";
  }
}

function processCheckBoxClick(element) {
  if (element.checked) {
    increaseCheckedCounter();
  }
  else {
    decreaseCheckedCounter();
  }
  updateSelectionMenu();
}

function increaseCheckedCounter() {
  var count = parseInt($("num_of_checked_items").value);
  count++;
  $("num_of_checked_items").value = count;
}

function decreaseCheckedCounter() {
  var count = parseInt($("num_of_checked_items").value);
  if (count > 0) { count--; }
  $("num_of_checked_items").value = count;
}

function updateSelectionMenu() {
  var count = getNumOfCheckedItems();
  if (count > 0) {
    $('selectionMenu_deleteOption').disabled = false;
  }
  else {
    $('selectionMenu_deleteOption').disabled = true;
  }
}

function getNumOfCheckedItems() {
  var count = parseInt($("num_of_checked_items").value);
  return count;
}