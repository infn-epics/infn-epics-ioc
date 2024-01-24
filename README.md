Generic IOC Template Repository
===============================

This repository is a template for creating a generic IOC in the epics-containers
framework. See https://epics-containers.github.io for tutorials and documentation.

Making a new generic IOC
------------------------

1.  Go to the
    [GitHub page](https://github.com/epics-containers/ioc-template) and
    click **Use this template** -> **Create a new repository** Then choose a name and
    organization for your new generic IOC.

1. Change the `README.md` file to describe your IOC.

1. Change the `Dockerfile` to compile in the support modules you need in
   your generic IOC Container.

1. Once you have it working you can update `tests/runtests.sh` to run your
   IOC in a container and test it. We recommend creating a Tickit simulation
   of the device you are controlling and using that to test your IOC.
   See https://dls-controls.github.io/tickit/typing_extensions/index.html


Working with the IOC
--------------------

1. A generic IOC with a working Dockerfile can be built with the `build` script
   in the root folder. This builds runtime an developer targets.

1. Pushing the repo to github and tagging it will release a container image
   to the GitHub container registry. Gitlab CI is also supported.

1. Launching the project it vscode or other devcontainer IDE will allow you
   to open a developer container and test the IOC locally (including IOCs with
   system dependencies not available on your host).

1. A Basic test that verifies you have the correct libraries installed in
   the runtime container is provided in `tests/runtests.sh`. This must be
   run outside the developer container.
