// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; version 2 of the License.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

var theCircleSynth = null;

var realMouseUpFunction = null;

var movementX = null;
var movementY = null;
var isDown = false;

function getAngleFromCircleCenter (inX, inY) {
  newAngle = null;
  if (theCircleSynth.y == inY) {
    if (theCircleSynth.x > inX) {
      newAngle = Math.PI;
    } else {
      newAngle = 0;
    }
  } else if (theCircleSynth.x == inX) {
    if (theCircleSynth.y > inY) {
      newAngle = Math.PI * 3.0 / 2;
    } else {
      newAngle = Math.PI / 2;
    }
  }

  if (newAngle == null) {
    newAngle = Math.atan((theCircleSynth.y - inY) / (theCircleSynth.x - inX));
    debug("angle is" + newAngle);
    if (theCircleSynth.x > inX) {
      debug("adding pi");
      newAngle += Math.PI;
    } else if (theCircleSynth.y > inY) {
      debug("adding 2 * pi");
      newAngle += 2 * Math.PI;
    }
  } else {
    debug("angle is" + newAngle);
  }
  return newAngle;
}

function getDistanceBetweenCircleAngles(inAngle1, inAngle2) {
  return theCircleSynth.radius * (inAngle1 - inAngle2);
}

function getRandomId() {
  return "" + Math.floor((Math.random() * 0xFFFFFFFF));
}

function getColorFromType(type) {
  return {"HissMaker":"yellow",
      "BuzzMaker":"purple",
      "BeepMaker":"orange",
      "TweetMaker":"pink"}[type];
}

function getRandomMarkerType() {
  types = ["HissMaker", "BuzzMaker", "BeepMaker", "TweetMaker"];
  return types[Math.floor(Math.random() * types.length)]
}

function getMarkerTypeFromPositions(inX1, inY1, inX2, inY2) {
  if (inX1 > inX2) {
    if (inY1 > inY2) {
      return "BuzzMaker";
    } else {
      return "HissMaker";
    }
  } else {
    if (inY1 > inY2) {
      return "BeepMaker";
    } else {
      return "TweetMaker";
    }
  }
  return getRandomMarkerType();
}

function debug(str) {
  if (navigator.appVersion.search("Safari") >= 0) {
    console.log(str);
  } else {
  }
}

function AngleMarker (circle, id, angle, type) {
  this.circle = circle;
  this.id = id;
  this.angle = angle;
  this.type = type;

  this.notifyOfConstruction = function() {
    data = $.toJSON({"address":"/circlesequencer/marker/create", "data":[this.circle.id, this.id, this.angle, this.type], "types":"ssfs"});
    debug("create data = " + data);
    $.ajax({
      url: '/command',
	  type: 'POST',
	  dataType: 'json',
	  data: data,
	  timeout: 1000,
	  error: function(){
	  // TODO: error message?
	},
	  success: function(json){
	  // Who cares? This was one-way.
	}
      });
  }

  this.notifyOfChange = function() {
    data = $.toJSON({"address":"/circlesequencer/marker/update", "data":[this.circle.id, this.id, this.angle], "types":"ssf"});
    debug("create data = " + data);
    $.ajax({
      url: '/command',
	  type: 'POST',
	  dataType: 'json',
	  data: data,
	  timeout: 1000,
	  error: function(){
	  // TODO: error message?
	},
	  success: function(json){
	  // Who cares? This was one-way.
	}
      });
  }

  this.setAngle = function(angle) {
    this.angle = angle;
    this.notifyOfChange();
  }

  this.notifyOfConstruction();
}

function CircleSynth (id, x, y, radius) {
  this.id = id;
  this.x = x;
  this.y = y;
  this.radius = radius;

  this.markers = new Array();

  this.notifyOfConstruction = function() {
    data = $.toJSON({"address":"/circlesequencer/circle/create", "data":[this.id, this.radius, this.x, this.y], "types":"sfff"});
    debug("create data = " + data);
    $.ajax({
      url: '/command',
	  type: 'POST',
	  dataType: 'json',
	  data: data,
	  timeout: 1000,
	  error: function(){
	  // TODO: error message?
	},
	  success: function(json){
	  // Who cares? This was one-way.
	}
      });
  }

  this.notifyOfChange = function() {
    data = $.toJSON({"address":"/circlesequencer/circle/update", "data":[this.id, this.radius, this.x, this.y], "types":"sfff"});
    debug("change data = " + data);
    $.ajax({
      url: '/command',
	  type: 'POST',
	  dataType: 'json',
	  data: data,
	  timeout: 1000,
	  error: function(){
	  // TODO: error message?
	},
	  success: function(json){
	  // Who cares? This was one-way.
	}
      });
  }

  this.addMarker = function(markerId, angle, type) {
    this.markers.push(new AngleMarker(this, markerId, angle, type));
  }

  this.getMarkerById = function(markerId) {
    for (var i = 0; i < this.markers.length; i++) {
      if (this.markers[i].id == markerId) {
	return this.markers[i];
      }
    }
    return null;
  }

  this.setRadius = function(inRadius) {
    this.radius = inRadius;  
    this.notifyOfChange();
  }
  this.setX = function (inX) {
    this.x = inX;
    this.notifyOfChange();
  }
  this.setY = function (inY) {
    this.y = inY;
    this.notifyOfChange();
  }
  this.setXY = function (inX, inY) {
    this.x = inX;
    this.y = inY;
    this.notifyOfChange();
  }

  this.notifyOfConstruction();
}

var gesturing = false;

function init() {
  if (navigator.appVersion.search("iPhone") >= 0) {
    debug("adding iphone handlers");
    document.getElementById("sweeper").addEventListener('touchstart', touchDownHandler, true);
    document.getElementById("sweeper").addEventListener('touchmove', touchMoveHandler, true);
    document.getElementById("sweeper").addEventListener('touchend', touchUpHandler, true);
    document.getElementById("sweeper").addEventListener('touchcancel', function(evt) {isDown = false;}, true);
    document.getElementById("sweeper").addEventListener('gesturestart', function (evt) {gesturing = true;}, true);
    document.getElementById("sweeper").addEventListener('gestureend', function (evt) {gesturing = false;}, true);
  } else {
    debug("adding non-iphone handlers");
    document.getElementById("sweeper").addEventListener('mousedown', mouseDownHandler, true);
    document.getElementById("sweeper").addEventListener('mouseup', mouseUpHandler, true);
    document.getElementById("sweeper").addEventListener('mousemove', mouseMoveHandler, true);
  }
  document.getElementById("sweeper").upHandler = upHandler;
  document.getElementById("sweeper").downHandler = downHandler;
  document.getElementById("sweeper").moveHandler = moveHandler;

  draw();
}

function findDistance(aX, aY, bX, bY) {
  return Math.sqrt((aX - bX) * (aX - bX) + (aY - bY) * (aY - bY));
}

function touchUpHandler(evt) {
  debug("touchup");
  this.upHandler(evt.changedTouches[0].clientX, evt.changedTouches[0].clientY);
  // evt.preventDefault();
  // evt.stopPropagation();
}

function touchDownHandler(evt) {
  debug("touchdown");
  this.downHandler(evt.changedTouches[0].clientX, evt.changedTouches[0].clientY);
  evt.preventDefault();
  // evt.stopPropagation();
}

function touchMoveHandler(evt) {
  debug("touchmove");
  this.moveHandler(evt.changedTouches[0].clientX, evt.changedTouches[0].clientY);
  evt.preventDefault();
  evt.stopPropagation();
}

function mouseUpHandler(evt) {
  this.upHandler(evt.pageX, evt.pageY);
  evt.preventDefault();
}

function mouseDownHandler(evt) {
  this.downHandler(evt.pageX, evt.pageY);
  evt.preventDefault();
}

function mouseMoveHandler(evt) {
  this.moveHandler(evt.pageX, evt.pageY);
  evt.preventDefault();
}

function upHandler(inX, inY) {
  isDown = false;
  if (realMouseUpFunction != null) {
    realMouseUpFunction(inX, inY);
    realMouseUpFunction = null;
  }
  draw();
}

function downHandler(inX, inY) {
  // document.getElementById("myX").innerHTML = evt.pageX;
  // document.getElementById("myY").innerHTML = evt.pageY;

  // document.getElementById("sweeperX").innerHTML = this.offsetLeft;
  // document.getElementById("sweeperY").innerHTML = this.offsetTop;

  var clickX = inX - this.offsetLeft;
  var clickY = inY - this.offsetTop;

  movementX = clickX;
  movementY = clickY;

  isDown = true;

  if (theCircleSynth == null) {
    theCircleSynth = new CircleSynth(getRandomId(), clickX, clickY, 20);
  } else {
    distanceFromSynth = findDistance(theCircleSynth.x, theCircleSynth.y, clickX, clickY);
    debug("distance = " + distanceFromSynth);
    offsetX = this.offsetLeft;
    offsetY = this.offsetTop;
    if (Math.abs(distanceFromSynth - theCircleSynth.radius) < (theCircleSynth.radius / 4)) {
      touchedMarker = null;
      touchedAngleDelta = 7;
      touchAngle = getAngleFromCircleCenter(clickX, clickY);
      debug("touch angle = " + touchAngle);
      for (var i = 0; i < theCircleSynth.markers.length; i++) {
	if (Math.abs(touchAngle - theCircleSynth.markers[i].angle) < touchedAngleDelta) {
	  touchedMarker = theCircleSynth.markers[i];
	  touchedAngleDelta = Math.abs(touchAngle - theCircleSynth.markers[i].angle);
	}
      }
      // if user is touching a marker, move it
      // else change radius
      if ((touchedMarker != null) && (Math.abs(getDistanceBetweenCircleAngles(touchedMarker.angle, touchAngle)) < 4)) {
	debug("setting mouse up handler to move marker");
	realMouseUpFunction = function(inX, inY) {
	  debug("mouse up at " + inX + ", " + inY);
	  debug("offset at " + offsetX + ", " + offsetY);
	  var clickUpX = inX - offsetX;
	  var clickUpY = inY - offsetY;
	  newAngle = getAngleFromCircleCenter(clickUpX, clickUpY);
	  touchedMarker.setAngle(newAngle);
	  debug("moved marker to " + touchedMarker.angle);
	}
      } else {
	debug("setting mouse up handler to change radius");
	realMouseUpFunction = function(inX, inY) {
	  debug("mouse up at " + inX + ", " + inY);
	  debug("offset at " + offsetX + ", " + offsetY);
	  var clickUpX = inX - offsetX;
	  var clickUpY = inY - offsetY;
	  dist = findDistance(theCircleSynth.x, theCircleSynth.y, clickUpX, clickUpY);
	  if (dist > 5) {
	    theCircleSynth.setRadius(dist);
	    debug("ran mouse up handler to change radius. radius = " + theCircleSynth.radius);
	  } else {
	    debug("bad dist " + dist);
	  }
	}
      }
    } else if (distanceFromSynth < theCircleSynth.radius) {
      debug("setting mouse up handler to move the circle");
      realMouseUpFunction = function(inX, inY) {
	debug("mouse up at " + inX + ", " + inY);
	debug("offset at " + offsetX + ", " + offsetY);
	var clickUpX = inX - offsetX;
	var clickUpY = inY - offsetY;
	theCircleSynth.setXY(clickUpX, clickUpY);
	debug("ran mouse up handler to move circle. circle at  = " + theCircleSynth.x + ", " + theCircleSynth.y);
      }
    } else {
      debug("setting mouse up handler to add a marker");
      newMarkerType = getMarkerTypeFromPositions(inX, inY, theCircleSynth.x, theCircleSynth.y);
      realMouseUpFunction = function(inX, inY) {
	debug("mouse up at " + inX + ", " + inY);
	debug("offset at " + offsetX + ", " + offsetY);
	var clickUpX = inX - offsetX;
	var clickUpY = inY - offsetY;
	distanceFromSynth = findDistance(theCircleSynth.x, theCircleSynth.y, clickUpX, clickUpY);
	debug("distance is " + distanceFromSynth);
	if (Math.abs(distanceFromSynth - theCircleSynth.radius) < (theCircleSynth.radius / 4)) {
	  debug("adding a marker");
	  newType = newMarkerType;
	  newAngle = getAngleFromCircleCenter(clickUpX, clickUpY);

	  theCircleSynth.addMarker(getRandomId(), newAngle, newType);
	  debug("added a marker of type " + newType);
	} else {
	  debug("did not add a marker because mouse up was too far from circle");
	}
      }
    }
  }
  draw();
}

function moveHandler(inX, inY) {
  offsetX = this.offsetLeft;
  offsetY = this.offsetTop;
  movementX = inX - offsetX;
  movementY = inY - offsetY;
  draw();
  // debug("movement:" + movementX + ", " + movementY)
}

function draw() {
 var canvas = document.getElementById("sweeper");
 var ctx = canvas.getContext("2d");

 ctx.fillStyle = "red";
 ctx.fillRect (0, 0, 1000, 600);

 if (theCircleSynth != null) {
   // ctx.fillStyle = "blue";
   ctx.strokeStyle = "blue";
   ctx.beginPath();
   ctx.arc(theCircleSynth.x, theCircleSynth.y, theCircleSynth.radius, 0, 7, 0);
   // ctx.fill();
   ctx.stroke();

   for (var i = 0; i < theCircleSynth.markers.length; i++) {
     var marker = theCircleSynth.markers[i];
     color = getColorFromType(marker.type);
     debug("marker color is " + color);
     ctx.fillStyle = color;
     ctx.beginPath();
     ctx.arc(theCircleSynth.x + Math.cos(marker.angle) * theCircleSynth.radius, theCircleSynth.y + Math.sin(marker.angle) * theCircleSynth.radius, 4, 0, 7, 0);
     ctx.fill();
   }
 }

 if (isDown && movementX && movementY) {
   ctx.fillStyle = "white";
   ctx.fillRect(movementX, 0, 2, 1000);
   ctx.fillRect(0, movementY, 1000, 2);
 }
}

