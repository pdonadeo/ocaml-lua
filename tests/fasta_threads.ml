open Lua_api;;

let lua_program = "-- The Computer Language Benchmarks Game
-- http://shootout.alioth.debian.org/
-- contributed by Mike Pall

local Last = 42
local function random(max)
  local y = (Last * 3877 + 29573) % 139968
  Last = y
  return (max * y) / 139968
end

local function make_repeat_fasta(thread_id, id, desc, s, n)
  local output_file_name = string.format(\"OUTPUT/thread_%05d/out.txt\", thread_id)
  local output_file = io.open(output_file_name, \"a+b\")
  local sub = string.sub
  output_file:write(\">\", id, \" \", desc, \"\\n\")
  local p, sn, s2 = 1, #s, s..s
  for i=60,n,60 do
    output_file:write(sub(s2, p, p + 59), \"\\n\")
    p = p + 60; if p > sn then p = p - sn end
  end
  local tail = n % 60
  if tail > 0 then output_file:write(sub(s2, p, p + tail-1), \"\\n\") end
  output_file:close()
end

local function make_random_fasta(thread_id, id, desc, bs, n)
  local output_file_name = string.format(\"OUTPUT/thread_%05d/out.txt\", thread_id)
  local output_file = io.open(output_file_name, \"a+b\")
  output_file:write(\">\", id, \" \", desc, \"\\n\")
  output_file:close()

  loadstring([=[
    local char, unpack, n, random = string.char, unpack, ...
    local output_file_name = string.format(\"OUTPUT/thread_%05d/out.txt\", thread_id)
    local output_file = io.open(output_file_name, \"a+b\")

    local buf, p = {}, 1
    for i=60,n,60 do
      for j=p,p+59 do ]=]..bs..[=[ end
      buf[p+60] = 10; p = p + 61
      if p >= 2048 then output_file:write(char(unpack(buf, 1, p-1))); p = 1 end
    end
    local tail = n % 60
    if tail > 0 then
      for j=p,p+tail-1 do ]=]..bs..[=[ end
      p = p + tail; buf[p] = 10; p = p + 1
    end
    output_file:write(char(unpack(buf, 1, p-1)))
    output_file:close()
  ]=], desc)(n, random)
end

local function bisect(c, p, lo, hi)
  local n = hi - lo
  if n == 0 then return \"buf[j] = \"..c[hi]..\"\\n\" end
  local mid = math.floor(n / 2)
  return \"if r < \"..p[lo+mid]..\" then\\n\"..bisect(c, p, lo, lo+mid)..
         \"else\\n\"..bisect(c, p, lo+mid+1, hi)..\"end\\n\"
end

local function make_bisect(tab)
  local c, p, sum = {}, {}, 0
  for i,row in ipairs(tab) do
    c[i] = string.byte(row[1])
    sum = sum + row[2]
    p[i] = sum
  end
  return \"local r = random(1)\\n\"..bisect(c, p, 1, #tab)
end

local alu =
  \"GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG\"..
  \"GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA\"..
  \"CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT\"..
  \"ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA\"..
  \"GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG\"..
  \"AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC\"..
  \"AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA\"

local iub = make_bisect{
  { \"a\", 0.27 },
  { \"c\", 0.12 },
  { \"g\", 0.12 },
  { \"t\", 0.27 },
  { \"B\", 0.02 },
  { \"D\", 0.02 },
  { \"H\", 0.02 },
  { \"K\", 0.02 },
  { \"M\", 0.02 },
  { \"N\", 0.02 },
  { \"R\", 0.02 },
  { \"S\", 0.02 },
  { \"V\", 0.02 },
  { \"W\", 0.02 },
  { \"Y\", 0.02 },
}

local homosapiens = make_bisect{
  { \"a\", 0.3029549426680 },
  { \"c\", 0.1979883004921 },
  { \"g\", 0.1975473066391 },
  { \"t\", 0.3015094502008 },
}

local N = param
make_repeat_fasta(thread_id, 'ONE', 'Homo sapiens alu', alu, N*2)
make_random_fasta(thread_id, 'TWO', 'IUB ambiguity codes', iub, N*3)
make_random_fasta(thread_id, 'THREE', 'Homo sapiens frequency', homosapiens, N*5)";;

let pf = Printf.printf;;
let spf = Printf.sprintf;;
let (|>) x f = f x;;
let opt_get o =
  match o with
  | Some v -> v
  | None -> raise Not_found;;

let thread thread_id n =
  let state = LuaL.newstate () in
  LuaL.openlibs state;
  Lua.pushinteger state n;
  Lua.setglobal state "param";
  Lua.pushinteger state thread_id;
  Lua.setglobal state "thread_id";
  LuaL.loadbuffer state lua_program "line" |> ignore;
  try
    match Lua.pcall state 0 0 0 with
    | Lua.LUA_OK -> ()
    | err -> raise (Lua.Error err);
  with
  | Lua.Error _ ->
    begin
      Printf.printf "%s\n%!" ((Lua.tostring state (-1)) |> opt_get);
      Lua.pop state 1;
      failwith "FATAL ERROR"
    end;
;;

let rec mkdir ?(parents=true) ?(permissions = 0o755) directory =
  let mkdir' ?(perm = 0o755) dir_name =
    try Unix.mkdir dir_name perm
    with Unix.Unix_error(Unix.EEXIST, _, _) -> () in

  let dir_name = Filename.dirname directory in
  try mkdir' ~perm:permissions directory
  with
  | Unix.Unix_error (Unix.EACCES, _, parameter) ->
      raise (Unix.Unix_error (Unix.EACCES, "mkdir", parameter))
  | Unix.Unix_error (Unix.ENOENT, _, _) as e ->
      if parents then begin
        mkdir ~parents:parents ~permissions:permissions dir_name;
        Unix.mkdir directory permissions
      end else raise e
;;

let main thread_num n =
  let thread_num = int_of_string thread_num in
  let n = int_of_string n in
  let th_list = ref [] in
  for i = 1 to thread_num do
    mkdir (spf "OUTPUT/thread_%05d" i);
    pf "Thread %d/%d starts\n%!" i thread_num;
    let t = Thread.create (thread i) n in
    th_list := t::!th_list;
  done;
  List.iter Thread.join !th_list;
;;

try main Sys.argv.(1) Sys.argv.(2)
with Invalid_argument _ -> begin
  Printf.eprintf "Usage: %s <thread_num> <fasta_argument>\n%!" (Sys.argv.(0));
  exit 1;
end
