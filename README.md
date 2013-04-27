# VGAPViewer

VGAPViewer uses the [Planets Nu](http://planets.nu/) API to build a turn-by-turn animation of any VGA Planets game.

You will need Ruby and Bash to build the scene file which renders on an HTML 5 Canvas in any modern browser.

<a target="_blank" href="http://www.corboy.com/vgapviewer/images/assault.png">
	<img style="max-width: 100%; width: 350px; margin: 5px;" title="Assault" alt="Assault" src="http://www.corboy.com/vgapviewer/images/assault.png">
</a>
<a target="_blank" href="http://www.corboy.com/vgapviewer/images/expansion.png">
	<img style="max-width: 100%; width: 350px; margin: 5px;" title="Expansion" alt="Expansion" src="http://www.corboy.com/vgapviewer/images/expansion.png">
</a>
<a target="_blank" href="http://www.corboy.com/vgapviewer/images/breach.png">
	<img style="max-width: 100%; width: 350px; margin: 5px;" title="Breach" alt="breach" src="http://www.corboy.com/vgapviewer/images/breach.png">
</a>

# Examples

Here are some sample animations from a recent game with my colleagues:

* [Player 11](http://www.corboy.com/vgapviewer/player11/vgapviewer.html)
* [Player 1](http://www.corboy.com/vgapviewer/player1/vgapviewer.html)
* [Player 5](http://www.corboy.com/vgapviewer/player5/vgapviewer.html)
* [Player 6](http://www.corboy.com/vgapviewer/player6/vgapviewer.html)

## Animations Supported

* Ship Moves (Friendly)
* Ship Builds
* Starbase Builds
* Ship Explosions (Friendly)
* Ship Explosions (Enemy)
* Minefields (Friendly and Enemy)

## Usage

Rendering a Planets Nu game is done in three parts:

1. Retrieivng the Turn Data Files
2. Processing the Turn Data Files
    into a composite scene file
3. Viewing the Resulting Scene

### Retrieving the Turn Data Files

The Planets Nu API is documented [here](http://vgaplanets.org/index.php/Planets.Nu_API) and [here](http://planets.nu/api-documentation).

The documentation describes that you can retrieve the turn data for a completed game with: `http://api.planets.nu/game/loadturn?gameid=GAMEID&playerid=PLAYERID&turn=TURNNUMBER`

Since processing happens locally, you should use a bash script to retrieve all the turn files you will need via `curl`.

``` bash
for i in {2..69}
do
	curl --compressed -d gameid=52834 -d playerid=11 -d turn=$i http://api.planets.nu/game/loadturn > ./player11/VGAP-T$i.json
done
```

The process is a tiny bit more involved if the game is still underway (you need to authenticate the request) but can still be done quite easily. Check the API docs.
If you don't know your game ID, you can look that up via the API as well, but I may have simply pulled the number from the game url.

### Processing the Turn Data Files

Processing the turn files into a composite scene file is done by the `processTurns.rb` Ruby script.

You can type `./processTurns.rb -h` for full option information, but you basically provide the numbered file pattern, a starting and ending turn number and then collect the result from `stdout`.

``` bash
./processTurns.rb -f ./player11/VGAP-T.json -s 2 -e 69 > scene.json
```	

The above will open the turn files from `./player11/VGAP-T2.json` to `./player11/VGAP-T69.json` and process them into `scene.json`.
### Viewing the Resulting Scene

`VGAPViewer.html` uses the JSON object stored in `scene.json` to render the game animation.

The animation starts paused, allowing you to scroll your starting viewpoint.

Only standard window scrolling and browser zoom controls are available at present, but these should work ok.

## Known Issues

* The system only works with the large 4k x 4k maps. I have never played one of the smaller games. Send me the game number for a game with a smaller map and I will build in the support.
* Make sure that the player was active during the first processed turn as the background planet map is taken from the first turn of the scene.
* HYP movement is not properly animated
* The current enemy ship explosion animation (shrinking white ring) sucks.

## To Do

* Convert serialized JSON variable to JSONP
* I think the minefields should be shown a turn earlier than they are
* Come up with a better enemy ship explosion animation
* Support arbitrary map sizes
* Better frame-by-frame controls, looping control
* Zoom controls
* Merge multiple player scenes to create composite full-game animation?

## License

[GNU General Public License](http://www.gnu.org/licenses/)

&copy; Copyright 2013 Dave Corboy <dave@corboy.com>

This file is part of VGAPViewer.
VGAPViewer uses the Planets Nu API (http://planets.nu/) to build a turn-by-turn
animation of any VGA Planets game.

VGAPViewer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

VGAPViewer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

If you did not receive a copy of the GNU General Public License
along with VGAPViewer, see <http://www.gnu.org/licenses/>.