open Lua_api;;

Random.self_init ();;

type point =
  {
    x : float;
    y : float;
    fluff : string list;
  }

let empty = { x = 0.0; y = 0.0; fluff = [] };;

let equal p1 p2 =
  if p1.x = p2.x && p2.y = p2.y && Test_common.string_list_eq p1.fluff p2.fluff
  then true
  else false
;;

let p_alloc = ref 0;;

let p_finaliser v =
  let open Test_common in
  log Debug_only "    deallocating...";
  decr p_alloc
;;

let test_loop () =
  let ls = LuaL.newstate () in
  let test_value = ref empty in
  let func ls =
    let p : point =
      match Lua.touserdata ls 1 with
      | Some `Light_userdata ud -> ud
      | _ -> failwith "A light userdata expected" in
    test_value := p;
    0 in
  let p = {
      x = Random.float 100.0;
      y = Random.float 100.0;
      fluff = Test_common.allocate 9973 470;
    } in
  incr p_alloc;
  Gc.finalise p_finaliser p;

  let () = 
    match Lua.cpcall ls func p with
    | Lua.LUA_OK        -> ()
    | Lua.LUA_YIELD
    | Lua.LUA_ERRRUN
    | Lua.LUA_ERRSYNTAX
    | Lua.LUA_ERRMEM
    | Lua.LUA_ERRERR as e -> raise (Lua.Error e) in

  if not (equal p !test_value)
  then failwith "The lightuserdata inside cpcall is not the expected one!"
;;

let main () =
  let open Test_common in
  let time_start = Unix.gettimeofday () in
  while Unix.gettimeofday () <  time_start +. 10.0 do
    sleep_float 0.1;
    Gc.compact ();
  done;

  let test_duration = 60.0 *. 1.0 in
  let time_start = Unix.gettimeofday ()in

  while Unix.gettimeofday () <  time_start +. test_duration do
    test_loop ();
    log Debug_only "allocated objects: %d" !p_alloc;
  done;

  Gc.compact ();
  log Debug_only "allocated objects: %d" !p_alloc;
  let time_start = Unix.gettimeofday () in

  while Unix.gettimeofday () <  time_start +. 30.0 do
    sleep_float 0.1;
    Gc.compact ();
  done;
  log User_info "allocated objects: %d" !p_alloc;
;;

Test_common.run main ();;

