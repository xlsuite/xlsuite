xl.GoogleMap = Class.create({
  initialize: function(id) {
    this._el = $(id);
    if (!this._el) return;

    this.options                  = arguments[1] || {};
    this.initialLatitude          = this.options.initialLatitude || 49.28039;
    this.initialLongitude         = this.options.initialLongitude || -123.103309;
    this.initialZoomLevel         = this.options.initialZoomLevel || 5;
    this.lineColor                = this.options.lineColor || '#00ff00';
    this.lineOpacity              = this.options.lineOpacity || 1.0;
    this.lineWidth                = this.options.lineWidth || 2;
    this.colorHighlightedSquare   = this.options.colorHighlightedSquare || '#aaaaff';
    this.opacityHighlightedSquare = this.options.opacityHighlightedSquare || 0.4;
    this.colorLine                = this.options.colorLine || '#757575';
    this.opacityLine              = this.options.opacityLine || 1;

    this._gmap = new GMap2(this._el);
    this._gmap.setCenter(new GLatLng(this.initialLatitude, this.initialLongitude), this.initialZoomLevel);
    this._gmap.addControl(new GSmallMapControl());
    this._gmap.addControl(new GMapTypeControl());

    this._clearRegionListeners = new Array();
    this.clearRegion();
  },

  appendMarker: function(point) {
    var marker = new GMarker(point, {draggable: true});
    var obj = this;
    GEvent.addListener(marker, "dragend", function(){
      if (obj._markers.length > 2) {
        obj.createRegion();
      }
    });
    
    this._markers.push(marker);
    this._gmap.addOverlay(marker);

    if (this._markers.length > 2) {
      this.createRegion();
    }
    return marker;
  },

  createRegion: function() {
    if (this._polyline) this._gmap.removeOverlay(this._polyline);
    if (this._polygon)  this._gmap.removeOverlay(this._polygon);

    if (this._markers.length < 3){
      alert("At least 3 points are required on the map to delimit an area.  Add at least " + (3 - this._markers.length).toString() + " more point(s) to delimit an area.");
      return;
    }

    var points = this.markersToPoints();
    points.push(this._markers[0].getLatLng());

    this._polyline = new GPolyline(points, this.lineColor, this.lineWidth, this.opacityLine);
    this._gmap.addOverlay(this._polyline);

    this._polygon = new GPolygon(points, this.colorLine, this.lineWidth, this.opacityLine, this.colorHighlightedSquare, this.opacityHighlightedSquare);
    this._gmap.addOverlay(this._polygon);
  },

  clearRegion: function() {
    this._gmap.clearOverlays();
    this._markers  = new Array();
    this._polyline = null;
    this._polygon  = null;
    this._clearRegionListeners.each(function(handler) { handler();});
  },

  markersToPoints: function() {
    var points = new Array();
    if (this._markers) {
      for (var k=0; k < this._markers.length; k++) {
        points.push(this._markers[k].getLatLng());
      }
    }

    return points;
  },
  
  pointsToMarkers: function(points){
    for (var k=0; k < points.length; k++) {
      this.appendMarker(new GLatLng(points[k].first(), points[k].last()));
    }   
  },

  on: function(eventName, handler) {
    if (eventName == "clearRegion") {
      this._clearRegionListeners.push(handler);
    } else {
      GEvent.addListener(this._gmap, eventName, handler);
    }
  }
});
