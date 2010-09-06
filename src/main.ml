open Lua_api;;

let s = Gc.set { (Gc.get ()) with
                    Gc.verbose = (0x001 lor 0x002 lor 0x004 lor 0x008 lor
                                  0x010 lor 0x020 lor 0x040 lor 0x080 lor
                                  0x100 lor 0x200);
                    Gc.allocation_policy = 1; };;

let simple_ocaml_function l =
  ignore (String.create (16727211)); (* a huge (prime) string to pollute the heap *)
  Printf.printf "OCaml function called from Lua!!!:-)\n%!";
  0;;

let l = LuaL.newstate ();;

Lua.pushocamlfunction l simple_ocaml_function;;

Lua.setglobal l "simple_ocaml_function";;
LuaL.loadbuffer l "simple_ocaml_function()\n" "line";;
ignore (Lua.pcall l 0 0 0);;

Lua.pushstring l "Intentional fatal error";;

Gc.compact ();;

Printf.printf "BEFORE calling \"Lua.error l\"\n%!";;
ignore (Lua.error l);;

