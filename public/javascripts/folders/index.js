function executeSelectedAction(element) {
  var selectedOptionValue = element.options[element.selectedIndex].value;
  $('sort').value = selectedOptionValue;
  $('hiddenForm').submit();
}

//function expandFolder(folder_id, select) {
//  var ahrefIdName = "togglelink_folder" + folder_id;
//  var folderId = "folder" + folder_id;
//  var folderImageIdName = "folderimage" + folder_id;
//  
//  if ($(folderId) && !$(folderId).visible())
//  {
//    $(folderId).toggle();
//    if ($(ahrefIdName))
//      $(ahrefIdName).update("<img src = '/images/icons/bullet_toggle_minus.png' border='0'>");
//  }
//  if (select)
//  {
//    $(folderImageIdName).src = '/images/icons/folder_selected.png';
//  }
//}

function executeViewBySelection(element) {
  var selectedOptionValue = element.options[element.selectedIndex].value;
  $('view').value = (selectedOptionValue == "thumbs")? "thumbs" : "list";
  $('hiddenForm').submit();
}

function multiFolder(element, id){
  if ($('selectMultiple').checked)
  {
    if($('ids').value=="" || $('ids').value==id )
    {
      $('ids').value = id;
    }
    else
    {
      var indexOfId = $('ids').value.search( new RegExp('(\\D|^'+id+"(\\D,*))|(\\D"+id+"$)") );
      if (indexOfId == 0) {
        regex = new RegExp('(' + id + "(\\D,*))|(" + id + "$)")
      }
      else 
        regex = new RegExp(","   + id);
      $('ids').value = $('ids').value.replace( regex, "");     
      if (indexOfId == -1)
      {
        if ($('ids').value != "")
          $('ids').value = $('ids').value.concat(",");
        $('ids').value = $('ids').value.concat(id);
      }
    }
  }
  else if(!$('selectMultiple').checked)
  {
    $('ids').value = id;
  }
  else
    alert("error");
  unselectAllFolders();
  $('ids').value.split(',').each(function(s){
    expandFolder(s.gsub(" ", ""), true);
  });
  
  xl.runningGrids.each(function(pair){
    var grid = pair.value;
    var dataStore = grid.getStore();
    if (dataStore.proxy.conn.url.match(new RegExp('folders', "i"))) {
      dataStore.proxy.conn.url = "/admin/folders.json?ids="+$('ids').value;
      dataStore.reload();
    }
  });
}

function unselectAllFolders()
{
  $$('img.directory_menu_folder_image').each(function(el){
    el.src = '/images/icons/folder.png';
  });
}

function toggleEditFileView(id)
{
  viewElementId = "ajaxViewFile"+id;
  if( $(viewElementId))
  {
    $(viewElementId).toggle();
  }
  else
  {
    new Ajax.Request('assets/'+id+';display_edit', {asynchronous:true, evalScripts:true, method:'get'});
  }
}

function generateNewFileWindow(id)
{
  var windowContent = "<div id = insert_new_file_form></div>"
  var windowElement = new Window("new_file_window", 
        {
          className: "alphacube",
          title: "New File",
          destroyOnClose: true,
          minimizable: false, maximizable: false, closable: false, 
          
          width: 600, height: 400,
        });
      
  windowElement.setHTMLContent(windowContent);
  windowElement.showCenter();
  
  new Ajax.Request('assets/'+id+';display_new_file_window', {asynchronous:true, evalScripts:true, method:'get'});
}


function generateNewFolderWindow(id)
{
  var windowContent = "<div id = insert_new_folder_form></div>"
  var windowElement = new Window("new_folder_window", 
        {
          className: "alphacube",
          title: "New Folder",
          destroyOnClose: true,
          minimizable: false, maximizable: false, closable: false, resizable: false,
          
          width: 560, height: 420,
        });
      
  windowElement.setHTMLContent(windowContent);
  windowElement.showCenter();
  
  new Ajax.Request('/admin/folders/'+id+';display_new_folder_window', {asynchronous:true, evalScripts:true, method:'get'});
}

function generateEditFolderWindow(id)
{
  var windowContent = "<div id = insert_edit_folder_form></div>"
  var windowElement = new Window("edit_folder_window", 
        {
          className: "alphacube",
          title: "Edit Folder",
          destroyOnClose: true,
          minimizable: false, maximizable: false, closable: false, resizable: false,
          
          width: 560, height: 420,
        });
      
  windowElement.setHTMLContent(windowContent);
  windowElement.showCenter();
  
  new Ajax.Request('/admin/folders/'+id+';edit', {asynchronous:true, evalScripts:true, method:'get'});
}

AjaxPermissionCheckbox = Class.create();

AjaxPermissionCheckbox.prototype = {
  initialize: function(asset_id) {

    this.assetId = asset_id;
    this.readerList = $('asset_'+this.assetId+'_readers');
    this.writerList = $('asset_'+this.assetId+'_writers');
    this.readerCheckBoxes = this.readerList.getElementsByTagName('input');
    this.writerCheckBoxes = this.writerList.getElementsByTagName('input');
    for (var i = 0; i < this.readerCheckBoxes.length; i++) {
      Event.observe(this.readerCheckBoxes[i], "click", this.registerReaderClickHandler.bindAsEventListener(this, this.readerCheckBoxes[i]));
      Event.observe(this.writerCheckBoxes[i], "click", this.registerWriterClickHandler.bindAsEventListener(this, this.writerCheckBoxes[i]));
    }
  },
  
  registerReaderClickHandler: function(event, checkbox){
    $('reader_update_throbber'+this.assetId).toggle();
    new Ajax.Request('assets/'+this.assetId+';update_permissions?reader_id='+checkbox.value, {asynchronous:true, evalScripts:true, method:'get'})
  },
  registerWriterClickHandler: function(event, checkbox){
    $('writer_update_throbber'+this.assetId).toggle();
    new Ajax.Request('assets/'+this.assetId+';update_permissions?writer_id='+checkbox.value, {asynchronous:true, evalScripts:true, method:'get'})
  }
}