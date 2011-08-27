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

external newmetatable : state -> string -> bool = "luaL_newmetatable__stub"

external getmetatable : state -> string -> unit = "luaL_getmetatable__stub"

external typerror : state -> int -> string -> 'a = "luaL_typerror__stub"

(* checkudata is not a binding of luaL_checkudata (see:
 * http://www.lua.org/manual/5.1/manual.html#luaL_checkudata), it's actually a porting of the
 * function implementd in the Lua auxiliary library, in lauxlib.c, line 124, of the official
 * distrubution of Lua.
 *)
let checkudata l ud tname =
  let te = lazy (typerror l ud tname) in
  let p = touserdata l ud in
  match p with
  | Some data -> begin
      if (Lua_api_lib.getmetatable l ud) then begin
        getfield l registryindex tname;
        if (rawequal l (-1) (-2))
        then (pop l 2; p)
        else Lazy.force te
      end else Lazy.force te
    end
  | None -> Lazy.force te
;;

external checkstring : state -> int -> string = "luaL_checkstring__stub"

external error__wrapper : state -> string -> 'a = "luaL_error__stub"

let error (state : state) =
  let k s = error__wrapper state s in
  Printf.kprintf k
;;

