#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>

typedef char hash_t[32];
hash_t *hash_list = NULL;
int hash_list_entries = 0;
int hash_list_size = 0;

int add_list_entry(char *name)
{
    name += strlen("/nix/store/");
    if(hash_list_entries >= hash_list_size) {
	if(hash_list_size == 0) hash_list_size =  4;
	hash_list_size = hash_list_size * 2;
	hash_list = realloc(hash_list, hash_list_size * sizeof(hash_t));
    }
    strncpy(hash_list[hash_list_entries++], name, 32);
}

int read_list(char *filename)
{
    char s[1024];
    FILE *fp;
    if(fp = fopen(filename, "r")) {
	while(fgets(s, 1024, fp)) {
	    if(strrchr(s, '\n')) {
		add_list_entry(s);
	    } else {
		puts("hash list entry too long");
		exit(1);
	    }
	}
    }
    fclose(fp);
}

int on_list(char *name)
{
    int i;
    for(i = 0; i < hash_list_entries; i++) {
	if(!strncmp(hash_list[i], name, 32)) {
	    return 1;
	}
    }
    return 0;
}

int main(int argc, char * argv[])
{
    struct dirent * de;
    DIR  * dirp;
    char hash[32];

    if(argc < 2) {
	puts("Usage: min-list-garbage store-paths-file\n\nChecks all store paths against the list of expected paths in store-paths-file,\n and prints any which are present unexpectedly");
	exit(1);
    }

    read_list(argv[1]);
    
    if((dirp = opendir("/nix/store")) == NULL) {
	puts("can't open /nix/store");
	exit(1);
    }

     while(de = readdir(dirp)) {
	if(strlen(de->d_name) >= 32) {
	    strncpy(hash, de->d_name, 32);
	    if(!on_list(hash)) puts(de->d_name);
	}
    }

    closedir(dirp);
}
