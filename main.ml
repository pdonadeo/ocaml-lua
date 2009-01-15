let (|>) x f = f x

type lua_State

type lua_OCamlFunction = lua_State -> int

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

exception Lua_error of thread_status (* TODO aggiungere lo stato L! *)
exception Lua_type_error of string
exception Lua_exception

let _ = Callback.register_exception "Lua type error" (Lua_type_error "")
let _ = Callback.register_exception "Not_found" Not_found

external lua_open : unit -> lua_State = "lua_open__stub"
external luaL_openlibs : lua_State -> unit = "luaL_openlibs__stub"
external luaL_loadbuffer__wrapper :
  lua_State -> string -> int -> string -> int = "luaL_loadbuffer__stub"

external lua_pcall__wrapper :
  lua_State -> int -> int -> int -> int = "lua_pcall__stub"

external lua_tolstring__wrapper :
  lua_State -> int -> string = "lua_tolstring__stub"
  (** Raises [Lua_type_error] *)

external lua_atpanic__wrapper :
  lua_State -> lua_OCamlFunction -> lua_OCamlFunction = "lua_atpanic__stub"

external lua_pop : lua_State -> int -> unit = "lua_pop__stub"

external lua_error : lua_State -> unit = "lua_error__stub"

let luaL_loadbuffer l buff name =
  let ret_status = luaL_loadbuffer__wrapper l buff (String.length buff) name |>
    thread_status_of_int in
    match ret_status with
      | LUA_OK -> ()
      | err -> raise (Lua_error err)
;;

let default_panic_function l = 0;;

let lua_atpanic l panicf =
  try lua_atpanic__wrapper l panicf
  with Not_found -> default_panic_function
;;


let lua_pcall l nargs nresults errfunc =
  let ret_status = lua_pcall__wrapper l nargs nresults errfunc |>
    thread_status_of_int in
    match ret_status with
      | LUA_OK -> ()
      | err -> raise (Lua_error err)
;;

let lua_tolstring l index =
  lua_tolstring__wrapper l index
;;

let lua_tostring = lua_tolstring;;

module Exceptionless =
struct
  let lua_tolstring l index =
    try `Ok (lua_tolstring__wrapper l index)
    with Lua_type_error msg -> `Lua_type_error msg

  let lua_tostring = lua_tolstring

  let luaL_loadbuffer l buff name =
    luaL_loadbuffer__wrapper l buff (String.length buff) name |>
      thread_status_of_int

  let lua_pcall l nargs nresults errfunc =
    lua_pcall__wrapper l nargs nresults errfunc |>
      thread_status_of_int
end


(*
(**** ESEMPIO 1 ***************************************************************)
let l = lua_open ();;
let () = luaL_openlibs l;;

try
  while true do
    let line = (read_line ()) ^ "\n" in
      try
        luaL_loadbuffer l line "line";
        lua_pcall l 0 0 0;
(*         lua_error l; *)
      with
        | Lua_error err -> begin
            Printf.printf "%s\n%!" (lua_tostring l (-1));
            lua_pop l 1;
          end
  done;
with End_of_file -> ()

(******************************************************************************)
*)


(**** ESEMPIO 2 ***************************************************************)
let conta = ref 0;;

let panicf1 l =
  Printf.printf "panicf1: %d\n%!" !conta;
  raise Lua_exception
;;

let closure () =
  let l1 = lua_open () in
  let l2 = lua_open () in
    try
      let n = Random.int 1024*1024 in
      let str = String.create n in
      let panicf2 l =
        ignore str;
        Printf.printf "panicf2: %d\n%!" !conta;
        raise Lua_exception in
      let n = Random.int 2 in
      let f = match n with | 0 -> panicf1 | 1 -> panicf2 | _ -> failwith "IMPOSSIBILE" in
        lua_atpanic l1 f |> ignore;
        lua_atpanic l2 f |> ignore;
        luaL_openlibs l1;
        luaL_openlibs l2;
        luaL_loadbuffer l1 "a = 42\nb = 43\nc = a + b\n-- print(c)" "line";
        luaL_loadbuffer l2 "a = 42\nb = 43\nc = a + b\n-- print(c)" "line";
        lua_pcall l1 0 0 0;
        lua_pcall l2 0 0 0;
        let n = Random.int 2 in
          match n with | 0 -> lua_error l1 | 1 -> lua_error l2 | _ -> failwith "IMPOSSIBILE"
    with
      | Lua_error err -> begin
            Printf.printf "%s\n%!" (lua_tostring l1 (-1));
            lua_pop l1 1;
            failwith "FATAL ERROR"
          end;
;;

let sleep_float n =
  let _ = Unix.select [] [] [] n in ()
;;

while true do
  let () = try closure () with Lua_exception -> () in
(*   Gc.minor (); *)
(*   Gc.major_slice 0 |> ignore; *)
(*   Gc.major (); *)
(*   Gc.compact (); *)
  conta := !conta + 1;
  sleep_float (1./.((Random.float 900.0) +. 100.));
done;;
(******************************************************************************)

