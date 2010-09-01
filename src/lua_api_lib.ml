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
exception Not_a_C_function

let _ = Callback.register_exception "Lua_type_error" (Type_error "")
let _ = Callback.register_exception "Not_a_C_function" Not_a_C_function

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

external isboolean : state -> int -> bool = "lua_isboolean__stub"

external iscfunction : state -> int -> bool = "lua_iscfunction__stub"

external isfunction : state -> int -> bool = "lua_isfunction__stub"

external islightuserdata : state -> int -> bool = "lua_islightuserdata__stub"

external isnil : state -> int -> bool = "lua_isnil__stub"

external isnone : state -> int -> bool = "lua_isnone__stub"

external isnoneornil : state -> int -> bool = "lua_isnoneornil__stub"

external isnumber : state -> int -> bool = "lua_isnumber__stub"

external isstring : state -> int -> bool = "lua_isstring__stub"

external istable : state -> int -> bool = "lua_istable__stub"

external isthread : state -> int -> bool = "lua_isthread__stub"

external isuserdata : state -> int -> bool = "lua_isuserdata__stub"

external lessthan : state -> int -> int -> bool = "lua_lessthan__stub"

(* TODO lua_load *)

external newtable: state -> int -> int -> bool = "lua_newtable__stub"

(* TODO lua_newthread *)

(* TODO lua_newuserdata *)

external next : state -> int -> int = "lua_next__stub"

external objlen : state -> int -> int = "lua_objlen__stub"

external lua_pcall__wrapper : state -> int -> int -> int -> int = "lua_pcall__stub"

let pcall l nargs nresults errfunc =
  lua_pcall__wrapper l nargs nresults errfunc |> thread_status_of_int

external pop : state -> int -> unit = "lua_pop__stub"

external pushboolean : state -> bool -> unit = "lua_pushboolean__stub"

external pushcfunction : state -> oCamlFunction -> unit = "lua_pushcfunction__stub"

let pushocamlfunction = pushcfunction

let pushfstring (state : state) =
  let k s = pushstring state s; s in
    Printf.kprintf k

external pushinteger : state -> int -> unit = "lua_pushinteger__stub"

(* TODO lua_pushlightuserdata *)

external pushliteral : state -> string -> unit = "lua_pushlstring__stub"

external pushnil : state -> unit = "lua_pushnil__stub"

external pushnumber : state -> float -> unit = "lua_pushnumber__stub"

(* TODO lua_pushthread *)

external pushvalue : state -> int -> unit = "lua_pushvalue__stub"

let pushvfstring = pushfstring

external rawequal : state -> int -> int -> bool = "lua_rawequal__stub"

external rawget : state -> int -> unit = "lua_rawget__stub"

external rawgeti : state -> int -> int -> unit = "lua_rawgeti__stub"

external rawset : state -> int -> unit = "lua_rawset__stub"

external rawseti : state -> int -> int -> unit = "lua_rawseti__stub"

external setglobal : state -> string -> unit = "lua_setglobal__stub"

let register l name f =
  pushcfunction l f;
  setglobal l name

external remove : state -> int -> unit = "lua_remove__stub"

external replace : state -> int -> unit = "lua_replace__stub"

(* TODO lua_resume *)

external setfenv : state -> int -> bool = "lua_setfenv__stub"

external setfield : state -> int -> string -> unit = "lua_setfield__stub"

external setmetatable : state -> int -> int = "lua_setmetatable__stub"

external settable : state -> int -> int = "lua_settable__stub"

external settop : state -> int -> int = "lua_settop__stub"

external status_aux : state -> int = "lua_status__stub"

let status l = l |> status_aux |> thread_status_of_int

external toboolean : state -> int -> bool = "lua_toboolean__stub"

external tocfunction_aux : state -> int -> oCamlFunction = "lua_tocfunction__stub"

let tocfunction l index =
  try Some (tocfunction_aux l index)
  with Not_a_C_function -> None

