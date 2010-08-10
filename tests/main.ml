open Lua_api

let (|>) x f = f x

exception Test_exception
let conta = ref 0;;

let panicf1 l =
  Printf.printf "panicf1: %d\n%!" !conta;
  raise Test_exception
;;

let closure () =
  let simple_ocaml_function l =
    let () = String.create (1024*1024) |> ignore in
      Printf.printf "OCaml function called from Lua!!!:-)\n%!";
      0 in
  let l1 = LuaL.newstate () in
  let l2 = LuaL.newstate () in
    try
      let n = Random.int 1024*1024 in
      let str = String.create n in
      let panicf2 l =
        ignore str;
        Printf.printf "panicf2: %d\n%!" !conta;
        raise Test_exception in
      let n = Random.int 2 in
      let f = match n with | 0 -> panicf1 | 1 -> panicf2 | _ -> failwith "IMPOSSIBILE" in

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
        LuaL.loadbuffer l1 "simple_ocaml_function()\n" "line";
        LuaL.loadbuffer l2 "a = 42\nb = 43\nc = a + b\n-- print(c)" "line";
        let () = match Lua.pcall l1 0 0 0 with
                  | Lua.LUA_OK -> ()
                  | err -> raise (Lua.Error err) in
        let () = match Lua.pcall l2 0 0 0 with
                  | Lua.LUA_OK -> ()
                  | err -> raise (Lua.Error err) in
        let n = Random.int 2 in
          match n with | 0 -> Lua.error l1 | 1 -> Lua.error l2 | _ -> failwith "IMPOSSIBILE"
    with
      | Lua.Error err -> begin
            Printf.printf "%s\n%!" (Lua.tostring l1 (-1));
            Lua.pop l1 1;
            failwith "FATAL ERROR"
          end;
;;

let sleep_float n =
  let _ = Unix.select [] [] [] n in ()
;;

let print_timings start_space start_wtime start_ptime =
  let end_ptime = Unix.times () in      (* process time *)
  let self_u = end_ptime.Unix.tms_utime -. start_ptime.Unix.tms_utime in
  let self_s = end_ptime.Unix.tms_stime -. start_ptime.Unix.tms_stime in
  let self = self_u +. self_s in
  let child_u = end_ptime.Unix.tms_cutime -. start_ptime.Unix.tms_cutime in
  let child_s = end_ptime.Unix.tms_cstime -. start_ptime.Unix.tms_cstime in
  let child = child_u +. child_s in
  let run_time = self +. child in
  let real_time = Unix.time () -. start_wtime in (* wall time *)
  let real_time_sec = int_of_float real_time in
  let real_time_min = real_time_sec / 60 in
  let real_time_sec = real_time_sec mod 60 in
  let real_time_hrs = real_time_min / 60 in
  let real_time_min = real_time_min mod 60 in
  (* we would need a compaction if we were reporting memory usage *)
  (* Gc.compact (); *)
  let end_space = Gc.quick_stat () in
    Printf.printf "Run time: %f sec\n%!" run_time;
    Printf.printf "Self:     %f sec\n%!" self;
    Printf.printf "     sys: %f sec\n%!" self_u;
    Printf.printf "    user: %f sec\n%!" self_s;
    Printf.printf "Children: %f sec\n%!" child;
    Printf.printf "     sys: %f sec\n%!" child_u;
    Printf.printf "    user: %f sec\n%!" child_s;
    Printf.printf "GC:     minor: %d\n%!"
      (end_space.Gc.minor_collections - start_space.Gc.minor_collections);
    Printf.printf "        major: %d\n%!"
      (end_space.Gc.major_collections - start_space.Gc.major_collections);
    Printf.printf "  compactions: %d\n%!"
      (end_space.Gc.compactions - start_space.Gc.compactions);
    Printf.printf "Allocated:  %.1f words\n%!"
      (end_space.Gc.minor_words +. end_space.Gc.major_words
       -. start_space.Gc.minor_words -. start_space.Gc.major_words
       -. end_space.Gc.promoted_words +. start_space.Gc.promoted_words);
    Printf.printf "Wall clock:  %.0f sec (%02d:%02d:%02d)\n%!"
      real_time real_time_hrs real_time_min real_time_sec;
    if real_time > 0. then
      Printf.printf "Load:  %.2f%%\n%!" (run_time *. 100.0 /. real_time)
;;

(* Run function, then report time and space usage *)
let run func args =
  Gc.compact (); (* so that prior execution does not skew the results *)
  let start_space = Gc.quick_stat () in
  let start_wtime = Unix.time () in     (* wall time *)
  let start_ptime = Unix.times () in    (* process time *)
  let ret =
    try func args
    with e -> print_timings start_space start_wtime start_ptime;
              raise e in
    print_timings start_space start_wtime start_ptime;
    ret
;;

let timeout = 60.0 *. 10.0;;
let max_run = int_of_float (timeout /. (33.0 /. 10000.0));;

let main () =
  while !conta <  max_run do
    let () = try closure () with Test_exception -> () in
(*       Gc.minor (); *)
(*       Gc.major_slice 0 |> ignore; *)
(*       Gc.major (); *)
      Gc.compact ();
      conta := !conta + 1;
      sleep_float (1./.((Random.float 900.0) +. 100.));
  done
;;

run main ()

