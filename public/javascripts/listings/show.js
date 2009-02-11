var swfu, swfuOptions;
swfuOptions = {
	upload_script : "-- assigned later",
	target : "-- assigned later",
	flash_path : "/javascripts/swfupload/SWFUpload.swf",
  allowed_filesize : 10*1024*1024,	// 10 MB
  allowed_filetypes : "*.jpg;*.png;*.gif;*.JPG;*.PNG;*.GIF",
  allowed_filetypes_description : "Common Internet pictures (jpg, gif, png)...",
  browse_link_innerhtml : "Browse&hellip;",
  upload_link_innerhtml : "Upload",
  browse_link_class : "swfuploadbtn browsebtn",
  upload_link_class : "swfuploadbtn uploadbtn",
  flash_loaded_callback : 'swfu.flashLoaded',
  upload_file_queued_callback : "fileQueued",
  upload_file_start_callback : 'uploadFileStart',
  upload_progress_callback : 'uploadProgress',
  upload_file_complete_callback : 'uploadFileComplete',
  upload_file_cancel_callback : 'uploadFileCancelled',
  upload_queue_complete_callback : 'uploadQueueComplete',
  upload_error_callback : 'uploadError',
  upload_cancel_callback : 'uploadCancel',
  auto_upload : true,
  debug : true,
  create_ui : true		
};

function fileElementId(file) {
  return "x_file_" + file.id;
}

function fileQueued(file) {
  var uploadQueue = $("x_upload_queue");
  var elem = uploadQueue.down(".complete");
  if (elem) elem.remove();

  var fileId = fileElementId(file);
  uploadQueue.insert("<li id='" + fileId + "'>" + file.name + " (" + bytesToHumanSize(file.size) + ")<a href='#' class='cancel' title='Cancel'><img src='/images/icons/cancel.png' alt='Cancel'/></a><span class='pctwrap'><span class='percent'>100%</span><span class='pbar'>&nbsp;</span></span></li>");
  var cancelLink = uploadQueue.down("#" + fileId + " a.cancel");
  Event.observe(cancelLink, "click", function(e) {swfu.cancelFile(file.id); Event.stop(e);});
}

function uploadFileStart(file, position, queueLength) {
  var fileId = fileElementId(file);
  var elem = $(fileId);
  elem.addClassName("active");
  var pbar = elem.down(".pbar");
  var pct = elem.down(".percent");
  pct.innerHTML = "0%"
}

function uploadProgress(file, bytesCompleted, bytesTotal) {
  setPercentValue(file, ((bytesCompleted / bytesTotal) * 100.0).round());
}

function uploadFileComplete(file) {
  setPercentValue(file, 100);
  (function() {
    new Effect.SlideUp(elem, {duration: 0.33});
  }).delay(1.0);
}

function setPercentComplete(file, percent) {
  var fileId = fileElementId(file);
  var elem = $(fileId);
  var pbar = elem.down(".pbar");
  var pct = elem.down(".percent");
  pbar.style.backgroundPosition = "-" + (200 - 2*percent) + "px"; 
  pct.innerHTML = percent.toString() + "%"
}

function uploadFileError(errcode, file, msg) {
  var elem = $(fileElementId(file));
  var pctwrap = elem.down(".pctwrap");
  pctwrap.innerHTML = "Error <strong>" + errcode + "</strong>: " + msg;
  new Effect.Highlight(pctwrap);
}

function uploadFileCancelled(file, queueLength) {
  var fileId = fileElementId(file);
  new Effect.SlideUp(fileId, {duration: 0.33, afterFinish: function() {$(fileId).remove();}});
}

function uploadQueueComplete() {
  var uploadQueue = $("x_upload_queue");
  uploadQueue.insert("<li class='complete'>All files uploaded</li>");
  var elem = uploadQueue.down(".complete");
  new Effect.SlideDown(elem, {queue: {scope: 'complete', position: 'end'}});
  new Effect.Highlight(elem, {queue: {scope: 'complete', position: 'end'}});
  new Effect.BlindUp(elem, {queue: {scope: 'complete', position: 'end'}, afterFinish: function() {elem.remove()}});
}

function uploadError() {
  var fileId = fileElementId(file);
  alert("Upload error: " + arguments.inspect());
}

function bytesToHumanSize(bytes) {
  if (bytes == 1) {
    return "1 Byte";
  } else if (bytes < 1024) {
    return bytes.toString() + " Bytes";
  } else if (bytes < 1024*1024) {
    return ((((bytes / 1024.0) * 100.0).round()) / 100).toString() + " KB";
  } else if (bytes < 1024*1024*1024) {
    return ((((bytes / (1024.0*1024.0)) * 100.0).round()) / 100).toString() + " MB";
  } else if (bytes < 1024*1024*1024*1024) {
    return ((((bytes / (1024.0*1024.0*1024.0)) * 100.0).round()) / 100).toString() + " GB";
  } else {
    return ((((bytes / (1024.0*1024.0*1024.0*1024.0)) * 100.0).round()) / 100).toString() + " TB";
  }
}
