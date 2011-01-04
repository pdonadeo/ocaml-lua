open Lua_api_lib

external newstate : unit -> state = "luaL_newstate__stub"

external openlibs : Lua_api_lib.state -> unit = "luaL_openlibs__stub"

val loadbuffer : Lua_api_lib.state -> string -> string -> Lua_api_lib.thread_status

val loadfile : Lua_api_lib.state -> string -> Lua_api_lib.thread_status

