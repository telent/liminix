#include <stdlib.h>
#include <string.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include "fetch.h"

/*
  FIXME: "By default libfetch allows TLSv1 and newer when negotiating
  the connecting with the remote peer.  You can change this behavior
  by setting the SSL_NO_TLS1, SSL_NO_TLS1_1 and SSL_NO_TLS1_2
  environment variables to disable TLS 1.0, 1.1 and 1.2 respectively."
*/

int lp_error(lua_State *L, int code, char *message) {
    lua_pushnil(L);
    lua_pushinteger(L, code);
    lua_pushlstring(L, message, strlen(message));
    return 3;
}

int lp_fetched(lua_State *L, FXRETTYPE fp, struct url_stat *stat) {
    size_t bytes_read = 0;
    char * content = 0;
    if(stat->size > 0) {
	content = (char *) malloc(stat->size);
	es_read(fp, content,  stat->size, &bytes_read);

	if(bytes_read != stat->size) {
	    lp_error(L, -1, "bytes read does not match content-length");
	}
    } else {
	/* no content-length header */
	int block_size = 128;
	int buf_size = block_size;
	size_t bytes_read_block;
	do {
	    content = (char *) realloc(content, buf_size);
	    es_read(fp, content + bytes_read,  block_size, &bytes_read_block);
	    bytes_read += bytes_read_block;
	    buf_size += block_size;
	} while(bytes_read_block > 0);
    }

    lua_pushlstring(L, (const char *) content, bytes_read);
    lua_newtable(L);
    lua_pushliteral(L, "last-modified");
    lua_pushinteger(L, stat->mtime);
    lua_settable(L, -3);
    /* free(content) ? */
    return 2;
}

int lp_fetch(lua_State *L) {
    const char * url_string = luaL_checkstring(L, 1);
    const char * flags = luaL_optstring(L, 2, "");
    time_t if_modified_since = luaL_optinteger(L, 3, 0);

    struct url *url = fetchParseURL(url_string);
    if(url == NULL) {
	return lp_error(L, -1, "url not parseable");
    }
    url->ims_time = if_modified_since;
    struct url_stat stat;

    FXRETTYPE fp = fetchXGet(url, &stat, flags);
    fetchFreeURL(url);
    if(fp == NULL) {
	return lp_error(L, fetchLastErrCode, fetchLastErrString);
    }
    return lp_fetched(L, fp, &stat);
}

/* http_request_body seems to be semi-private in libfetch, but if using
 * only the fetch* functions there's no way to send an http request
 * with a body, so we use it anyway
 */
extern FXRETTYPE
http_request_body(struct url *URL, const char *op, struct url_stat *us,
		  struct url *purl, const char *flags, const char *content_type,
		  const char *body);

int lp_request(lua_State *L) {
    const char * request_method = luaL_checkstring(L, 1);
    const char * url_string = luaL_checkstring(L, 2);
    const char * flags = luaL_optstring(L, 3, "");
    time_t if_modified_since = luaL_optinteger(L, 4, 0);
    const char * content_type = lua_tostring(L, 5);
    const char * body = lua_tostring(L, 6);

    struct url *url = fetchParseURL(url_string);
    if(url == NULL) {
	return lp_error(L, -1, "url not parseable");
    }
    url->ims_time = if_modified_since;
    struct url_stat stat;

    FXRETTYPE fp = http_request_body(url,
				     request_method,
				     &stat,
				     NULL, /* no proxy */
				     flags,
				     content_type,
				     body);
    fetchFreeURL(url);
    if(fp == NULL) {
	return lp_error(L, fetchLastErrCode, fetchLastErrString);
    }
    return lp_fetched(L, fp, &stat);
}

static const struct luaL_Reg funcs [] = {
    {"fetch", lp_fetch},
    {"request", lp_request},
    {NULL, NULL}  /* sentinel */
};


int luaopen_fetch (lua_State *L) {
    luaL_newlib(L, funcs);
    return 1;
}
