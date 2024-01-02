CFLAGS=$(INC) -D_LINUX_TYPES_H -D_LINUX_STRING_H_

fw_printenv: fw_env_main.o fw_env.o \
        crc32.o ctype.o linux_string.o \
        env_attr.o env_flags.o
	$(CC) -o $@ $^
