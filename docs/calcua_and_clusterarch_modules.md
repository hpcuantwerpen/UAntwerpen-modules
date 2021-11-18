# The generic calcua and clusterarch modules

The calcua and clusterarch modules work together to load a version of the
software stack for the right architecture. Moreover they ensure that the
EasyBuild-config module can recover all the information it needs to install
software in the right directories.

The calcua module is loaded first. This module sets the version of the software
stack. The version of the software stack is of the form year followed by the letter
a or b.

TODO: Think about support for yyyy.mm also as this is used during the development
of new toolchains in EasyBuild itself, and also for EESSI.

The calcua modules will automatically load the best fitting clusterarch module
for the node on which the module is loaded. However, it is always possible to
overwrite that option later on.

Instances of the generic clusterarch module come in two shapes:
  * cluster/<name> or cluster/<name>-<OS> or cluster/<name>-<arch> or
    cluster/<name>-<arch>-<OS> or any other special designator: This is because
    users will typically be more familiar with the name of the cluster than with
    the CPU architecture. The mapping to CPU architecture is coded internally.
  * arch/CPUarchitecture or arch/CPUarchitecture-OSversion: This is a direct mapping
    to the underlying directory structure.


## The calcua generic module






## The clusterarch generic module


