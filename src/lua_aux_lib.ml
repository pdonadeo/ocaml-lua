open Lua_api_lib

let (|>) x f = f x

external newstate : unit -> state = "luaL_newstate__stub"

external openlibs : state -> unit = "luaL_openlibs__stub"

external luaL_loadbuffer__wrapper :
  state -> string -> int -> string -> int = "luaL_loadbuffer__stub"

let loadbuffer l buff name =
  luaL_loadbuffer__wrapper l buff (String.length buff) name |> thread_status_of_int
;;

external luaL_loadfile__wrapper : state -> string -> int = "luaL_loadfile__stub"

let loadfile l filename =
  luaL_loadfile__wrapper l filename |> thread_status_of_int
;;

