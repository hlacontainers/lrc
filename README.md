# LRC image

The LRC is a set of C++ and Java libraries that federate applications must use to communicate via the HLA Run Time Infrastructure (RTI). The API of the libraries is standardized, but the implementation of the libraries is RTI (vendor) specific. Depending on what RTI implementation is used, a central component (Pitch CRC or VTMaK RTI Executive) is required for the execution of a federation.

This repository provides Dockerfiles and instructions for the creation of Local RTI Component (LRC) container images for different HLA-RTI vendors and Linux platforms. These images can be extended with application specific logic to create an application container image for an HLA federate application.

The LRC images for the Portico RTI are available on Docker Hub. The images for the VTMaK and Pitch RTI should be built by the user in the own build environment.

For the instructions to build an LRC container image see [BUILDME](BUILDME.md).

## Container synopsis

````
lrc:<vendor>-<version>-<platform>-<jdk> <options>
````

Where:

- `<vendor>` is **pitch**, **portico** or **vtmak**,
- `<version>` is the LRC version,
- `<platform>` is **debian** or **centos8**, and
- `<jdk>` is the Open JDK version included in the image.

The container `<options>` are passed on to the federate application. In principle, command line options are federate application specific.

## Environment variable

Environment variables are used to configure an LRC (LRC Settings), or to provide information to the
federate application (federate application settings). LRC settings are mostly LRC image dependent. For
example, when using the Pitch LRC image, the CRC hostname and port number can be specified by setting the environment variable `PITCH_CRCADDRESS`. There are also LRC settings that every LRC image supports, such as the environment variable `LRC_ENTRYPOINT` and `LRC_SLEEPPERIOD`.

The LRC settings are processed by the `launch.sh` script in the LRC image and used to appropriately configure the LRC. In the following docker compose file fragment the image `msaas/myapplication` uses two LRC settings. The environment variable `PITCH_CRCADDRESS` is LRC specific and identifies the address of the Pitch CRC . The environment variable `LRC_SLEEPPERIOD` instructs the launch script to sleep for one second before starting the federate application.

````
myservice:
 image: msaas/myapplication
 environment:
 - PITCH_CRCADDRESS=crc:8989
 - LRC_SLEEPPERIOD=1
````

Federate application settings are environment variables provided to the federate application. This concerns the environment variables `CLASSPATH` and `LD_LIBRARYPATH`. These define paths to the shared object libraries (Java or C++) required for executing the application.

## LRC settings
LRC settings are environment variables used to configure and control the behavior of the LRC. There are general environment variables applicable to any RTI, and RTI specific variables. These environment variables are described in the LRC scripts repository.

## Federate application settings
Federate settings are environment variables to use by or to initialize the federate application. These are:

| Environment variable | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| `CLASSPATH`          | Class path files for Java applications.                      |
| `LD_LIBRARYPATH`     | Library search path for shared objects for C++ applications. |

For Java applications the RTI JARs have been added to the Java `CLASSPATH` environment variable.

For C++ applications the RTI SOs have been added to the `LD_LIBRARY_PATH` environment variable.

The MÄK RTI implementation is a binding layer over a C++ implementation and those C++ libraries need to be on the `LD_LIBRARY_PATH` at runtime, also if the user application is a Java application.

