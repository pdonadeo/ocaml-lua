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
#include <caml/signals.h>


typedef struct node
{
  lua_State *state;
  value state_value;
  value panic_callback;
  struct node *next;
} node;

static void finalize_lua_State(value L);
static struct custom_operations lua_State_ops =
{
  "org.ex-nunc.ocaml_lua",
  finalize_lua_State,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

#define lua_State_val(L) (*((lua_State **) Data_custom_val(L)))

static node *states_register = NULL;

static int states_number = 0;

CAMLprim
value lua_open__stub (value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(v_L);

  // create a fresh new Lua state
  lua_State *L = lua_open();
  if (L == NULL)
  {
    caml_failwith("MEMORY ERROR: not enough memory to allocate a new Lua state");
  }

  // alloc space for the register entry
  node *new_node = (node*)caml_stat_alloc(sizeof(node));
  new_node->state = L;
  new_node->panic_callback = Val_unit;
  new_node->next = states_register;
  states_register = new_node;
  states_number++;

  // wrap the lua_State* in a custom object
  v_L = caml_alloc_custom(&lua_State_ops, sizeof(lua_State *), 1, 10);
  lua_State_val(v_L) = L;
  new_node->state_value = v_L;

  // return the lua_State value
  CAMLreturn(v_L);
}


static void finalize_lua_State(value L)
{
  lua_State *state = lua_State_val(L);
  node *current = states_register;
  node *prev = NULL;

  while (current != NULL)
  {
    if (current->state == state)
    {
      lua_close(state);

      if (prev != NULL)
        prev->next = current->next;
      else
        states_register = current->next;

      if (current->panic_callback != Val_unit)
          caml_remove_global_root(&(current->panic_callback));
      caml_stat_free(current);
      states_number--;
      current = NULL;
    }
    else
    {
      prev = current;
      current = current->next;
    }
  }

  return;
}


CAMLprim
value luaL_openlibs__stub(value L)
{
  CAMLparam1(L);
  luaL_openlibs(lua_State_val(L));
  CAMLreturn(Val_unit);
}


int panic_prototype(lua_State *L)
{
  node *current = states_register;
  while (current != NULL)
  {
    if (current->state == L)
      return Int_val(caml_callback( current->panic_callback,  // callback
                                    current->state_value ));  // Lua state
    else
      current = current->next;
  }
  return 0;
}


CAMLprim
value lua_atpanic__stub(value L, value panicf)
{
  CAMLparam2(L, panicf);
  CAMLlocal1(old_panicf);

  lua_State *state = lua_State_val(L);
  node *current = states_register;
  while (current != NULL)
  {
    if (current->state == state)
    {
      if (current->panic_callback == Val_unit)
      {
        current->panic_callback = panicf;
        caml_register_global_root(&(current->panic_callback));
        lua_atpanic(state, panic_prototype);
        caml_raise_constant(*caml_named_value("Not_found"));
      }
      else
      {
        old_panicf = current->panic_callback;
        caml_remove_global_root(&(current->panic_callback));
        current->panic_callback = panicf;
        caml_register_global_root(&(current->panic_callback));
        lua_atpanic(state, panic_prototype);
      }
      current = NULL;
    }
    else
    {
      current = current->next;
    }
  }

  CAMLreturn(old_panicf);
}


CAMLprim
value lua_error__stub(value L)
{
  CAMLparam1(L);
  lua_error(lua_State_val(L));
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
value lua_call__stub(value L, value nargs, value nresults)
{
  CAMLparam3(L, nargs, nresults);
  lua_call(lua_State_val(L), Int_val(nargs), Int_val(nresults));
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
  caml_raise_with_string(*caml_named_value("Lua_type_error"), msg);
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

