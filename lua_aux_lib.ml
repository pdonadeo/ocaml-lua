open Lua_api_lib

let (|>) x f = f x

external newstate : unit -> state = "luaL_newstate__stub"

external openlibs : state -> unit = "luaL_openlibs__stub"

external luaL_loadbuffer__wrapper :
  state -> string -> int -> string -> int = "luaL_loadbuffer__stub"

let loadbuffer l buff name =
  let ret_status = luaL_loadbuffer__wrapper l buff (String.length buff) name |>
    thread_status_of_int in
    match ret_status with
      | LUA_OK -> ()
      | err -> raise (Error err)
;;

module Exceptionless =
struct
  let loadbuffer l buff name =
    luaL_loadbuffer__wrapper l buff (String.length buff) name |>
      thread_status_of_int

end

