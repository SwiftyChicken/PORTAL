# PORTAL
x86 assembly remake of Portal Prelude on the TI-84


## TO DO 
- [X] LOGIC.ASM: PROC tryFitPortal
    - Move Portal.x and Portal.y from center to start of portal point
    - If this position is not available try to move it by 1 pixel (do this 5 maybe?)
    - Try (C := current, X := portal points W := wall)
        - START: WWWXXCXXWWW
        - WWWCXXXXWWW
        - WWWWCXXXXWW
        - WWWWWCXXXXW
        - WWCXXXXWWWW
        - WCXXXXWWWWW

- [X] DRAW.ASM: PROC drawLaser
    - Draw line from player to portal center
    - Make the line only flash once. IDEAS:
        - hold it in a data segment as TRUE or FALSE
        - hold a number in data segment that gives the amount of time to draw it

- [X] Animated ~~monochrome~~ colored portals
    - Make ~~monochrome~~ colored portal animations

- [X] LOGIC.ASM: don't draw portals over each other
    - Check TI 84 behaviour
    
- [ ] LOGIC.ASM: Teleportation logic
    - [X] being able to enter half the portal -> teleport half in the other portal
    - [X] add clone that move based on how much of the player is in the portal
    - [X] clone management
    - [ ] effectively teleport the player...
