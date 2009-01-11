let (|>) x f = f x

type lua_State

type thread_status =
  | LUA_OK
  | LUA_YIELD
  | LUA_ERRRUN
  | LUA_ERRSYNTAX
  | LUA_ERRMEM
  | LUA_ERRERR

let thread_status_of_int = function
  | 0 -> LUA_OK
  | 1 -> LUA_YIELD
  | 2 -> LUA_ERRRUN
  | 3 -> LUA_ERRSYNTAX
  | 4 -> LUA_ERRMEM
  | 5 -> LUA_ERRERR
  | _ -> failwith "thread_status_of_int: unknown status value"

exception Lua_error of thread_status
exception Lua_type_error of string

let _ = Callback.register_exception "Lua type error" (Lua_type_error "")

external lua_open : unit -> lua_State = "lua_open__stub"
external luaL_openlibs : lua_State -> unit = "luaL_openlibs__stub"
external lua_close : lua_State -> unit = "lua_close__stub"
external luaL_loadbuffer__wrapper :
  lua_State -> string -> int -> string -> int = "luaL_loadbuffer__stub"

external lua_pcall__wrapper :
  lua_State -> int -> int -> int -> int = "lua_pcall__stub"

external lua_tolstring__wrapper :
  lua_State -> int -> string = "lua_tolstring__stub"
  (** Raises [Lua_type_error] *)

external lua_pop : lua_State -> int -> unit = "lua_pop__stub"

let luaL_loadbuffer l buff name =
  luaL_loadbuffer__wrapper l buff (String.length buff) name |>
    thread_status_of_int
;;

let lua_pcall l nargs nresults errfunc =
  lua_pcall__wrapper l nargs nresults errfunc |> thread_status_of_int
;;

let lua_tolstring l index =
  lua_tolstring__wrapper l index
;;

let lua_tostring = lua_tolstring;;

let l = lua_open ();;
let () = luaL_openlibs l;;

try
  while true do
    let line = (read_line ()) ^ "\n" in
      try
        match luaL_loadbuffer l line "line" with
          | LUA_OK -> begin
              match lua_pcall l 0 0 0 with
                | LUA_OK -> ()
                | err -> raise (Lua_error err)
            end
          | err -> raise (Lua_error err)
      with
        | Lua_error err -> begin
            Printf.eprintf "%s\n%!" (lua_tostring l (-1));
            lua_pop l 1;
          end
  done;
with End_of_file -> ()

let () = lua_close l

