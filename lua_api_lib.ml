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
exception Error of thread_status (* TODO add the L state! *)
exception Type_error of string

let _ = Callback.register_exception "Lua_type_error" (Type_error "")
let _ = Callback.register_exception "Not_found" Not_found

(*************)
(* FUNCTIONS *)
(*************)
external lua_atpanic__wrapper :
  state -> oCamlFunction -> oCamlFunction = "lua_atpanic__stub"

let default_panic_function (_ : state) = 0

let atpanic l panicf =
  try lua_atpanic__wrapper l panicf
  with Not_found -> default_panic_function

external call : state -> int -> int -> unit = "lua_call__stub"

external checkstack : state -> int -> bool = "lua_checkstack__stub"


(******************************************************************************)
(******************************************************************************)
(******************************************************************************)
(******************************************************************************)
external lua_open : unit -> state = "lua_open__stub"

external lua_pcall__wrapper :
  state -> int -> int -> int -> int = "lua_pcall__stub"

let pcall l nargs nresults errfunc =
  let ret_status = lua_pcall__wrapper l nargs nresults errfunc |>
    thread_status_of_int in
    match ret_status with
      | LUA_OK -> ()
      | err -> raise (Error err)
;;

external lua_tolstring__wrapper :
  state -> int -> string = "lua_tolstring__stub"
  (** Raises [Type_error] *)

let tolstring l index =
  lua_tolstring__wrapper l index
;;

let tostring = tolstring;;

external pop : state -> int -> unit = "lua_pop__stub"

external error : state -> 'a = "lua_error__stub"

module Exceptionless =
struct
  let pcall l nargs nresults errfunc =
    lua_pcall__wrapper l nargs nresults errfunc |>
      thread_status_of_int

  let tolstring l index =
    try `Ok (lua_tolstring__wrapper l index)
    with Type_error msg -> `Type_error msg

  let tostring = tolstring
end

