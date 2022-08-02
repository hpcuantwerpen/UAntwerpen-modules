# The CalcUA-init module

The `CalcUA-init` module is used to partially initialise the CalcUA software stack,
moving some of that work out of the images on the compute nodes and into the software
stack framework.

It functions can include:

-   Printing the variable part of the message-of-the-day
-   Providing an interesting tip to a user, similar to the way fortune worked on old
    UNIX machines.
-   Loading the initial environment


## Current implementation

-   Build the MODULEPATH:
    -   Add style modifier modules
    -   Add the software stacks 
-   Set the module display style by loading `ModuleColour`, `ModuleExtensions`
    and `ModuleLabel` except when those modules are already loaded, and make sure
    they are not unloaded when the initialisation module is unloaded. That way a
    user can easily overwrite the display style by loading modules.
-   For now: We do have a provision to show the message of the day and/or some
    tips.
