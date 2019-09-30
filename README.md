# Encrypted SyncThing

This project is a stop-gap which will encrypt the SyncThing filesystem to
improve security when running SyncThing on untrusted hosts (VPS).

A gocryptfs encrypted filesystem is used on the host, and the Docker image
uses a `distroless` base image to make it difficult for an unauthorized used
to be able to `docker exec` into the running image.

The gocryptfs key is built in memory from a part that exists only
in the Dockerfile and part passed in during runtime so that binary examination
is insufficiuent to decrypt the key.

**NOTE: This is not a secure system!  While it should significantly increase the
effort to access your SyncThing filesystem, someone with access to the Docker
image and the invocation could, with enough skill, determine the gocryt key and
decrypt your data.**

## Instructions
1. Download the pre-built gocrypt binary (or source and build yourself) from
   https://github.com/rfjakob/gocryptfs/releases

2. Create the encrypted path:
   `export CRYPT_PATH=<path on host>`

3. Encrypt path (choose a passowrd of your liking: `grocypt -init $CRYPT_PATH`
   *NOTE: Remember the masterkey.  we will use it in the next step*

4. Encrypt the master key with a pass-phrase (Do NOT use the gocrypt password here!).
   The longer the better (up to 72 bytes).  I recommend creating a 72-byte random string.
   `perl generate_keyfile.pl <master_key from above> <pass-phrase> > keyfile.h`

5. Build the Docker image: `docker build -t syncthing:encrypt .`

6. Remove the keyfile: `rm keyfile.h`

7. Start syncthing with:
   ```
   docker run --name SyncThing -v $CRYPT_PATH:/var/crypt \
   -p 8384:8384 -p 22000:22000  -p 21027:21027/udp \
   --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
   -e GOCRYPT_KEY=<pass-phrase from step 4> \
   --restart on-failure:5 -d \
   syncthing:encrypt
   ```
 
 8. After configuration, you may want to relaunch docker without exposing port `8384`
    To restrict the addition of unauthorized devices
