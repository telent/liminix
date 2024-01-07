struct root_opts {
    char *device;
    char *fstype;
    char *mount_opts;
};

void parseopts(char * cmdline, struct root_opts *opts);
