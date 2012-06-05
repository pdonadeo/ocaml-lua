open Lua_api;;

let (|>) x f = f x;;

Random.self_init ();;

let opt_get o =
  match o with
  | Some v -> v
  | None -> raise Not_found

exception Test_exception
let counter = ref 0;;

let panicf1 l =
  Printf.printf "panicf1: %d\n%!" !counter;
  raise Test_exception
;;

let push_get_call_c_function l f =
  Lua.pushocamlfunction l f;
  let f' = Lua.tocfunction l (-1) in
  Lua.pop l 1;
  match f' with
  | None -> failwith "This should be a function, something went wrong!"
  | Some f ->
      begin
        Printf.printf "Calling an OCaml function obtained from Lua: %!";
        f l |> ignore;
      end
;;

let test_loop () =
  let simple_ocaml_function l =
    let () = Test_common.allocate ~random:false 479 99733 |> ignore in
      Printf.printf "OCaml function called from Lua!!!:-)\n%!";
      0 in

  let l1 = LuaL.newstate () in
  let l2 = LuaL.newstate () in

  try
    let str_list = Test_common.allocate ~random:false 479 99733 in
    let panicf2 l =
      ignore str_list;

      push_get_call_c_function l simple_ocaml_function;

      Printf.printf "panicf2: %d\n%!" !counter;
      raise Test_exception in
    let n = Random.int 2 in
    let f = match n with | 0 -> panicf1 | 1 -> panicf2 | _ -> failwith "IMPOSSIBILE" in

(* TODO TODO TODO
 * ATTENZIONE, ELIMINARE QUESTI TEST DA QUI E CREARE UN TEST SPECIFICO.
 * SONO IMPORTANTI, MA QUI NON C'ENTRANO NULLA!
    (* Light userdata test *)
    for i = 1 to 50 do
      let something = Test_common.allocate_many_small () in
      Lua.pushlightuserdata l1 something;
      let something' : string list =
        match Lua.touserdata l1 (-1) with
        | Some `Userdata v -> failwith "USERDATA"
        | Some `Light_userdata v -> v
        | None -> failwith "NOT A USER DATUM" in
      Lua.pop l1 1;
      List.iter2
        (fun s s' -> if s <> s' then failwith (Printf.sprintf "\"%s\" <> \"%s\"" s s'))
        something something'
    done;

    (* Userdata test *)
    for i = 1 to 50 do
      let something = Test_common.allocate_many_small () in
      Lua.newuserdata l2 something;
      let something' : string list =
        match Lua.touserdata l2 (-1) with
        | Some `Userdata v -> v
        | Some `Light_userdata v -> failwith "LIGHT USERDATA"
        | None -> failwith "NOT A USER DATUM" in
      Lua.pop l2 1;
      List.iter2
        (fun s s' -> if s <> s' then failwith (Printf.sprintf "\"%s\" <> \"%s\"" s s'))
        something something'
    done;
    ***************************************************************************)

    let def_panic1 = Lua.atpanic l1 f in
    let def_panic2 = Lua.atpanic l2 f in

    Lua.pushfstring l1 "Custom message on %s%d stack" "L" 1 |> ignore;
    Lua.pushstring l2 "Custom message on L2 stack";
    let my_panic1 = Lua.atpanic l1 def_panic1 in
    let my_panic2 = Lua.atpanic l2 def_panic2 in

    let def_panic1 = Lua.atpanic l1 my_panic1 in
    let def_panic2 = Lua.atpanic l2 my_panic2 in

    ignore(def_panic1, def_panic2);

    ignore (Lua.pushocamlfunction l1 simple_ocaml_function);
    Lua.setglobal l1 "simple_ocaml_function";

    LuaL.openlibs l1;
    LuaL.openlibs l2;
    LuaL.loadbuffer l1 "simple_ocaml_function()\n" "line" |> ignore;
    LuaL.loadbuffer l2 "a = 42\nb = 43\nc = a + b\n-- print(c)" "line" |> ignore;
    let () =
      match Lua.pcall l1 0 0 0 with
      | Lua.LUA_OK -> ()
      | err -> raise (Lua.Error err) in
    let () =
      match Lua.pcall l2 0 0 0 with
      | Lua.LUA_OK -> ()
      | err -> raise (Lua.Error err) in
    let n = Random.int 2 in
    match n with
    | 0 -> Lua.error l1
    | 1 -> Lua.error l2
    | _ -> failwith "IMPOSSIBILE"
  with
  | Lua.Error err ->
    begin
      Printf.printf "%s\n%!" ((Lua.tostring l1 (-1)) |> opt_get);
      Lua.pop l1 1;
      failwith "FATAL ERROR"
    end;
;;

let main () =
  let open Test_common in
  let time_start = Unix.gettimeofday () in
  while Unix.gettimeofday () <  time_start +. 10.0 do
    sleep_float 0.1;
    Gc.compact ();
  done;

  let test_duration = 60.0 *. 1.0 in
  let time_start = Unix.gettimeofday () in

  while Unix.gettimeofday () <  time_start +. test_duration do
    let () = try test_loop () with Test_exception -> () in
    counter := !counter + 1;
  done;

  Gc.compact ();
  let time_start = Unix.gettimeofday () in

  while Unix.gettimeofday () <  time_start +. 30.0 do
    sleep_float 1.0;
    Gc.compact ();
  done;
;;

Test_common.run main ()

