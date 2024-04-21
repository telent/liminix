struct root_opts {
    char *device;
    char *altdevice; /* For A/B schemas */
    char *fstype;
    char *mount_opts;
};

void parseopts(char * cmdline, struct root_opts *opts);
