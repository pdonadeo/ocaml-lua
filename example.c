#include <stdio.h>
#include <string.h>
#include <lua5.1/lua.h>
#include <lua5.1/lauxlib.h>
#include <lua5.1/lualib.h>

/* COMPILE WITH:
        gcc -Wall -pedantic-errors -ansi \
            -llua5.1 \
            example.c \
            -o example
 */
    
int main(void)
{
    char buff[256];
    int error;
    lua_State *L = lua_open();  /* opens Lua */
    luaL_openlibs(L);           /* open standard libraries */

    while (fgets(buff, sizeof(buff), stdin) != NULL)
    {
        error = luaL_loadbuffer(L, buff, strlen(buff), "line") ||
                lua_pcall(L, 0, 0, 0);
        if (error)
        {
            fprintf(stderr, "%s\n", lua_tostring(L, -1));
            lua_pop(L, 1);  /* pop error message from the stack */
        }
    }

    lua_close(L);
    return 0;
}

