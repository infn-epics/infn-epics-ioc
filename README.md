Generic IOC Template Repository
===============================

This repository is a template for creating a generic IOC in the epics-containers
framework. See https://epics-containers.github.io for tutorials and documentation.


Developer image
------------------------
The developer is ubuntu22 based has:

image: baltig.infn.it:4567/epics-containers/infn-epics-ioc:devel

1. EPICS_BASE=/epics/epics-base
2. support modules installed in /epics/support

a tipical RELEASE.local:

```
EPICS_BASE=/epics/epics-base

# Additional Support Modules for individual IOCs will be added below this line

IOCSTATS=/epics/support/iocStats
SNCSEQ=
ASYN=/epics/support/asyn
IPAC=
AUTOSAVE=/epics/support/autosave
BUSY=/epics/support/busy
STREAMDEVICE=/epics/support/StreamDevice
CALC=/epics/support/calc
SSCAN=/epics/support/sscan
MOTOR=/epics/support/motor
MOTORMOTORSIM=/epics/support/motorMotorSim
ADCORE=/epics/support/ADCore
ADGENICAM=/epics/support/ADGenICam
ADSIMDETECTOR=/epics/support/ADSimDetector
MODBUS=/epics/support/modbus
SCREEN-EPICS-IOC=/epics/support/screen-epics-ioc
MOTORNEWPORT=/epics/support/motorNewport
```

To mount the current directory:

```
docker run -p 5064:5064/udp -p 5064:5064/tcp -p 5065:5065/udp -p 5065:5065/tcp -it -v .:/epics/ioc/config baltig.infn.it:4567/epics-containers/infn-epics-ioc:devel

```


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

1. A generic IOC with a working Dockerfile can be built with the build script
   in the root folder. This builds runtime and developer targets. This must be
   run outside the dev container.

1. Pushing the repo to github and tagging it will release a container image
   to the GitHub container registry. Gitlab CI is also supported.

1. Launching the project in vscode or other devcontainer IDE will allow you
   to open a devcontainre and test the IOC locally (including IOCs with
   system dependencies not available on your host).

1. A Basic test that verifies you have the correct libraries installed in
   the runtime container is provided in tests/runtests.sh. This must be
   run outside the dev container.

Developing inside the devcontainer
----------------------------------

A few points to note when developing inside the devcontainer:

1. The project folder is mounted at `/epics/ioc-template` (or equivalent).
   This means that the devcontainer container correleates closely to how
   the rutime container looks. Because of this you will have an uncompiled
   IOC when you first open the devcontainer. The following command  will
   make a working IOC:

   - `ibek ioc build`

      - adds a templated ioc source tree to `/epics/ioc-template/ioc`
      - generates a `Makefile` that includes all the dbds and libs from the
         support moudules in the container
      - compiles the resulting IOC


1. The ibek tool is preinstalled in the devcontainer. It is used by Dockerfiles
   to build the IOC but you can also use it on the command line. See
   `ibek --help` for more information.

1. You can add additional projects to your workspace that are peers to the
   `ioc-template` project. The folder `/repos` is mounted to the parent of
   your project folder for this purpose.

1. You can customize bash configuration and also customize a profile that can
   install additional packages at devcontainer creation time. These are
   customizations are for developer personalization and can apply to all
   epics-containes ioc projects. See [README.md](user_examples/README.md).

Jan 2024 Changes
----------------

After a review we have decided to simplify the approach to managing the IOC
source code. It is now included in the ioc-template repository and is
no longer templated in `ibek`.

The Makefile is the only dynamic thing in the ioc folder and it now uses
the files /epics/support/lib_list and dbd_list which `ibek` generates.

We also changed where the project is mounted in the devcontainer. It is now
in `/workspaces/ioc-template` which makes it the same as any other
standard devcontainer project. We now require the the name of the folder
be passed to the container build so that we can arrange for runtime and
devcontainer to share the location of the project. `epics-containers-cli`
v2.6.10b1 has been updated to automatically pass this when you use
`ec dev build`. `ibek` has been updated to support the new locations
in version `1.6.0b1`.

To update a pre-existing generic ioc to the new scheme:

- update requirements.txt_ec to `epics-containers-cli>=2.6.10b1`
- update requirements.txt to `ibek>=1.6.0b1`
- update ibek-support sub module to the branch `change-generate-links`
  - TODO this will be merged into main when all other changes are complete
    in epics containers ioc-xxxx projects
- copy in the ioc folder from ioc-template verbatim
- update Dockerfile top and bottom to match ioc-template (use a diff to see)

