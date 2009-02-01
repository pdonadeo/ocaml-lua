open Lua_api

let (|>) x f = f x

exception Test_exception
let conta = ref 0;;

let panicf1 l =
  Printf.printf "panicf1: %d\n%!" !conta;
  raise Test_exception
;;

let closure () =
  let l1 = Lua.lua_open () in
  let l2 = Lua.lua_open () in
    try
      let n = Random.int 1024*1024 in
      let str = String.create n in
      let panicf2 l =
        ignore str;
        Printf.printf "panicf2: %d\n%!" !conta;
        raise Test_exception in
      let n = Random.int 2 in
      let f = match n with | 0 -> panicf1 | 1 -> panicf2 | _ -> failwith "IMPOSSIBILE" in
        Lua.atpanic l1 f |> ignore;
        Lua.atpanic l2 f |> ignore;
        LuaL.openlibs l1;
        LuaL.openlibs l2;
        LuaL.loadbuffer l1 "a = 42\nb = 43\nc = a + b\n-- print(c)" "line";
        LuaL.loadbuffer l2 "a = 42\nb = 43\nc = a + b\n-- print(c)" "line";
        Lua.pcall l1 0 0 0;
        Lua.pcall l2 0 0 0;
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

while true do
  let () = try closure () with Test_exception -> () in
(*   Gc.minor (); *)
(*   Gc.major_slice 0 |> ignore; *)
(*   Gc.major (); *)
(*   Gc.compact (); *)
  conta := !conta + 1;
  sleep_float (1./.((Random.float 900.0) +. 100.));
done;;

