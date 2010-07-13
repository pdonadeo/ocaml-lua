#include <string.h>
#include <stdarg.h>

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

/******************************************************************************/
/*****                           DEBUG FUNCTION                           *****/
/******************************************************************************/
/* Comment out the following line to enable debug */
#define NO_DEBUG

#if defined(NO_DEBUG) && defined(__GNUC__)
#define debug(level, format, args...) ((void)0)
#else
void debug(int level, char *format, ...);
#endif

#ifndef NO_DEBUG
static int msglevel = 2; /* the higher, the more messages... */
#endif

#if defined(NO_DEBUG) && defined(__GNUC__)
/* Nothing */
#else
void debug(int level, char* format, ...)
{
#ifdef NO_DEBUG
    /* Empty body, so a good compiler will optimise calls
       to debug away */
#else
    va_list args;

    if (level > msglevel)
        return;

    va_start(args, format);
    vfprintf(stderr, format, args);
    fflush(stderr);
    va_end(args);
#endif /* NO_DEBUG */
}
#endif /* NO_DEBUG && __GNUC__ */
/******************************************************************************/

typedef struct ocaml_data
{
  value state_value;
  value panic_callback;
} ocaml_data;

#define UUID "551087dd-4133-4097-87c6-79c27cde5c15"

static void finalize_lua_State(value L);

static struct custom_operations lua_State_ops =
{
  UUID,
  finalize_lua_State,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

#define lua_State_val(L) (*((lua_State **) Data_custom_val(L))) /* also l-value */

static void *custom_alloc ( void *ud,
                            void *ptr,
                            size_t osize,
                            size_t nsize )
{
    (void)ud;
    (void)osize;  /* not used */
    void *realloc_result = NULL;

    if (nsize == 0)
    {
        free(ptr);
        return NULL;
    }
    else
    {
        realloc_result = caml_stat_resize(ptr, nsize);
        return realloc_result;
    }
}


static void set_ocaml_data(lua_State *L, ocaml_data* data)
{
    lua_newtable(L);
    lua_pushstring(L, "ocaml_data");
    lua_pushlightuserdata(L, (void *)data);
    lua_settable(L, -3);
    lua_pushstring(L, UUID);
    lua_insert(L, -2);
    lua_settable(L, LUA_REGISTRYINDEX);
}


static ocaml_data * get_ocaml_data(lua_State *L)
{
    lua_pushstring(L, UUID);
    lua_gettable(L, LUA_REGISTRYINDEX);
    lua_pushstring(L, "ocaml_data");
    lua_gettable(L, -2);
    ocaml_data *info = (ocaml_data*)lua_touserdata(L, -1);
    lua_pop(L, 2);
    return info;
}


static int default_panic(lua_State *L)
{
    value *default_panic_v = caml_named_value("default_panic");

    ocaml_data *data= get_ocaml_data(L);

    return Int_val(caml_callback(*default_panic_v, data->state_value));
}


CAMLprim
value luaL_newstate__stub (value unit)
{
    CAMLparam1(unit);
    CAMLlocal1(v_L);

    value *default_panic_v = caml_named_value("default_panic");

    // create a fresh new Lua state
    lua_State *L = lua_newstate(custom_alloc, NULL);
    lua_atpanic(L, &default_panic);

    // alloc space for the register entry
    ocaml_data *data = (ocaml_data*)caml_stat_alloc(sizeof(ocaml_data));
    caml_register_global_root(&(data->panic_callback));
    data->panic_callback = *default_panic_v;

    // create a new Lua table for binding informations
    set_ocaml_data(L, data);

    // wrap the lua_State* in a custom object
    v_L = caml_alloc_custom(&lua_State_ops, sizeof(lua_State *), 1, 10);
    lua_State_val(v_L) = L;
    data->state_value = v_L;

    // return the lua_State value
    CAMLreturn(v_L);
}


static void finalize_lua_State(value L)
{
    lua_State *state = lua_State_val(L);

    ocaml_data *data = get_ocaml_data(state);
    caml_remove_global_root(&(data->panic_callback));
    caml_stat_free(data);
    lua_close(state);
}


CAMLprim
value luaL_openlibs__stub(value L)
{
  CAMLparam1(L);
  luaL_openlibs(lua_State_val(L));
  CAMLreturn(Val_unit);
}


int panic_wrapper(lua_State *L)
{
    ocaml_data *data = get_ocaml_data(L);
    return Int_val(caml_callback(data->panic_callback,  // callback
                                 data->state_value));   // Lua state
}


CAMLprim
value lua_atpanic__stub(value L, value panicf)
{
    CAMLparam2(L, panicf);
    CAMLlocal1(old_panicf);

    lua_State *state = lua_State_val(L);

    ocaml_data *data = get_ocaml_data(state);

    old_panicf = data->panic_callback;
    caml_remove_global_root(&(data->panic_callback));
    caml_register_global_root(&(data->panic_callback));
    data->panic_callback = panicf;
    lua_atpanic(state, panic_wrapper);

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
value lua_checkstack__stub(value L, value extra)
{
  CAMLparam2(L, extra);
  int retval = lua_checkstack(lua_State_val(L), Int_val(extra));
  if (retval == 0)
    CAMLreturn(Val_false);
  else
    CAMLreturn(Val_true);
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

CAMLprim
value lua_pushlstring__stub(value L, value s)
{
    CAMLparam2(L, s);
    lua_pushlstring(lua_State_val(L), String_val(s), caml_string_length(s));
    CAMLreturn(Val_unit);
}

