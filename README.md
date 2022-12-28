# PORTAL
x86 assembly remake of Portal Prelude on the TI-84


## TO DO 
- [ ] LOGIC: PROC tryFitPortal
    - Move Portal.x and Portal.y from center to start of portal point
    - If this position is not available try to move it by 1 pixel (do this 5 maybe?)
    - Try (C := current, X := portal points W := wall)
        - START: WWWXXCXXWWW
        - WWWCXXXXWWW
        - WWWWCXXXXWW
        - WWWWWCXXXXW
        - WWCXXXXWWWW
        - WCXXXXWWWWW
