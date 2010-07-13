(*******************************)
(* COMMON FUNCTIONAL OPERATORS *)
(*******************************)
let (|>) x f = f x

type state

type oCamlFunction = state -> int

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

let int_of_thread_status = function
  | LUA_OK -> 0
  | LUA_YIELD -> 1
  | LUA_ERRRUN -> 2
  | LUA_ERRSYNTAX -> 3
  | LUA_ERRMEM -> 4
  | LUA_ERRERR -> 5
  
let lua_multret : int = -1


(**************)
(* EXCEPTIONS *)
(**************)
exception Error of thread_status
exception Type_error of string

let _ = Callback.register_exception "Lua_type_error" (Type_error "")

(*************)
(* FUNCTIONS *)
(*************)
external tolstring : state -> int -> string = "lua_tolstring__stub"
  (** Raises [Type_error] *)

let tostring = tolstring

external pushlstring : state -> string -> unit = "lua_pushlstring__stub"

let pushstring = pushlstring

(* This is the "porting" of the standard panic function from Lua source:
   lua-5.1.4/src/lauxlib.c line 639 *)
let default_panic (l : state) =
  Printf.fprintf stderr "PANIC: unprotected error in call to Lua API (%s)\n%!" (tostring l (-1));
  0

let _ = Callback.register "default_panic" default_panic

external atpanic : state -> oCamlFunction -> oCamlFunction = "lua_atpanic__stub"

external call : state -> int -> int -> unit = "lua_call__stub"

external checkstack : state -> int -> bool = "lua_checkstack__stub"


(******************************************************************************)
(******************************************************************************)
(******************************************************************************)
(******************************************************************************)
external lua_pcall__wrapper :
  state -> int -> int -> int -> int = "lua_pcall__stub"

let pcall l nargs nresults errfunc =
  let ret_status = lua_pcall__wrapper l nargs nresults errfunc |>
    thread_status_of_int in
    match ret_status with
      | LUA_OK -> ()
      | err -> raise (Error err)
;;

external pop : state -> int -> unit = "lua_pop__stub"

external error : state -> 'a = "lua_error__stub"

module Exceptionless =
struct
  let pcall l nargs nresults errfunc =
    lua_pcall__wrapper l nargs nresults errfunc |>
      thread_status_of_int

  let tolstring l index =
    try `Ok (tolstring l index)
    with Type_error msg -> `Type_error msg

  let tostring = tolstring
end

