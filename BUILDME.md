# Build the LRC images

The LRC images for Pitch and VTMaK are built from the Pitch CRC and VTMaK RTI Executive images respectively. **These images must be built first**.

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

The Pitch and VTMaK LRC images derive the vendor proprietary files from the Pitch CRC and VTMaK RTI Executive images respectively. No Pitch or VTMaK proprietary files are included in this repository.

The Portico proprietary library is included under the portico directory.

