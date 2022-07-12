# The EasyBuild configuration


## Location of the EasyBuild modules

Ideally we would have an EasyBuild module for each software stack stored in the generic 
architecture(s) for the software stack. However, we also need one for the `system` partition
and it may not be a good idea to stick to an old version there.

There are two options:

1.  One in the generic architecture(s) for `calcua/system` and one in each the generic
    architecture(s) for each of the `calcua/yyyyx` software stacks. This would guarantee
    that at least for the non-system stacks the EasyBuild version would remain constant,
    and it could even remain constant for the `system` stack for quite a while

2.  All EasyBuild installations are done in the generic architecture(s) of `calcua/system`.
    This would allow to use a different version of EasyBuild than intended for the stack.

We did chose to go for the second option. However, we do let the EasyBuild config modules
force-load the correct version so the user has to overwrite explicitly after loading that
module.

The stack does implement a script that will bootstrap EasyBuild rather than install
EasyBuild with another version of EasyBuild. This makes it very easy to set up a 
test stack in a different file system.

