open Lua_api_lib

val ( |> ) : 'a -> ('a -> 'b) -> 'b
external newstate : unit -> state = "luaL_newstate__stub"
external openlibs : Lua_api_lib.state -> unit = "luaL_openlibs__stub"
external luaL_loadbuffer__wrapper :
  Lua_api_lib.state -> string -> int -> string -> int
  = "luaL_loadbuffer__stub"
val loadbuffer : Lua_api_lib.state -> string -> string -> unit
module Exceptionless :
  sig
    val loadbuffer :
      Lua_api_lib.state -> string -> string -> Lua_api_lib.thread_status
  end
