# The CalcUA-init module

The `CalcUA-init` module is used to partially initialise the CalcUA software stack,
moving some of that work out of the images on the compute nodes and into the software
stack framework.

It functions can include:
  * Printing the variable part of the message-of-the-day
  * Providing an interesting tip to a user, similar to the way fortune worked on old
    UNIX machines.
  * Loading the intial environment
