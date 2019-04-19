#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <grp.h>
#include "keyfile.h"
// user:nobody
#define EUID 65534
#define EGID 65534

int main()
{
    char *password = getenv("GOCRYPT_KEY");
    if (! password) {
        printf("Must specify $GOCRYPT_KEY\n");
        return 1;
    }
    if( access( "/var/crypt/gocryptfs.conf", F_OK ) == -1 ) {
        printf("/var/crypt does not appear to be a gocryptfs volume\n");
        return 1;
    }

    chown("/var/syncthing", EUID, EGID);
    chmod("/bin/fusermount", 04777);
    gid_t gid = EGID;
    setgroups(1, &gid);
    setgid(EGID);
    setuid(EUID);
    int pid = fork();
    if (! pid) {
        int j = 0;
        for(int i = 0; i < sizeof(key); i++) {
            key[i] = key[i] ^ password[j];
            j++;
            if (password[j] == 0)
                j = 0;
        }
        execl("/gocryptfs", "/gocryptfs", "-masterkey", key, "/var/crypt", "/var/syncthing", NULL);
        for(int i = 0; i < sizeof(key); i++) { key[i] = 0; }
        //unlink("/bin/fusermount");
        return 0;
    }
    int status;
    wait(&status);
    printf("Status: %d\n", status);
    if (status != 0) {
        return 1;
    }
    putenv("HOME=/var/syncthing");
    execl("/syncthing", "/syncthing", "-home", "/var/syncthing/config", "-gui-address", "0.0.0.0:8384", NULL);
}
