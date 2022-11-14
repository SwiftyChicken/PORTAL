# PORTAL
x86 assembly remake of Portal Prelude on the TI-84


## TO DO 
(mark waar je aan bent aan het werken met [R] of [W])


### Fase 1: Character can move
	* Gameloop, keyb handler (cf. EXAMPLE code)
	* Position-adt
	* Character: 
		* Character-adt
		* keyb invoer om character te besturen
		* Draw-adt (sprite of block voor character)
	* Level: 
		* Draw-adt (enkel background tekenen)


Main-adt:	Keyb handler, gameloop, levels oproepen\  
Maze-adt: 	Vertaalt file naar matrix gevuld met objecten\
Level-adt: 	Collision, portals\
Portal-adt: 	Position-adt, direction\
Position-adt: 	Snelheid, versnelling, x- en y-coördinaten\
Bullet-adt:	Stuurt msg naar level-adt, position-adt\
Character-adt:	Position-adt\
Wall-adt:	Position-adt\	
Draw-adt:	Sprites tekenen voor elk object


### Fase 2: Files inlezen, collision
	* Eerste level van Prelude namaken in file en filetype kiezen
	* Files inlezen: Maze-adt
	* Collision: Level-adt, Wall-adt
	* Draw-adt aanpassen om level te tekenen

### Fase 3: Schieten en portals
	* Bullet-adt (beginnen met bullets kunnen schieten)
	* Portal-adt 
		* Wanneer bullet wall-adt raakt veranderen in portal-adt
		* Direction van waar er gehit is bijhouden
		* Portal functionaliteit implementeren
	* Zorgen dat snelheid en versnelling van character sense maken met portals 
	* Draw-adt aanpassen om kogels en portals te tekenen
	
### Fase 4: Volgende levels
