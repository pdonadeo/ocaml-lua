open Lua_api_lib

external newstate : unit -> state = "luaL_newstate__stub"

external openlibs : Lua_api_lib.state -> unit = "luaL_openlibs__stub"

val loadbuffer : Lua_api_lib.state -> string -> string -> Lua_api_lib.thread_status

val loadfile : Lua_api_lib.state -> string -> Lua_api_lib.thread_status

external newmetatable : state -> string -> bool = "luaL_newmetatable__stub"

external getmetatable : state -> string -> unit = "luaL_getmetatable__stub"

val checkudata : state -> int -> string -> [> `Userdata of 'a | `Light_userdata of 'a ] option

external typerror : state -> int -> string -> 'a = "luaL_typerror__stub"

external checkstring : state -> int -> string = "luaL_checkstring__stub"

val error : state -> ('a, unit, string, 'b) format4 -> 'a                                                             

