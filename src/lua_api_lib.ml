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

type alloc (* TODO placeholder, not use, to be removed? *)

type gc_command =
  | GCSTOP
  | GCRESTART
  | GCCOLLECT
  | GCCOUNT
  | GCCOUNTB
  | GCSTEP
  | GCSETPAUSE
  | GCSETSTEPMUL

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

let int_of_gc_command = function
  | GCSTOP -> 0
  | GCRESTART -> 1
  | GCCOLLECT -> 2
  | GCCOUNT -> 3
  | GCCOUNTB -> 4
  | GCSTEP -> 5
  | GCSETPAUSE -> 6
  | GCSETSTEPMUL -> 7
  
let multret = -1
let registryindex = -10000
let environindex = -10001
let globalsindex = -10002


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

external concat : state -> int -> unit = "lua_concat__stub"

(* TODO lua_cpcall *)

external createtable : state -> int -> int -> unit = "lua_createtable__stub"

(* TODO lua_dump *)

external equal : state -> int -> int -> bool = "lua_equal__stub"

external error : state -> 'a = "lua_error__stub"

external gc_wrapper : state -> int -> int -> int = "lua_gc__stub"
let gc l what data =
  let what = int_of_gc_command what in
    gc_wrapper l what data

external getfenv : state -> int -> unit = "lua_getfenv__stub"

external getfield : state -> int -> string -> unit = "lua_getfield__stub"

let getglobal l name = getfield l globalsindex name

external getmetatable : state -> int -> int = "lua_getmetatable__stub"

external gettable : state -> int -> unit = "lua_gettable__stub"

external gettop : state -> int = "lua_gettop__stub"

external insert : state -> int -> unit = "lua_insert__stub"

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


