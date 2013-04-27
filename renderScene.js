//	renderScene.js
//	JavaScript functionality for the animated rendering of the VGAPViewer scene file.
//
//	Copyright 2013 Dave Corboy <dave@corboy.com>
//
//	This file is part of VGAPViewer.
//	VGAPViewer uses the Planets Nu API (http://planets.nu/) to build a turn-by-turn
//	animation of any VGA Planets game.
//
//	VGAPViewer is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	VGAPViewer is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	If you did not receive a copy of the GNU General Public License
//	along with VGAPViewer, see <http://www.gnu.org/licenses/>.

var gAnimTurn;
var gAnimFrame;
var gFirstTurn;		// specifies game turn corresponding to first turn of data
var gPlay = false;	// start/stop animation control
var gPlayerID;

window.requestAnimFrame = (function(callback) {
	return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame ||
	function(callback) {
		window.setTimeout(callback, 1000 / 60);
	};
})();

function renderShipMove(ctx, scale) {

	var turnMoveData;

	if (gAnimTurn > 0) {
		ctx.strokeStyle = 'rgba(0,255,0,' + ((1.0 - scale) + .25) + ')';	// Green fade
		ctx.lineWidth = 2;
	
		ctx.beginPath();

		// for each ship move
		turnMoveData = sceneJSON.movement[gAnimTurn-1];
		for (var i=0, l=turnMoveData.length; i<l; i++ ) {
			var move=turnMoveData[i];

			ctx.moveTo(move.x, move.y)
			ctx.lineTo(move.targetx, move.targety);
		}

		ctx.stroke();
	}

	ctx.strokeStyle = "#00FF00";	// Green
	ctx.lineWidth = 2;
	
	ctx.beginPath();

	// for each ship move
	turnMoveData = sceneJSON.movement[gAnimTurn];
	for (var i=0, l=turnMoveData.length; i<l; i++ ) {
		var move=turnMoveData[i];

		ctx.moveTo(move.x, move.y)
		ctx.lineTo(move.x + ((move.targetx-move.x)*scale), move.y + ((move.targety-move.y)*scale));
	}

	ctx.stroke();
}

function renderShipBuild(ctx, scale) {
	ctx.lineWidth = 6;

	// for each ship build
	var turnBuildData = sceneJSON.shipbuilds[gAnimTurn]; /* animTurn */
	for (var i=0, l=turnBuildData.length; i<l; i++ ) {
		var build=turnBuildData[i];

		ctx.beginPath();
		ctx.strokeStyle='rgba(0,255,255,' + ((1.0 - scale) + .25) + ')';	// Cyan circle
		ctx.arc(build.x, build.y, 50*scale, 0, 2 * Math.PI, false);
		ctx.stroke();
	}
}

function renderStarbaseBuild(ctx, scale) {
	ctx.lineWidth = 20;

	// for each starbase build
	var turnBuildData = sceneJSON.starbasebuilds[gAnimTurn];
	for (var i=0, l=turnBuildData.length; i<l; i++ ) {
		var build=turnBuildData[i];

		ctx.beginPath();
		ctx.strokeStyle='rgba(255,255,255,' + ((1.0 - scale) + .25) + ')';	// Big white circle
		ctx.arc(build.x, build.y, 100*scale, 0, 2 * Math.PI, false);
		ctx.stroke();
	}
}

function renderShipDestroyed(ctx, scale) {
	ctx.lineWidth = 10;

	// for each ship destroyed
	var turnData = sceneJSON.shipsdestroyed[gAnimTurn];
	for (var i=0, l=turnData.length; i<l; i++ ) {
		var boom=turnData[i];

		ctx.beginPath();
		ctx.strokeStyle='rgba(255,0,0,' + ((1.0 - scale) + .25) + ')';	// small red circle
		ctx.arc(boom.x, boom.y, 30*scale, 0, 2 * Math.PI, false);
		ctx.stroke();
	}
}

function renderEnemyDestroyed(ctx, scale) {
	ctx.lineWidth = 5;

	// for each enemy destroyed
	var turnData = sceneJSON.enemiesdestroyed[gAnimTurn];
	for (var i=0, l=turnData.length; i<l; i++ ) {
		var boom=turnData[i];

		ctx.beginPath();
		ctx.strokeStyle='rgba(255,255,255,' + ((1.0 - scale) + .25) + ')';	// small white circle
		ctx.arc(boom.x, boom.y, 30*(1-scale), 0, 2 * Math.PI, false);
		ctx.stroke();
	}
}

function renderMinefields(ctx, scale) {
	ctx.lineWidth = 1;

	// for each minefield
	var turnData = sceneJSON.minefields[gAnimTurn];
	for (var i=0, l=turnData.length; i<l; i++ ) {
		var minefield=turnData[i];

		ctx.beginPath();
		var radius = minefield.oldradius + (minefield.radius - minefield.oldradius) * scale;
		ctx.arc(minefield.x, minefield.y, radius, 0, 2 * Math.PI, false);
		if (minefield.ownerid == gPlayerID) {
			ctx.strokeStyle = 'rgba(0, 255, 0, .4)';	// translucent green disc
			ctx.fillStyle = 'rgba(0, 255, 0, .25)';
		}
		else {
			ctx.strokeStyle = 'rgba(255, 0, 0, .4)';	// translucent red disc
			ctx.fillStyle = 'rgba(255, 0, 0, .25)';
		}
		ctx.fill();
		ctx.stroke();
	}
}

function setDisplayTurn(turn) {
	document.getElementById('oturn').innerHTML = gFirstTurn + turn;
}

function animate() {
	var ctx = document.getElementById('universe').getContext('2d');
	ctx.setTransform(1,0,0,-1,0,4000);

	// update

	// clear
	ctx.clearRect(0, 0, 4000, 4000);

	// draw stuff

	if (++gAnimFrame > 60) {
		gAnimFrame=1;
		if (++gAnimTurn >= sceneJSON.control.turns) gAnimTurn = 0;
		setDisplayTurn(gAnimTurn);
	}
	var scale = gAnimFrame / 60;

	renderShipMove(ctx, scale);
	renderShipBuild(ctx, scale);
	renderStarbaseBuild(ctx, scale);
	renderShipDestroyed(ctx, scale);
	renderEnemyDestroyed(ctx, scale);
	renderMinefields(ctx, scale);

	// request new frame if we are playing normally OR if we are mid-turn animation
	if (gPlay || gAnimFrame != 60) {
		requestAnimFrame(function() {
		  animate();
		});
	}
}

function resetAnimation()
{
	gAnimTurn = 0;
	gAnimFrame = 0;
	gPlay = false;
	setDisplayTurn(gAnimTurn);
	// we could display the blank field here
}

function playPauseAnimation()
{
	if (gPlay) {
		gPlay = false;
		document.getElementById('oplaypause').innerHTML = 'Play';
	}
	else {
		gPlay = true;
		document.getElementById('oplaypause').innerHTML = 'Pause';
		animate();
	}
}

function stepAnimation()
{
	animate();
}

function render()
{
	document.write("<p>Scene render started...</p>");
	//document.write("<h2>Turn: " + sceneJSON.movement[0].turn + "</h2>");
	document.write("<p>Scene parser complete</p>");
	var ctx = document.getElementById('universe').getContext('2d');
	ctx.setTransform(1,0,0,-1,0,4000);

	document.getElementById('universe').style.backgroundImage="url('" + sceneJSON.control.background + "')";
	document.getElementById('ogame').innerHTML = sceneJSON.control.name;
	gPlayerID = sceneJSON.control.playerid;
	document.getElementById('oplayer').innerHTML = gPlayerID + "&nbsp;(" + sceneJSON.control.playername + ")";
	gFirstTurn = sceneJSON.control.firstturn;
	resetAnimation();
}
