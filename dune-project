(lang dune 2.3)

(name ocaml-lua)

(version 1.9)

(generate_opam_files true)

(source
 (github pdonadeo/ocaml-lua))

(license MIT)

(authors "Paolo Donadeo" "Sylvain Le Gall")

(maintainers "paolo@donadeo.net")

(homepage "https://pdonadeo.github.io/ocaml-lua/")

(bug_reports "https://github.com/pdonadeo/ocaml-lua/issues")

(package
 (name ocaml-lua)
 (synopsis "Lua bindings")
 (description
  "Lua is a powerful, light-weight programming language designed for\nextending applications. It provides a good general purpose programming\nlanguage to replace DSL that don't really need to be specific.\n\nThis library provides bindings to Lua API which allows the application\nto exchange data with Lua programs and also to extend Lua with OCaml\nfunctions.\n\n[Lua homepage](http://www.lua.org)")
 (depends
  (ocaml
   (>= 4.11.0))
  (odoc :with-doc)))
