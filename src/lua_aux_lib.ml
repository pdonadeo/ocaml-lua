open Lua_api_lib

let (|>) x f = f x

type buffer =
  { ls : state;
    buffer : Buffer.t; }

type reg = string * oCamlFunction

let refnil = -1;;

let noref = -2;;

let addchar b c =
  Buffer.add_char b.buffer c
;;

let addlstring b s =
  Buffer.add_string b.buffer s
;;

let addstring = addlstring;;

let addvalue b =
  match tolstring b.ls (-1) with
  | Some s -> Buffer.add_string b.buffer s
  | None -> ()
;;

external argcheck : state -> bool -> int -> string -> unit = "luaL_argcheck__stub"

external argerror : state -> int -> string -> 'a = "luaL_argerror__stub"

let buffinit ls =
  { ls = ls;
    buffer = Buffer.create 8192; }
;;

external callmeta : state -> int -> string -> bool = "luaL_callmeta__stub"

external checkany : state -> int -> unit = "luaL_checkany__stub"

external checkint : state -> int -> int = "luaL_checkint__stub"

let checkinteger = checkint;;

external checklong : state -> int -> int = "luaL_checklong__stub"

external typerror : state -> int -> string -> 'a = "luaL_typerror__stub"

let tag_error ls narg tag =
  typerror ls narg (typename ls tag)
;;

let checklstring ls narg =
  match tolstring ls narg with
  | Some s -> s
  | None -> tag_error ls narg LUA_TSTRING
;;

let checknumber ls narg =
  let d = tonumber ls narg in
  if d = 0.0 && not (isnumber ls narg)
  then tag_error ls narg LUA_TNUMBER
  else d
;;

let optlstring ls narg d =
  if isnoneornil ls narg then d
  else checklstring ls narg
;;

let optstring = optlstring;;

let checkstring = checklstring;;

let checkoption ls narg def lst =
  let name =
    match def with
    | Some s -> optstring ls narg s
    | None -> checkstring ls narg in

  let rec find ?(i=0) p xs =
    match xs with
    | [] -> argerror ls narg (pushfstring ls "invalid option '%s'" name)
    | hd::tl -> if p hd then i else find ~i:(i+1) p tl in

  find (fun s -> s = name) lst
;;

external error_aux : state -> string -> 'a = "luaL_error__stub"

let error state =
  let k s = error_aux state s in
    Printf.kprintf k
;;

let checkstack ls space mes =
  if not (Lua_api_lib.checkstack ls space)
  then error ls "stack overflow (%s)" mes
  else ()
;;

let checktype ls narg t =
  if (Lua_api_lib.type_ ls narg <> t)
  then tag_error ls narg t
  else ()
;;

let checkudata ls ud tname =
  let te = lazy (typerror ls ud tname) in
  let p = touserdata ls ud in
  match p with
  | Some data -> begin
      if (Lua_api_lib.getmetatable ls ud) then begin
        getfield ls registryindex tname;
        if (rawequal ls (-1) (-2))
        then (pop ls 2; p)
        else Lazy.force te
      end else Lazy.force te
    end
  | None -> Lazy.force te
;;

external luaL_loadfile__wrapper : state -> string -> int = "luaL_loadfile__stub"

let loadfile ls filename =
  luaL_loadfile__wrapper ls filename |> thread_status_of_int
;;

let dofile ls filename =
  match loadfile ls filename with
  | LUA_OK -> begin
      match pcall ls 0 multret 0 with
      | LUA_OK -> true
      | _ -> false
    end
  | _ -> false
;;

external luaL_loadbuffer__wrapper :
  state -> string -> int -> string -> int = "luaL_loadbuffer__stub"

let loadbuffer ls buff name =
  luaL_loadbuffer__wrapper ls buff (String.length buff) name |> thread_status_of_int
;;

let loadstring ls s =
  loadbuffer ls s s
;;

let dostring ls str =
  match loadstring ls str with
  | LUA_OK -> begin
      match pcall ls 0 multret 0 with
      | LUA_OK -> true
      | _ -> false
    end
  | _ -> false
;;

external getmetafield : state -> int -> string -> bool = "luaL_getmetafield__stub"

external getmetatable : state -> string -> unit = "luaL_getmetatable__stub"

external gsub : state -> string -> string -> string -> string = "luaL_gsub__stub"

external newmetatable : state -> string -> bool = "luaL_newmetatable__stub"

external newstate : unit -> state = "luaL_newstate__stub"

external openlibs : state -> unit = "luaL_openlibs__stub"

external optinteger : state -> int -> int -> int = "luaL_optinteger__stub"

let optint = optinteger

external optlong : state -> int -> int -> int = "luaL_optlong__stub"

let optnumber ls narg d =
  if Lua_api_lib.isnoneornil ls narg
  then d
  else checknumber ls narg
;;

let pushresult b =
  let data = Buffer.contents b.buffer in
  Lua_api_lib.pushlstring b.ls data;
  Buffer.clear b.buffer;
;;

external ref_ : state -> int -> int = "luaL_ref__stub"

external findtable : state -> int -> string -> int -> string option = "luaL_findtable__stub"

let register ls libname func_list =
  let () =
    match libname with
    | Some libname -> begin
      let size = List.length func_list in
      (* check whether lib already exists *)
      let _ = findtable ls registryindex "_LOADED" 1 in
      getfield ls (-1) libname; (* get _LOADED[libname] *)
      if not (istable ls (-1)) then begin  (* not found? *)
        pop ls 1;  (* remove previous result *)
        (* try global variable (and create one if it does not exist) *)
        let () =
          match findtable ls globalsindex libname size with
          | Some _ -> error ls "name conflict for module '%s'" libname
          | None -> () in
        pushvalue ls (-1);
        setfield ls (-3) libname;  (* _LOADED[libname] = new table *)
      end;
      remove ls (-2);  (* remove _LOADED table *)
      insert ls (-1);  (* move library table to below upvalues *)
    end
    | None -> () in

  List.iter
    (fun reg ->
      pushcfunction ls (snd reg);
      setfield ls (-2) (fst reg))
    func_list;
;;

let typename ls index =
  Lua_api_lib.typename ls (Lua_api_lib.type_ ls index)
;;

external unref : state -> int -> int = "luaL_ref__stub"

external where : state -> int -> unit = "luaL_where__stub"
