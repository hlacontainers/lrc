![Build Status](https://img.shields.io/docker/cloud/build/hlacontainers/lrc)
![Pull](https://img.shields.io/docker/pulls/hlacontainers/lrc)

# LRC image

The Local RTI Component (LRC) is a set of C++ and Java libraries that federate applications must use to communicate with the RTI. The API of the libraries is standardized, but the implementation of the libraries is RTI (vendor) specific. Depending on what RTI implementation is used, a central component (Pitch CRC or VTMaK RTI Executive) is required for the execution of a federation.

Several LRC container images are available for different RTI vendors and Linux platforms. The LRC container image enables several standard approaches to the containerization of an HLA federate application, regardless what RTI vendor or platform is used. The three approaches - design patterns - for the containerization of HLA federate applications using an LRC image are described in the section [LRC containerization patterns](docs/lrc.md). The patterns are named:

* Containerization via extension;
* Containerization via composition of the application;
* Containerization via composition of the LRC.

The LRC and HLA federate application must be combined to become an executable application. This combination can be done at either container **build time** or at container **run time**. The first pattern concerns the build time construction of a container image via image extension, which is the more traditional approach. The latter two patterns concern the run time combination of containers through volume mounts. The **start-me** repository contains several examples of compositions that demonstrate the three patterns.

The patterns are initially described in the paper titled [Guidelines and best practices for using Docker in support of HLA federations](https://www.sisostds.org/DigitalLibrary.aspx?Command=Core_Download&EntryId=44931) (SISO Simulation Innovation Workshop, 2016, paper number 31).

For some RTIs a **skeleton** Docker container image is built from the files in this repository. A skeleton container image does not include any vendor proprietary files. Depending on the pattern used these files must be mounted into the application or LRC container at run-time in order to create a functional application. A skeleton image can be recognized via its tag.

For the instructions to build an LRC container image see [BUILDME](BUILDME.md).

## Container synopsis

````
lrc:<vendor>-<version>-<platform>-<jdk> <options>

lrc:<vendor>-<version> <options>
````

Where:

- `<vendor>` is **pitch**, **portico** or **vtmak**,
- `<version>` is the LRC version,
- `<platform>` is **alpine**, **debian** or **centos7**, and
- `<jdk>` is the Open JDK version included in the image.

The container `<options>` are passed on to the federate application. In principle, command line options are federate application specific.

Specific notes on images:

- `lrc:<vendor>-<version>-<platform>-<jdk>`
  - Use for the extension pattern.
  - Includes Open JDK.
  
- `lrc:<vendor>-<version>`.
  - Use for the composition pattern.
  - These images do not include Open JDK. The purpose of these minimal images is that they can be mounted into the application container.

## Settings

Settings are environment variables used to configure an LRC (LRC settings), or to provide information to the
federate application (federate application settings). LRC settings are mostly LRC image dependent. For
example, when using the Pitch LRC image, the CRC hostname and port number can be specified by setting the environment variable `PITCH_CRCADDRESS`. There are also LRC settings that every LRC image must support, such as the environment variable `LRC_ENTRYPOINT` and `LRC_SLEEPPERIOD`.

The LRC settings are processed by the `launch.sh` script in the LRC image and used to appropriately configure the LRC. In the following docker compose file fragment the image `msaas/myapplication` is built with the extension pattern and uses two LRC settings. The environment variable `PITCH_CRCADDRESS` is LRC specific and identifies the address of the Pitch CRC . The environment variable `LRC_SLEEPPERIOD` instructs the launch script to sleep for one second before starting the federate application.

````
myservice:
 image: msaas/myapplication
 environment:
 - PITCH_CRCADDRESS=crc:8989
 - LRC_SLEEPPERIOD=1
````

Federate application settings are environment variables provided to the federate application. This includes the environment variables `LRC_CLASSPATH` and `LRC_LIBRARYPATH`. These define paths to the shared object libraries (Java or C++) providing the LRC for use when executing the application.

## LRC settings
LRC settings are environment variables used to configure and control the behavior of the LRC. There are general environment variables applicable to any RTI, and RTI specific variables.

### General settings
| Environment variable  | Description                                                  | Default if not specified |
| --------------------- | ------------------------------------------------------------ | ------------------------ |
| ``LRC_ENTRYPOINT``    | Shell script to start the federate application.              | Container exit           |
| ``LRC_MASTERADDRESS`` | Master hostname and port number as ``<hostname>:<port>``.    | No master address        |
| ``LRC_SLEEPPERIOD``   | Sleep period in seconds before starting the federate application; format ``<min>[:<max>]``. If a max is specified then a random value between min and max is used as actual sleep period. | No sleep period          |
| `LRC_DEBUG`           | Print debug information. Set to a non-empty value to enable. | No debug.                |

If ``LRC_MASTERADDRESS`` is set to a non-empty string (in the format specified), then the container attempts to connect to the provided master address before starting the federate application defined in ``LRC_ENTRYPOINT``. The design pattern is that a master container bootstraps on a master host, creates/joins the federation execution, and opens the master port when ready. Once the port is open, other containers (based on the LRC image) that waited for the master component can then start the federate application. For the Pitch LRC image the Pitch CRC can serve as the master; for the VTMaK LRC image the RTI Executable can serve as master. If `LRC_MASTERADDRESS` is unset or is set to an empty string then no attempt is made to connect to a master address; this is the default behavior.

The sleep period applies from the point in time where the master port is open (if master address set), or from the point in time where the container is started (if master address is unset or empty).

### Pitch LRC settings
| Environment variable                | Description                                                  | Default if not specified                     |
| ----------------------------------- | ------------------------------------------------------------ | -------------------------------------------- |
| `PITCH_LRC_SETTINGS_FILE`           | File system path to LRC settings file.                       | `${LRC_HOME}/code/prti1516eLRC.settings`     |
| `PITCH_LRC_LOGGING_FILE`            | File system path to LRC logging file.                        | `${LRC_HOME}/code/prti1516e.logging`         |
| ``PITCH_CRCADDRESS``                | CRC address in the format of `<host>:<port>` (direct mode) or `<crc-nickname>@<boost host>:<boost port>` (booster mode). | `crc:8989`                                   |
| ``PITCH_LRCADAPTER``                | Applies to direct mode. The network adapter that the LRC should use. | Use IP route to CRC to determine adapter     |
| ``PITCH_BOOSTADAPTER``              | Applies to booster mode. The network adapter that the LRC should use for the Booster network. | Use IP route to booster to determine adapter |
| ``PITCH_ADVERTISE_ADDRESS``         | Applies to direct mode. Use this address to advertise the LRC. The format is ``[<host address>][:[<mintcpport>]-[<maxtcpport>][:[<minudpport>]-[<maxudpport>]]]`` | `:6000-6999:5000-5999`                       |
| ``PITCH_BOOSTER_ADVERTISE_ADDRESS`` | Applies to booster mode. Use this address to advertise the LRC to Booster. The format is ``[<host address>][:[<mintcpport>]-[<maxtcpport>][:[<minudpport>]-[<maxudpport>]]]`` | `:6000-6999:5000-5999`                       |
| ``PITCH_ENABLETRACE``               | Set to any value to enable. Enable RTI and Federate Ambassador tracing to console. | No tracing                                   |

#### Notes on the advertise address

When using ``PITCH_ADVERTISE_ADDRESS`` with a port range, make sure that the same port range is also provided in the container ``-p`` option. For example:

````
docker run \
	-e PITCH_ADVERTISE_ADDRESS=10.10.10.11:6100-6110 \
	-p 6100-6110:6100-6110 \
	yourApplicationImagename
````

If only the advertise address is specified, then the port range defaults to `6000-6000:5000-5000`.

If only the advertise address and the TCP port range are specified, then the UDP port range defaults to `5000-(5000+<maxtcpport>-<mintcpport>)`.

There is a LRC limitation on the UDP port range:

- When using JRE 6 or lower: the LRC selects odd-numbered UDP ports.

- When using JRE 7 or higher: the LRC selects even-numbered UDP ports. For example, UDP port range `30001-30001` is invalid for JRE 8.

This restriction can be disabled by adding`se.pitch.prti1516e.disablePortRestrictions=true` to the LRC settings file.

### Portico LRC settings

| Environment variable            | Description                                                  | Default if not specified     |
| ------------------------------- | ------------------------------------------------------------ | ---------------------------- |
| ``PORTICO_RTI_RID_FILE``        | File system path to the RID file.                            | ``${LRC_HOME}/code/RTI.rid`` |
| ``PORTICO_LRCADAPTER``          | The network adapter (network interface) that the LRC should use. The name must be an exact match. | RID file default             |
| ``PORTICO_LOGLEVEL``            | Specify the level that Portico will log at. Valid values are: TRACE, DEBUG, INFO, WARN, ERROR, FATAL, OFF. | RID file default (WARN)      |
| ``PORTICO_UNIQUEFEDERATENAMES`` | Ensure that all federates in a federation have unique names. When false, Portico will change the requested name from "name" to "name (handle)" thus making it Unique. Valid values are: true, false. | RID file default (true)      |

### VTMÄK LRC settings

| Environment variable            | Description                                                  | Default if not specified                                     |
| ------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `MAK_RTI_RID_FILE`              | File system path to the RID file. Note that the LRC RID file needs to be compatible with the RID properties used by the RTI Executable. | `${LRC_HOME}/code/rid.mtl`                                   |
| `MAK_RTIEXECADDRESS`            | RTI Exec address in the format of `<host>:<port>`.           | `rtiexec:4000`                                               |
| ``MAK_LRCADAPTER``              | Network interface address to use for the TCP Forwarder       | `0.0.0.0`, i.e. first available non-localhost interface address |
| `MAK_RTI_NOTIFY_LEVEL`          | Change the level of logging detail generated by the LRC. Values in the range 0--4 are valid with 0 being no logging and 4 being the most detailed | 2                                                            |
| `MAK_RTI_LOG_FILE_DIRECTORY`    | Specify a directory into which LRC log files will be written. This is most useful if it is a volume mount so that the log file becomes visible on the host system | Working directory of the federate                            |
| `MAK_RTI_RTIEXEC_LOG_FILE_NAME` | The name of the log file to be written by the LRC. The file is written into `MAK_LOGFILE_DIR`. Logging to file is not enabled unless this environment variable is set. | Not set                                                      |
| `RTI_ASSISTANT_DISABLE`         | Applicable to the LRC image that includes the RTI Assistant. To disable the RTI Assistant, set this environment to any value. If unset, set DISPLAY to an X Server display. | Enabled                                                      |
| `MAK_RTI_JAVA_RTIAMB_BUFLEN`    | Set the size of the RTI Ambassador buffer (in bytes) to allow the Java federate to send a large parameter or attribute value as per case [#MAK40782]. Also ensure that `RTI_use32BitsForValueSize` is set to 1 in the RID file to be able to represent this size. | `1000000`                                                    |
| `MAK_RTI_JAVA_FEDAMB_BUFLEN`    | Set the size of the Federate Ambassador buffer (in bytes) to allow the Java federate to receive a large parameter or attribute value as per case [#MAK42276]. Also ensure that `RTI_use32BitsForValueSize` is set to 1 in the RID file to be able to represent this size. | `1000000`                                                    |

## Federate application settings
Federate settings are environment variables to use by or to initialize the federate application.

| Environment variable | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| ``LRC_HOME``         | Home directory in which the LRC include files and libraries are stored. |
| ``LRC_CLASSPATH``    | RTI class path files for Java applications. This path is also added to ``CLASSPATH``. |
| ``LRC_LIBRARYPATH``  | RTI library search path for shared objects for C++ applications. This path is also added to ``LD_LIBRARYPATH``. |
| ``LRC_VERSION``      | Version identification of the LRC image.                     |

### Java language

For Java applications the `LRC_CLASSPATH` has been added to the Java `CLASSPATH` environment variable.

###  C++ language

For C++ applications `LRC_LIBRARYPATH` has been added to the `LD_LIBRARY_PATH` environment variable.

In addition, when using the MÄK LRC, the contents of `LRC_LIBRARYPATH` has been added to the `LD_LIBRARY_PATH` environment variable. This is required as the MÄK RTI implementation of the Java HLA Interface Specification is a binding layer over a C++ implementation and those C++ libraries need to be on the `LD_LIBRARY_PATH` at runtime.

## Gracefully stopping a containerized HLA federate application
When a container is stopped (with the docker stop command) the signal SIGTERM is sent to the process with PID 1 running inside the container. If this process does not terminate within 10 seconds, Docker will kill the process with the signal SIGKILL. This means that an HLA federate application will "disappear" abruptly from the federation execution and any resouces that the container process holds are not released in an orderly fashion. Thus to gracefully stop a container and its containing process(es), the process with PID 1 must handle the SIGTERM signal.

As mentioned earlier the federate application is started through the shell script defined by the environment variable ENTRYPOINT. The LRC launch.sh script ensures that this shell script runs in a shell with PID 1.

When the start script listed in the previous section is used to start the application, the application will not be terminated by the SIGTERM. This is because the application is actually executed in a new shell, forked from the shell with PID 1. The new shell will not receive the SIGTERM signal.

For a Java federate application, the following start script can be used to forard the SIGTERM signal to the application, running inside a Java Virtual Machine (JVM):

```
#!/bin/sh

# Initialise the PID of the application
pid=0

# define the SIGTERM-handler
term_handler() {
  echo 'Handler called'
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# on signal execute the specified handler
trap 'term_handler' SIGTERM

# run application in the background and set the PID
java -cp MyApplication.jar:$CLASSPATH myapplication.Main $@ &
pid="$!"

wait "$pid"
```

The start script forwards the SIGTERM to the JVM, where it is up to the application running inside the JVM to handle the SIGTERM. The application running inside the JVM should use a _Shutdown Hook_ to catch the shutdown of the JVM. For more information on handling SIGTERM and JVM shutdown, see [Shutdown Hook](https://docs.oracle.com/javase/7/docs/api/java/lang/Runtime.html).

