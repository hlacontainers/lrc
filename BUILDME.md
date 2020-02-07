# Build the LRC images

The LRC images for Pitch and VTMaK are built from the Pitch CRC and VTMaK RTI Executable images respectively. **These images must be built first**.

If the Pitch CRC and VTMaK RTI Executable images are **skeleton** images then the LRC images build from these are **skeleton** LRC images. A skeleton image only contains a skeleton directory structure and some relevant (but empty) files, but not the actual LRC files. These need to be mounted afterwards at run time. The build steps for creating these images are identical.

Perform the following steps to build the LRC images.

## Clone repository

Clone this Git repository to the directory named `${WORKDIR}`.

## Build the image

Change into the directory `${WORKDIR}/lrc/docker`.

Check and if needed adapt the environment variable settings in the file `.env`. Make sure that the RTI version number matches. For example, for VTMaK the RTI version should be e.g. `4.5` or `4.5f`.

Next, build the LRC container images with:

````
docker-compose -f build-pitch.yml build

docker-compose -f build-vtmak.yml build

docker-compose -f build-portico.yml build
````

The Pitch and VTMaK LRC images derive the vendor proprietary libraries from the Pitch CRC and VTMaK RTI Executable images respectively. No Pitch or VTMaK proprietary libraries are included in this repository.

The Portico library is included under the portico directory.

# Mount LRC files from host file system

If a skeleton LRC image is used then the  LRC files must be mounted from the host file system in order to create a functional LRC container.

This can be accomplished, based on the following assumptions:

- the LRC library files are installed on the host filesystem at `${RTI_HOME}/lib`;

- the LRC include files are installed on the host filesystem at `${RTI_HOME}/include`;

- and the RID file is installed under `${RTI_HOME}`.

These assumptions are satisfied if the standard installation instructions are followed for the RTI, and the RTI is installed under `${RTI_HOME}`.

The mount point of the LRC in the container is `/usr/local/lrc/code`. For the Pitch RTI the docker compose file may look like:

`````
version: '3'

services:
 xserver:
  image: ${REPOSITORY}xserver
  ports:
  - "8080:8080"
  
 crc:
  image: ${REPOSITORY}pitch-crc:${PITCH_VERSION}
  mac_address: ${MAC_ADDRESS}
  environment:
  - DISPLAY=${DISPLAY}

 app:
  image: ${REPOSITORY}start:pitch-alpine
  volumes:
  - ${RTI_HOME}:/usr/local/lrc/code
  environment:
  - LRC_MASTERADDRESS=crc:8989
  - DISPLAY=${DISPLAY}
`````

