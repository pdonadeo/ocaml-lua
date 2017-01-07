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
  | LUA_ERRFILE

type gc_command =
  | GCSTOP
  | GCRESTART
  | GCCOLLECT
  | GCCOUNT
  | GCCOUNTB
  | GCSTEP
  | GCSETPAUSE
  | GCSETSTEPMUL

type lua_type =
  | LUA_TNONE
  | LUA_TNIL
  | LUA_TBOOLEAN
  | LUA_TLIGHTUSERDATA
  | LUA_TNUMBER
  | LUA_TSTRING
  | LUA_TTABLE
  | LUA_TFUNCTION
  | LUA_TUSERDATA
  | LUA_TTHREAD

type 'a lua_Reader = state -> 'a -> string option

type writer_status =
  | NO_WRITING_ERROR  (** No errors, go on writing *)
  | WRITING_ERROR     (** An error occurred, stop writing *)

type 'a lua_Writer = state -> string -> 'a -> writer_status

let thread_status_of_int = function
  | 0 -> LUA_OK
  | 1 -> LUA_YIELD
  | 2 -> LUA_ERRRUN
  | 3 -> LUA_ERRSYNTAX
  | 4 -> LUA_ERRMEM
  | 5 -> LUA_ERRERR
  | 6 -> LUA_ERRFILE
  | _ -> failwith "thread_status_of_int: unknown status value"

let int_of_thread_status = function
  | LUA_OK -> 0
  | LUA_YIELD -> 1
  | LUA_ERRRUN -> 2
  | LUA_ERRSYNTAX -> 3
  | LUA_ERRMEM -> 4
  | LUA_ERRERR -> 5
  | LUA_ERRFILE -> 6

let int_of_gc_command = function
  | GCSTOP -> 0
  | GCRESTART -> 1
  | GCCOLLECT -> 2
  | GCCOUNT -> 3
  | GCCOUNTB -> 4
  | GCSTEP -> 5
  | GCSETPAUSE -> 6
  | GCSETSTEPMUL -> 7

let lua_type_of_int = function
  | -1 -> LUA_TNONE
  |  0 -> LUA_TNIL
  |  1 -> LUA_TBOOLEAN
  |  2 -> LUA_TLIGHTUSERDATA
  |  3 -> LUA_TNUMBER
  |  4 -> LUA_TSTRING
  |  5 -> LUA_TTABLE
  |  6 -> LUA_TFUNCTION
  |  7 -> LUA_TUSERDATA
  |  8 -> LUA_TTHREAD
  |  _ -> failwith "lua_type_of_int: unknown type"

let int_of_lua_type = function
  | LUA_TNONE -> -1
  | LUA_TNIL -> 0
  | LUA_TBOOLEAN -> 1
  | LUA_TLIGHTUSERDATA -> 2
  | LUA_TNUMBER -> 3
  | LUA_TSTRING -> 4
  | LUA_TTABLE -> 5
  | LUA_TFUNCTION -> 6
  | LUA_TUSERDATA -> 7
  | LUA_TTHREAD -> 8

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
exception Not_a_Lua_thread
exception Not_a_block_value


(*************)
(* FUNCTIONS *)
(*************)
external tolstring__wrapper : state -> int -> string = "lua_tolstring__stub"
  (** Raises [Type_error] *)

let tolstring ls index =
  try Some (tolstring__wrapper ls index)
  with Type_error _ -> None

let tostring = tolstring

external pushlstring : state -> string -> unit = "lua_pushlstring__stub"

let pushstring = pushlstring

(* This is the "porting" of the standard panic function from Lua source:
   lua-5.1.4/src/lauxlib.c line 639 *)
let default_panic (ls : state) =
  let msg = tostring ls (-1) in
  let () =
    match msg with
    | Some msg -> Printf.fprintf stderr "PANIC: unprotected error in call to Lua API (%s)\n%!" msg;
    | None -> failwith "default_panic: impossible pattern: this error shoud never be raised" in
  0

external atpanic : state -> oCamlFunction -> oCamlFunction = "lua_atpanic__stub"

external call : state -> int -> int -> unit = "lua_call__stub"

external checkstack : state -> int -> bool = "lua_checkstack__stub"

external concat : state -> int -> unit = "lua_concat__stub"

external pushcfunction : state -> oCamlFunction -> unit = "lua_pushcfunction__stub"

external pushlightuserdata : state -> 'a -> unit = "lua_pushlightuserdata__stub"

external lua_pcall__wrapper : state -> int -> int -> int -> int = "lua_pcall__stub"

let pcall ls nargs nresults errfunc =
  lua_pcall__wrapper ls nargs nresults errfunc |> thread_status_of_int

exception Memory_allocation_error

let cpcall ls func ud =
  let cpcall_panic ls = raise Memory_allocation_error in
  let old_panic = atpanic ls cpcall_panic in
  try
    match checkstack ls 2 with (* ALLOCATES MEMORY, COULD FAIL! *)
    | true -> begin
        pushcfunction ls func;
        pushlightuserdata ls ud; (* ALLOCATES MEMORY, COULD FAIL! *)
        let _ = atpanic ls old_panic in
        pcall ls 1 0 0
      end
    | false ->
        let _ = atpanic ls old_panic in
        LUA_ERRMEM
  with
  | Memory_allocation_error ->
      let _ = atpanic ls old_panic in
      LUA_ERRMEM
  | e -> 
      let _ = atpanic ls old_panic in
      raise e

external createtable : state -> int -> int -> unit = "lua_createtable__stub"

external dump : state -> 'a lua_Writer -> 'a -> writer_status = "lua_dump__stub"

external equal : state -> int -> int -> bool = "lua_equal__stub"

external error : state -> 'a = "lua_error__stub"

external gc_wrapper : state -> int -> int -> int = "lua_gc__stub"
let gc ls what data =
  let what = int_of_gc_command what in
    gc_wrapper ls what data

external getfenv : state -> int -> unit = "lua_getfenv__stub"

external getfield : state -> int -> string -> unit = "lua_getfield__stub"

let getglobal ls name = getfield ls globalsindex name

external getmetatable : state -> int -> bool = "lua_getmetatable__stub"

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

external lua_load__wrapper : state -> 'a lua_Reader -> 'a -> string -> int = "lua_load__stub"

let load ls reader data chunkname =
  lua_load__wrapper ls reader data chunkname |> thread_status_of_int

external newtable: state -> unit = "lua_newtable__stub"

external newthread : state -> state = "lua_newthread__stub"

external default_gc : state -> int = "default_gc__stub"

let make_gc_function user_gc_function =
  let new_gc ls =
    let res = user_gc_function ls in
    let _ = default_gc ls in
    res in
  new_gc

external newuserdata : state -> 'a -> unit = "lua_newuserdata__stub"

external next : state -> int -> int = "lua_next__stub"

external objlen : state -> int -> int = "lua_objlen__stub"

external pop : state -> int -> unit = "lua_pop__stub"

external pushboolean : state -> bool -> unit = "lua_pushboolean__stub"

let pushocamlfunction = pushcfunction

let pushfstring (state : state) =
  let k s = pushstring state s; s in
    Printf.kprintf k

external pushinteger : state -> int -> unit = "lua_pushinteger__stub"

external pushliteral : state -> string -> unit = "lua_pushlstring__stub"

external pushnil : state -> unit = "lua_pushnil__stub"

external pushnumber : state -> float -> unit = "lua_pushnumber__stub"

external pushthread : state -> bool = "lua_pushthread__stub"

external pushvalue : state -> int -> unit = "lua_pushvalue__stub"

let pushvfstring = pushfstring

external rawequal : state -> int -> int -> bool = "lua_rawequal__stub"

external rawget : state -> int -> unit = "lua_rawget__stub"

external rawgeti : state -> int -> int -> unit = "lua_rawgeti__stub"

external rawset : state -> int -> unit = "lua_rawset__stub"

external rawseti : state -> int -> int -> unit = "lua_rawseti__stub"

external setglobal : state -> string -> unit = "lua_setglobal__stub"

let register ls name f =
  pushcfunction ls f;
  setglobal ls name

external remove : state -> int -> unit = "lua_remove__stub"

external replace : state -> int -> unit = "lua_replace__stub"

external lua_resume__wrapper : state -> int -> int = "lua_resume__stub"

let resume ls narg =
  lua_resume__wrapper ls narg |> thread_status_of_int

external setfenv : state -> int -> bool = "lua_setfenv__stub"

external setfield : state -> int -> string -> unit = "lua_setfield__stub"

external setmetatable : state -> int -> int = "lua_setmetatable__stub"

external settable : state -> int -> unit = "lua_settable__stub"

external settop : state -> int -> unit = "lua_settop__stub"

external status_aux : state -> int = "lua_status__stub"

let status ls = ls |> status_aux |> thread_status_of_int

external toboolean : state -> int -> bool = "lua_toboolean__stub"

external tocfunction_aux : state -> int -> oCamlFunction = "lua_tocfunction__stub"

let tocfunction ls index =
  try Some (tocfunction_aux ls index)
  with Not_a_C_function -> None

let toocamlfunction = tocfunction

external tointeger : state -> int -> int = "lua_tointeger__stub"

external tonumber : state -> int -> float = "lua_tonumber__stub"

external tothread_aux : state -> int -> state = "lua_tothread__stub"

let tothread ls index =
  try Some (tothread_aux ls index)
  with Not_a_Lua_thread -> None

external touserdata_aux : state -> int -> 'a = "lua_touserdata__stub"

let touserdata ls index =
  if      islightuserdata ls index then (Some (`Light_userdata (touserdata_aux ls index)))
  else if isuserdata      ls index then (Some (`Userdata (touserdata_aux ls index)))
  else None

external lua_type_wrapper : state -> int -> int = "lua_type__stub"

let type_ state index =
  lua_type_wrapper state index |> lua_type_of_int

let typename _ = function
  | LUA_TNONE -> "no value"
  | LUA_TNIL -> "nil"
  | LUA_TBOOLEAN -> "boolean"
  | LUA_TLIGHTUSERDATA -> "userdata"
  | LUA_TNUMBER -> "number"
  | LUA_TSTRING -> "string"
  | LUA_TTABLE -> "table"
  | LUA_TFUNCTION -> "function"
  | LUA_TUSERDATA -> "userdata"
  | LUA_TTHREAD -> "thread"

external xmove : state -> state -> int -> unit = "lua_xmove__stub"

external yield : state -> int -> int = "lua_yield__stub"

let init =
  lazy (
    Callback.register_exception "Lua_type_error" (Type_error "");
    Callback.register_exception "Not_a_C_function" Not_a_C_function;
    Callback.register_exception "Not_a_Lua_thread" Not_a_Lua_thread;
    Callback.register_exception "Not_a_block_value" Not_a_block_value;
    Callback.register "default_panic" default_panic;
  )
;;
