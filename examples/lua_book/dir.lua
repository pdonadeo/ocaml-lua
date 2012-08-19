abs_count = 0

function traverse(start, lvl)
  lvl = lvl or 0
  local d = opendir(start)  -- opendir is provided by OCaml
  if d ~= nil then
    dir = readdir(d)        -- readdir is provided by OCaml
    while dir ~= nil do
      local abs_path = start .. dir
      if dir ~= "." and dir ~= ".." then
        local indent = string.rep("  ", lvl)
        abs_count = abs_count + 1
        io.write(string.format("entry %07d is: %s%s\n", abs_count, indent, abs_path))
        io.stdout:flush()
        local is_link = is_symlink(abs_path)  -- is_symlink is provided by OCaml
        if is_link ~= nil and not is_link then
          traverse(abs_path .. "/", lvl + 1)
        end
      end
      dir = readdir(d)
    end
  end
end

traverse("/")
