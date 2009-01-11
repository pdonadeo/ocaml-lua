#include <string.h>

#include <lua5.1/lua.h>
#include <lua5.1/lauxlib.h>
#include <lua5.1/lualib.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/callback.h>

/* Encapsulation of opaque Lua state handle (of type lua_State *)
   as Caml custom blocks. */

static struct custom_operations lua_State_ops =
{
  "org.ex-nunc.ocaml_lua",
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


/* Accessing the lua_State* part of a Caml custom block */
#define lua_State_val(v) (*((lua_State **) Data_custom_val(v)))

/* Allocating a Caml custom block to hold the given lua_State* */
static value alloc_lua_State(lua_State *L)
{
  value v = alloc_custom(&lua_State_ops, sizeof(lua_State *), 0, 1);
  lua_State_val(v) = L;
  return v;
}


CAMLprim
value lua_open__stub (value unit)
{
  CAMLparam1(unit);
  CAMLreturn(alloc_lua_State(lua_open()));
}


CAMLprim
value luaL_openlibs__stub(value L)
{
  CAMLparam1(L);
  luaL_openlibs(lua_State_val(L));
  CAMLreturn(Val_unit);
}


CAMLprim
value lua_close__stub(value L)
{
  CAMLparam1(L);
  lua_close(lua_State_val(L));
  CAMLreturn(Val_unit);
}


CAMLprim
value lua_pop__stub(value L, value n)
{
  CAMLparam2(L, n);
  lua_pop(lua_State_val(L), Int_val(n));
  CAMLreturn(Val_unit);
}


CAMLprim
value luaL_loadbuffer__stub(value L, value buff, value sz, value name)
{
  CAMLparam4(L, buff, sz, name);
  CAMLlocal1(status);
  status = Val_int(luaL_loadbuffer( lua_State_val(L),
                                    String_val(buff),
                                    Int_val(sz),
                                    String_val(name)) );
  CAMLreturn(status);
}


CAMLprim
value lua_pcall__stub(value L, value nargs, value nresults, value errfunc)
{
  CAMLparam4(L, nargs, nresults, errfunc);
  CAMLlocal1(status);
  status = Val_int(lua_pcall( lua_State_val(L),
                              Int_val(nargs),
                              Int_val(nresults),
                              Int_val(errfunc)) );
  CAMLreturn(status);
}


void raise_type_error(char *msg)
{
  caml_raise_with_string(*caml_named_value("Lua type error"), msg);
}


CAMLprim
value lua_tolstring__stub(value L, value index)
{
  size_t len = 0;
  const char *value_from_lua;
  CAMLparam2(L, index);
  CAMLlocal1(ret_val);
  value_from_lua = lua_tolstring( lua_State_val(L),
                                  Int_val(index),
                                  &len );
  if (value_from_lua != NULL)
  {
    ret_val = caml_alloc_string(len);
    char *s = String_val(ret_val);
    memcpy(s, value_from_lua, len);
  }
  else
  {
    raise_type_error("lua_tolstring: not a string value!");
  }

  CAMLreturn(ret_val);
}

