#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <linux/netlink.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int l_close_socket(lua_State *L) {
    lua_getfield(L, 1, "fileno");
    int fd = (int) lua_tointeger(L, -1);
    close(fd);
    return 0;
}

static int l_read_from_socket(lua_State *L) {
    int length = 32;

    if(lua_isnumber(L, 2))
	length = lua_tointeger(L, 2);

    lua_getfield(L, 1, "fileno");
    int fd = (int) lua_tointeger(L, -1);
    char *buf = (char *) malloc(length);
    int bytes = recv(fd, buf, length, 0);

    if(bytes > 0) {
	lua_pushlstring(L, buf, bytes);
	free(buf);
	return 1;
    } else {
	free(buf);
	return 0;
    }
}

static int l_open_socket(lua_State *L) {
    int netlink_fd = socket(AF_NETLINK, SOCK_RAW|SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);

    struct sockaddr_nl sa;
    memset(&sa, 0, sizeof(sa));
    sa.nl_family = AF_NETLINK;
    sa.nl_pid = getpid();

    if(lua_isnumber(L, 1)) {
	sa.nl_groups = lua_tointeger(L, 1);
	lua_pop(L, 1);
    }
    else {
	sa.nl_groups = 4; 		/* group 4 is rebroadcasts from mdevd */
    }

    if(bind(netlink_fd, (struct sockaddr *) &sa, sizeof(sa))==0) {
	lua_newtable(L);

	lua_pushliteral(L, "fileno");
	lua_pushinteger(L, netlink_fd);
	lua_settable(L, 1);

	lua_pushliteral(L, "read");
	lua_pushcfunction(L, l_read_from_socket);
	lua_settable(L, 1);

	lua_pushliteral(L, "close");
	lua_pushcfunction(L, l_close_socket);
	lua_settable(L, 1);

	return 1;
    } else {
	return 0;
    }
}


static const struct luaL_Reg funcs [] = {
    {"open", l_open_socket},
    {NULL, NULL}  /* sentinel */
};


/* "luaopen_" prefix is magic and tells lua to run this function
 * when it dlopens the library
 */

int luaopen_nellie (lua_State *L) {
    luaL_newlib(L, funcs);
    return 1;
}
