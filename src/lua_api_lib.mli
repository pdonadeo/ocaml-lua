(**************************************************************)
(** {1 The Lua Application Program Interface (OCaml binding)} *)
(**************************************************************)

(*********************************************)
(** {2 Difference with the original Lua API} *)
(*********************************************)

(** Here is a list of functions of which you should read documentation:
- {b Missing functions}: [lua_close], [lua_getallocf], [lua_newstate]
(see below {{:#VALload}here}), [lua_pushcclosure] (see below {{:#VALpushboolean}here}),
[lua_setallocf], [lua_topointer].
- {b Notably different functions}: {!newuserdata}, {!pushfstring}, {!pushlightuserdata},
{!touserdata}
- {b Special remarks}: {!cpcall}, {!newthread}, {!default_gc}, {!make_gc_function}.
{!tolstring}
*)

(**************************)
(** {2 Types definitions} *)
(**************************)

(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_State}lua_State}
    documentation. *)
type state

(** This type corresponds to lua_CFunction. See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_CFunction}lua_CFunction}
    documentation. *)
type oCamlFunction = state -> int

(** See {{:http://www.lua.org/manual/5.1/manual.html#pdf-LUA_YIELD}lua_status}
    documentation. *)
type thread_status =
  | LUA_OK
  | LUA_YIELD
  | LUA_ERRRUN
  | LUA_ERRSYNTAX
  | LUA_ERRMEM
  | LUA_ERRERR
  | LUA_ERRFILE

(** This type is not present in the official API and is used by the function
    [gc] *)
type gc_command =
  | GCSTOP
  | GCRESTART
  | GCCOLLECT
  | GCCOUNT
  | GCCOUNTB
  | GCSTEP
  | GCSETPAUSE
  | GCSETSTEPMUL

(** This type is a collection of the possible types of a Lua value, as defined
    by the macros in lua.h. As a reference, see the documentation of the 
    {{:http://www.lua.org/manual/5.1/manual.html#lua_type}lua_type function},
    and the corresponding OCaml {!Lua_api_lib.type_}. *)
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

(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_Reader}lua_Reader}
    documentation. *)
type 'a lua_Reader = state -> 'a -> string option

type writer_status =
  | NO_WRITING_ERROR  (** No errors, go on writing *)
  | WRITING_ERROR     (** An error occurred, stop writing *)

(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_Writer}lua_Writer}
    documentation. *)
type 'a lua_Writer = state -> string -> 'a -> writer_status

(************************)
(** {2 Constant values} *)
(************************)

val multret : int
(** Option for multiple returns in `Lua.pcall' and `Lua.call'.
    See {{:http://www.lua.org/manual/5.1/manual.html#lua_call}lua_call}
    documentation. *)

val registryindex : int
(** Pseudo-index to access the registry.
    See {{:http://www.lua.org/manual/5.1/manual.html#3.5}Registry} documentation. *)

val environindex : int
(** Pseudo-index to access the environment of the running C function.
    See {{:http://www.lua.org/manual/5.1/manual.html#3.3}Registry} documentation. *)

val globalsindex : int
(** Pseudo-index to access the thread environment (where global variables live).
    See {{:http://www.lua.org/manual/5.1/manual.html#3.3}Registry} documentation. *)


(*******************)
(** {2 Exceptions} *)
(*******************)

exception Error of thread_status
exception Type_error of string

(*********************************************)
(** {2 Functions not present in the Lua API} *)
(*********************************************)

val thread_status_of_int : int -> thread_status
(** Convert an integer into a [thread_status]. Raises [failure] on
    invalid parameter. *)

val int_of_thread_status : thread_status -> int
(** Convert a [thread_status] into an integer. *)

val lua_type_of_int : int -> lua_type
(** Convert an integer into a [lua_type]. Raises [failure] on
    invalid parameter. *)

val int_of_lua_type : lua_type -> int
(** Convert a [lua_type] into an integer. *)

(**************************)
(** {2 Lua API functions} *)
(**************************)

external atpanic : state -> oCamlFunction -> oCamlFunction = "lua_atpanic__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_atpanic}lua_atpanic}
    documentation. *)

external call : state -> int -> int -> unit = "lua_call__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_call}lua_call}
    documentation. *)

external checkstack : state -> int -> bool = "lua_checkstack__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_checkstack}lua_checkstack}
    documentation. *)

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#lua_close}lua_close} is not
    present because all the data structures of a Lua state are managed by the
    OCaml garbage collector. *)

external concat : state -> int -> unit = "lua_concat__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_concat}lua_concat}
    documentation. *)

val cpcall : state -> oCamlFunction -> 'a -> thread_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_cpcall}lua_cpcall}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original lua_cpcall,
    it's rather an OCaml function with the same semantics.

    {b WARNING}: the OCaml function you want to execute in a protected
    environment is actually protected againt {b Lua} errors, even memory errors,
    but {b not} against OCaml errors, i.e. exceptions. If for example you run:
    {[
let ls = LuaL.newstate ();;
let my_func ls = failwith "Sorry, my fault..."; 0;;
let cpcall_result = Lua.cpcall ls my_func 42;;
    ]}
    cpcall {b will actually raise} a failure, because that exception is not
    generated by Lua but by OCaml.
*)

external createtable : state -> int -> int -> unit = "lua_createtable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_createtable}lua_createtable}
    documentation. *)

val dump : state -> 'a lua_Writer -> 'a -> writer_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_dump}lua_dump}
    documentation. *)

external equal : state -> int -> int -> bool = "lua_equal__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_equal}lua_equal}
    documentation. *)

external error : state -> 'a = "lua_error__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_error}lua_error}
    documentation. *)

val gc : state -> gc_command -> int -> int
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_gc}lua_gc}
    documentation. *)

(** {{:http://www.lua.org/manual/5.1/manual.html#lua_getallocf}lua_getallocf}
    not implemented in this binding *)

external getfenv : state -> int -> unit = "lua_getfenv__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_getfenv}lua_getfenv}
    documentation. *)

external getfield : state -> int -> string -> unit = "lua_getfield__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_getfield}lua_getfield}
    documentation. *)

val getglobal : state -> string -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_getglobal}lua_getglobal}
    documentation. Like in the original Lua source code this function is
    implemented in OCaml using [getfield]. *)

external getmetatable : state -> int -> bool = "lua_getmetatable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_getmetatable}lua_getmetatable}
    documentation. *)

external gettable : state -> int -> unit = "lua_gettable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_gettable}lua_gettable}
    documentation. *)

external gettop : state -> int = "lua_gettop__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_gettop}lua_gettop}
    documentation. *)

external insert : state -> int -> unit = "lua_insert__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_insert}lua_insert}
    documentation. *)

external isboolean : state -> int -> bool = "lua_isboolean__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isboolean}lua_isboolean}
    documentation. *)

external iscfunction : state -> int -> bool = "lua_iscfunction__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_iscfunction}lua_iscfunction}
    documentation. *)

external isfunction : state -> int -> bool = "lua_isfunction__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isfunction}lua_isfunction}
    documentation. *)

external islightuserdata : state -> int -> bool = "lua_islightuserdata__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_islightuserdata}lua_islightuserdata}
    documentation. *)

external isnil : state -> int -> bool = "lua_isnil__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isnil}lua_isnil}
    documentation. *)

external isnone : state -> int -> bool = "lua_isnone__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isnone}lua_isnone}
    documentation. *)

external isnoneornil : state -> int -> bool = "lua_isnoneornil__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isnoneornil}lua_isnoneornil}
    documentation. *)

external isnumber : state -> int -> bool = "lua_isnumber__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isnumber}lua_isnumber}
    documentation. *)

external isstring : state -> int -> bool = "lua_isstring__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isstring}lua_isstring}
    documentation. *)

external istable : state -> int -> bool = "lua_istable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_istable}lua_istable}
    documentation. *)

external isthread : state -> int -> bool = "lua_isthread__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isthread}lua_isthread}
    documentation. *)

external isuserdata : state -> int -> bool = "lua_isuserdata__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isuserdata}lua_isuserdata}
    documentation. *)

external lessthan : state -> int -> int -> bool = "lua_lessthan__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_lessthan}lua_lessthan}
    documentation. *)

val load : state -> 'a lua_Reader -> 'a -> string -> thread_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_load}lua_load}
    documentation. *)

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#lua_newstate}lua_newstate} is
    not present because it makes very little sense to specify a custom allocator
    written in OCaml. To create a new Lua state, use the function
    {!Lua_aux_lib.newstate}. *)

external newtable: state -> unit = "lua_newtable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_newtable}lua_newtable}
    documentation. *)

val newthread : state -> state
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_newthread}lua_newthread}
    documentation.

    When you create a new thread, this binding guaranties that the Lua object
    will remain "living" (protected from both the Lua and the OCaml garbage
    collectors) until a valid copy exists in at least one of the two contexts.
    
    Remember that all the threads obtained by [newthread] and
    {!Lua_api_lib.tothread} are shared copies, for example:
    {[
let state = LuaL.newstate ();;
let th = Lua.newthread state;;
let th' = match Lua.tothread state 1 with Some s -> s | None -> failwith "not an option!";;
Lua.settop state 0;;
    ]}
    Now the stack of [state] is empty and you have two threads, [th] and [th'],
    but they are actually the {e very same data structure} and operations performed
    on the first will be visible on the second!
    
    Another important issue regarding the scope of a state object representing a
    thread (coroutine): this binding don't prevent you from accessing invalid
    memory in case of misuse of the library. Please, carefully consider this
    fragment:
    {[
let f () =
  let state = LuaL.newstate () in
  let th = Lua.newthread state in
  th;;

let th' = f ();;
Gc.compact ();; (* This will collect [state] inside [f] *)
(* Here something using [th'] *)
    ]}
    After [Gc.compact] the value inside [th'] has lost any possible meaning,
    because it's a thread (a coroutine) of a state object that has been already
    collected. Using [th'] will lead to a {e segmentation fault}, at best, and
    to an {e undefined behaviour} if you are unlucky. *)

external default_gc : state -> int = "default_gc__stub"
(** This is the default "__gc" function attached to any new userdatum created
    with [newuserdata]. See documentation of {! newuserdata} below. *)

val make_gc_function : oCamlFunction -> oCamlFunction
(** This function takes an {! oCamlFunction} you have created to be executed
    as "__gc" metamethod and "decorates" it with some default actions needed
    to deallocate all the memory.

    If you want to create a "__gc" method for your userdata, you {b must} register
    the value from [make_gc_function]. *)

external newuserdata : state -> 'a -> unit = "lua_newuserdata__stub"
(** [newuserdata] is the binding of
    {{:http://www.lua.org/manual/5.1/manual.html#lua_newuserdata}lua_newuserdata}
    but it works in a different way if compared to the original function, and the
    signature is slightly different.

    In C [lua_newuserdata] allocates an area for you, returns a [void*] and you
    cast it as needed. Moreover, it pushes the new userdata on the stack.

    In OCaml, however, you never allocates a value and so the resulting signature
    provides you a way to push an already created value on the top of the Lua stack.

    {b Very important remark, read carefully.} The original Lua [lua_newuserdata]
    doesn't associate to the new userdatum any metatable, it's up to you to define
    a metatable with metamethods, if you need it. On the other hand, this binding
    {b silently} creates a metatable with only one metamethod ("__gc") and associates
    the function {! default_gc } defined above. This function takes care of managing
    the memory between the two garbage collectors when needed. This is transparent
    to you, unless you want to attach to the userdatum a metatable of your, which is
    very likely to happen.

    In case you want to attach a metatable to your userdatum you {b must} include
    the "__gc" metamethod, and you {b must} create the function using
    {! make_gc_function } described above.If you want a metatable for your
    userdatum but you don't need a "__gc", use in any case the {! default_gc }.
    {b Don't create a userdatum with a metatable and without "__gc" or your
    program will leak memory!}

    {b WARNING}: using this function could be harmful because it actually breaks
    the type system. It has the same semantics of [Obj.magic], allowing the
    programmer to push an OCaml value into the Lua state, and then retrieve it
    with a different type. Be very careful! *)

external next : state -> int -> int = "lua_next__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_next}lua_next}
    documentation. *)

external objlen : state -> int -> int = "lua_objlen__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_objlen}lua_objlen}
    documentation. *)

val pcall : state -> int -> int -> int -> thread_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pcall}lua_pcall}
    documentation. *)

external pop : state -> int -> unit = "lua_pop__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pop}lua_pop}
    documentation. *)

external pushboolean : state -> bool -> unit = "lua_pushboolean__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushboolean}lua_pushboolean}
    documentation. *)

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushcclosure}lua_pushcclosure}
    is not present because it makes very little sense to specify a "closure"
    written in OCaml, using the Lua
    {{:http://www.lua.org/pil/27.3.3.html}upvalues} machinery. Use instead
    {!Lua_api_lib.pushcfunction} *)

external pushcfunction : state -> oCamlFunction -> unit = "lua_pushcfunction__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushcfunction}lua_pushcfunction}
    documentation. *)

val pushocamlfunction : state -> oCamlFunction -> unit
(** Alias of {!Lua_api_lib.pushcfunction} *)

val pushfstring : state -> ('a, unit, string, string) format4 -> 'a
(** Pushes onto the stack a formatted string and returns the string itself.
    It is similar to the standard library function sprintf.

    Warning: this function has a different behavior with respect to the original
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushfstring}lua_pushfstring}
    because the conversion specifiers are not restricted as specified in the Lua
    documentation, but you can use all the conversions of the
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html}Printf module}. *)

external pushinteger : state -> int -> unit = "lua_pushinteger__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushinteger}lua_pushinteger}
    documentation. *)

val pushlightuserdata : state -> 'a -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushlightuserdata}lua_pushlightuserdata}
    documentation. Raises [Not_a_block_value] if you try to push a non-block value
    (e.g. an immediate integer) as a light userdata.

    In Lua a light userdata is a way to store inside the Lua state a C pointer.
    It's up the programmer to carefully check for the lifetime of the data
    structures passed to Lua via a light userdata. If you malloc a pointer and
    pass it to Lua, then you free it from C and then you retrieve the same pointer
    from Lua (using lua_touserdata), you are most probably shooting yourself
    in the foot.

    To avoid this class of problems I decided to implement some logic in the binding
    of this function. When you push an OCaml value as a Lua light userdata, a
    global reference to that (OCaml) value is kept inside the Lua state L. So, if
    the original value goes out of scope it is {e not} collected by the garbage
    collector. In this scenario:
    {[
let push_something state =
  let ocaml_value = get_some_complex_value () in
  pushlightuserdata state ocaml_value;
  state
;;
    ]}
    when the [push_something] function returns the Lua state, the [ocaml_value]
    is {e not} collected and can be retrieved at a later time from [state].

    This behaviour has a major drawback: while ensuring the lifetime of objects,
    it wastes memory. All the OCaml values pushed as light userdata will in fact
    be collected when the garbage collector decide to collect the Lua state itself.
    This means that if you have a long running task (e.g. a server) with a Lua
    state and you use [pushlightuserdata], the values pushed will be {e never}
    collected!

    Moreover, if you push a value that have some resources associated with it
    (e.g. a channel, a socket or a DB handler) the resources will be released
    only when the Lua state goes out of scope. *)

external pushliteral : state -> string -> unit = "lua_pushlstring__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushliteral}lua_pushliteral}
    documentation. *)

external pushlstring : state -> string -> unit = "lua_pushlstring__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushlstring}lua_pushlstring}
    documentation. *)

external pushnil : state -> unit = "lua_pushnil__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushnil}lua_pushnil}
    documentation. *)

external pushnumber : state -> float -> unit = "lua_pushnumber__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushnumber}lua_pushnumber}
    documentation. *)

val pushstring : state -> string -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushstring}lua_pushstring}
    documentation. *)

val pushthread : state -> bool
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushthread}lua_pushthread}
    documentation. *)

external pushvalue : state -> int -> unit = "lua_pushvalue__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushvalue}lua_pushvalue}
    documentation. *)

val pushvfstring : state -> ('a, unit, string, string) format4 -> 'a
(** Alias of {!Lua_api_lib.pushfstring} *)

external rawequal : state -> int -> int -> bool = "lua_rawequal__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawequal}lua_rawequal}
    documentation. *)

external rawget : state -> int -> unit = "lua_rawget__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawget}lua_rawget}
    documentation. *)

external rawgeti : state -> int -> int -> unit = "lua_rawgeti__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawgeti}lua_rawgeti}
    documentation. *)

external rawset : state -> int -> unit = "lua_rawset__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawset}lua_rawset}
    documentation. *)

external rawseti : state -> int -> int -> unit = "lua_rawseti__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawseti}lua_rawseti}
    documentation. *)

val register : state -> string -> oCamlFunction -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_register}lua_register}
    documentation. The function is implemented in OCaml using pushcfunction
    and setglobal. *)

external remove : state -> int -> unit = "lua_remove__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_remove}lua_remove}
    documentation. *)

external replace : state -> int -> unit = "lua_replace__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_replace}lua_replace}
    documentation. *)

val resume : state -> int -> thread_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_resume}lua_resume}
    documentation. *)

(** {{:http://www.lua.org/manual/5.1/manual.html#lua_setallocf}lua_setallocf}
    not implemented in this binding *)

external setfenv : state -> int -> bool = "lua_setfenv__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_setfenv}lua_setfenv}
    documentation. *)

external setfield : state -> int -> string -> unit = "lua_setfield__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_setfield}lua_setfield}
    documentation. *)

external setglobal : state -> string -> unit = "lua_setglobal__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_setglobal}lua_setglobal}
    documentation. *)

external setmetatable : state -> int -> int = "lua_setmetatable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_setmetatable}lua_setmetatable}
    documentation. *)

external settable : state -> int -> unit = "lua_settable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_settable}lua_settable}
    documentation. *)

external settop : state -> int -> unit = "lua_settop__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_settop}lua_settop}
    documentation. *)

val status : state -> thread_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_status}lua_status}
    documentation. *)

external toboolean : state -> int -> bool = "lua_toboolean__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_toboolean}lua_toboolean}
    documentation. *)

val tocfunction : state -> int -> oCamlFunction option
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_tocfunction}lua_tocfunction}
    documentation. *)

val toocamlfunction : state -> int -> oCamlFunction option
(** Alias of {!Lua_api_lib.tocfunction} *)

val tointeger : state -> int -> int
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_tointeger}lua_tointeger}
    documentation. *)

val tolstring : state -> int -> string option
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_tolstring}lua_tolstring}
    documentation.
    
    {b NOTE}: The original [len] argument is missing because, unlike in C,
    there is no impedance mismatch between OCaml and Lua strings *)

val tonumber : state -> int -> float
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_tonumber}lua_tonumber}
    documentation. *)

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#lua_topointer}lua_topointer}
    is not available *)

val tostring : state -> int -> string option
(** Alias of {!Lua_api_lib.tolstring} *)

val tothread : state -> int -> state option
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_tothread}lua_tothread}
    documentation. *)

val touserdata : state -> int -> [> `Userdata of 'a | `Light_userdata of 'a ] option
(** If the value at the given acceptable index is a full userdata, returns its
    value as [Some `Userdata v]. If the value is a light userdata, returns its
    value as [Some `Light_userdata v].
    Otherwise, returns [None].

    {b WARNING}: using this function could be harmful because it actually breaks
    the type system. It has the same semantics of [Obj.magic], allowing the
    programmer to push an OCaml value into the Lua state, and then retrieve it
    with a different type. Be very careful! *)

val type_ : state -> int -> lua_type
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_type}lua_type}
    documentation. *)

val typename : state -> lua_type -> string
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_typename}lua_typename}
    documentation. *)

val xmove : state -> state -> int -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_xmove}lua_xmove}
    documentation. *)

val yield : state -> int -> int
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_yield}lua_yield}
    documentation. *)

(**/**)

val init : unit lazy_t
