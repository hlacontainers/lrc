# Build the LRC images

The LRC images for Pitch and VTMaK are built from the Pitch CRC and VTMaK RTI Executable images respectively. **These images must be built first**.

If the Pitch CRC image or VTMaK RTI Executive image is a **skeleton** images then the LRC images build from these will be **skeleton** LRC images. A skeleton image only contains a skeleton directory structure and some relevant (but empty) files, but not the actual LRC files. These need to be mounted afterwards at run time. The build steps for creating these images are identical. A skeleton image can be recognized by its tag.

Perform the following steps to build the LRC images.

## Clone repository

Clone this Git repository to the directory named `${WORKDIR}`.

## Build the image

Change into the directory `${WORKDIR}/lrc/docker`.

Check and if needed adapt the environment variable settings in the file `.env`. For Pitch or VTMaK make sure that the RTI version number matches with the Pitch CRC or VTMaK RTI.

Next, build the LRC container images with:

````
docker-compose -f build-pitch.yml build

docker-compose -f build-vtmak.yml build

docker-compose -f build-portico.yml build
````

The Pitch and VTMaK LRC images derive the vendor proprietary libraries from the Pitch CRC and VTMaK RTI Executable images respectively. No Pitch or VTMaK proprietary libraries are included in this repository.

The Portico library is included under the portico directory.

# Mount LRC files from host file system

If a skeleton LRC image is used then the LRC files must be mounted from the host file system in order to create a functional LRC container. The is easily accomplished by installing the (Pitch or VTMaK) RTI under `${RTI_HOME}` and mount this directory in the container. The mount point of the LRC in the container is `/usr/local/lrc/code`. For the Pitch RTI the docker compose file may look like:

`````
version: '3'

services:
 xserver:
  image: ${REPOSITORY}xserver
  ports:
  - "8080:8080"
  
 crc:
  image: ${REPOSITORY}pitch-crc:${PITCH_VERSION}
  volumes:
  - ${RTI_HOME}:/usr/local/prti1516e
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

