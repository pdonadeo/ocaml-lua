#include <string.h>
#include <stdarg.h>
#include <pthread.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/signals.h>

#include "stub.h"

/******************************************************************************/
/*****                          DATA STRUCTURES                           *****/
/******************************************************************************/
static void finalize_lua_State(value L);  /* Forward declaration */

static struct custom_operations lua_State_ops =
{
  UUID,
  finalize_lua_State,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static struct custom_operations default_lua_State_ops =
{
  DEFAULT_OPS_UUID,
  custom_finalize_default,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/******************************************************************************/
/*****                           GLOBAL LOCKS                             *****/
/******************************************************************************/
#ifndef ENABLE_LUAJIT
static pthread_mutex_t alloc_lock = PTHREAD_MUTEX_INITIALIZER;
#else
#warning KEEP IN MIND: ENABLING SUPPORT FOR LUAJIT, THREAD SAFETY IS LOST
#endif  /* ENABLE_LUAJIT */


/******************************************************************************/
/*****                         UTILITY FUNCTIONS                          *****/
/******************************************************************************/
#ifndef ENABLE_LUAJIT
static void *custom_alloc ( void *ud,
                            void *ptr,
                            size_t osize,
                            size_t nsize )
{
    (void)ud;
    (void)osize;  /* not used */
    void *realloc_result = NULL;

    pthread_mutex_lock(&alloc_lock);

    debug(5, "custom_alloc(%p, %p, %d, %d)\n", ud, ptr, osize, nsize);

    if (nsize == 0)
    {
        debug(6, "custom_alloc: calling free(%p)\n", ptr);
        free(ptr);
        debug(6, "custom_alloc: returning NULL\n");

        pthread_mutex_unlock(&alloc_lock);
        return NULL;
    }
    else
    {
        debug(6, "custom_alloc: calling caml_stat_resize(%p, %d)\n", ptr, nsize);
        realloc_result = caml_stat_resize(ptr, nsize);
        debug(6, "custom_alloc: returning %p\n", realloc_result);

        pthread_mutex_unlock(&alloc_lock);
        return realloc_result;
    }
}
#else   /* ENABLE_LUAJIT */
#warning KEEP IN MIND: ENABLING SUPPORT FOR LUAJIT, THREAD SAFETY IS LOST
#endif  /* ENABLE_LUAJIT */


/* While "closure_data_gc" and "default_gc" are the same function (see the
 * code), I still decided to keep them separate and copy&paste the code, to
 * leave me open to possible future differentiations.
 */
static int closure_data_gc(lua_State *L)
{
    debug(3, "closure_data_gc(%p)\n", (void*)L);
    value *ocaml_closure = (value*)lua_touserdata(L, 1);
    debug(5, "closure_data_gc: ocaml_closure == %p\n", (void*)ocaml_closure);
    caml_remove_global_root(ocaml_closure);
    debug(4, "closure_data_gc: RETURN 0\n");
    return 0;
}

static int default_gc(lua_State *L)
{
    debug(3, "default_gc(%p)\n", (void*)L);
    value *lua_ud = (value*)lua_touserdata(L, 1);
    debug(5, "default_gc: lua_ud == %p\n", (void*)lua_ud);
    caml_remove_global_root(lua_ud);
    debug(4, "default_gc: RETURN 0\n");
    return 0;
}

CAMLprim
value default_gc__stub(value L)
{
    debug(3, "default_gc__stub(%p)\n", (void*)L);
    CAMLparam1(L);
    int retval = default_gc(lua_State_val(L));
    debug(4, "default_gc__stub: RETURN %d\n", retval);
    CAMLreturn(Val_int(retval));
}

static void create_private_data(lua_State *L, ocaml_data* data)
{
    lua_newtable(L);                          /* Table (t) for our private data */
    lua_pushstring(L, "ocaml_data");
    lua_pushlightuserdata(L, (void *)data);
    lua_settable(L, -3);                      /* t["ocaml_data"] = our_private_data */

    lua_newtable(L);                          /* metatable for userdata used by lua_pushcfunction__stub */
    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, closure_data_gc);
    lua_settable(L, -3);

    lua_pushstring(L, "closure_metatable");
    lua_insert(L, -2);
    lua_settable(L, -3);                      /* t["closure_metatable"] = metatable_for_closures */

    /* Here the stack contains only 1 element, at index -1, the table t */

    lua_pushstring(L, "threads_array");
    lua_newtable(L);                          /* a table for copies of threads */
    lua_settable(L, -3);                      /* t["threads_array"] = table_for_threads */

    /* Here the stack contains only 1 element, at index -1, the table t */

    lua_pushstring(L, "light_userdata_array");
    lua_newtable(L);                          /* a table for copies of all light userdata */
    lua_settable(L, -3);                      /* t["light_userdata_array"] = table_for_l_ud */

    /* Here the stack contains only 1 element, at index -1, the table t */

    lua_newtable(L);                          /* metatable for userdata used by lua_newuserdata and companion */
    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, default_gc);
    lua_settable(L, -3);
    lua_pushstring(L, "userdata_metatable");
    lua_insert(L, -2);
    lua_settable(L, -3);                      /* t["userdata_metatable"] = metatable_for_userdata */

    /* Here the stack contains only 1 element, at index -1, the table t */

    lua_pushstring(L, UUID);
    lua_insert(L, -2);
    lua_settable(L, LUA_REGISTRYINDEX);       /* registry[UUID] = t */
}

static void finalize_lua_State(value L)
{
    debug(3, "finalize_lua_State(%p)\n", (void*)L);

    lua_State *state = lua_State_val(L);

    push_lud_array(state);
    int table_pos = lua_gettop(state);
    lua_pushnil(state);  /* first key */
    while (lua_next(state, table_pos) != 0)
    {
        /* key at -2, value (light userdata) at -1 */
        value *ocaml_lud_value = (value*)lua_touserdata(state, -1);
        caml_remove_global_root(ocaml_lud_value);
        debug(5, "finalize_lua_State: caml_stat_free(%p)\n", (void*)ocaml_lud_value);
        caml_stat_free(ocaml_lud_value);
        lua_pop(state, 1);
    }

    ocaml_data *data = get_ocaml_data(state);
    lua_close(state);
    caml_remove_global_root(&(data->panic_callback));
    caml_remove_global_root(&(data->state_value));
    caml_stat_free(data);
    debug(4, "finalize_lua_State: RETURN\n");
}

static int default_panic(lua_State *L)
{
    value *default_panic_v = caml_named_value("default_panic");
    ocaml_data *data = get_ocaml_data(L);
    return Int_val(caml_callback(*default_panic_v, data->state_value));
}


/******************************************************************************/
/*****                         LUA AUX API STUBS                          *****/
/******************************************************************************/

CAMLprim
value luaL_argcheck__stub (value L, value cond, value narg, value extramsg)
{
    CAMLparam4(L, cond, narg, extramsg);
    luaL_argcheck(  lua_State_val(L),
                    Bool_val(cond),
                    Int_val(narg),
                    String_val(extramsg)  );
    CAMLreturn(Val_unit);
}

CAMLprim
value luaL_argerror__stub (value L, value narg, value extramsg)
{
    CAMLparam3(L, narg, extramsg);
    luaL_argerror(lua_State_val(L), Int_val(narg), String_val(extramsg));
    CAMLreturn(Val_unit);
}

CAMLprim
value luaL_callmeta__stub (value L, value obj, value e)
{
    CAMLparam3(L, obj, e);
    int retval = luaL_callmeta(lua_State_val(L), Int_val(obj), String_val(e));
    if (retval == 0)
        CAMLreturn(Val_false);
    else
        CAMLreturn(Val_true);
}

STUB_STATE_INT_VOID(luaL_checkany, narg)

STUB_STATE_INT_INT(luaL_checkint, narg)

CAMLprim
value luaL_checklong__stub(value L, value narg)
{
    CAMLparam2(L, narg);
    long int retval = luaL_checklong(lua_State_val(L), Long_val(narg));
    CAMLreturn(Val_long(retval));
}

CAMLprim
value luaL_newstate__stub (value unit)
{
    CAMLparam1(unit);
    CAMLlocal2(v_L, v_L_mirror);

    debug(3, "luaL_newstate__stub: BEGIN\n");

    value *default_panic_v = caml_named_value("default_panic");

    /* create a fresh new Lua state */
#ifndef ENABLE_LUAJIT
    lua_State *L = lua_newstate(custom_alloc, NULL);
    debug(5, "luaL_newstate__stub: lua_newstate returned %p\n", (void*)L);
    debug(6, "    luaL_newstate__stub: calling lua_atpanic...");
    lua_atpanic(L, &default_panic);
    debug(6, " done!\n");
#else
    #warning KEEP IN MIND: ENABLING SUPPORT FOR LUAJIT, THREAD SAFETY IS LOST
    lua_State *L = luaL_newstate();
    debug(5, "luaL_newstate__stub: luaL_newstate returned %p\n", (void*)L);
    debug(6, "    luaL_newstate__stub: calling lua_atpanic...");
    lua_atpanic(L, &default_panic);
    debug(6, " done!\n");
#endif  /* ENABLE_LUAJIT */

    /* alloc space for the register entry */
    ocaml_data *data = (ocaml_data*)caml_stat_alloc(sizeof(ocaml_data));
    caml_register_global_root(&(data->panic_callback));
    data->panic_callback = *default_panic_v;

    /* wrap the lua_State* in a custom object */
    v_L = caml_alloc_custom(&lua_State_ops, sizeof(lua_State *), 1, 10);
    lua_State_val(v_L) = L;

    /* another value wrapping L for internal purposes */
    v_L_mirror = caml_alloc_custom(&default_lua_State_ops, sizeof(lua_State *), 1, 10);
    lua_State_val(v_L_mirror) = L;
    caml_register_global_root(&(data->state_value));
    data->state_value = v_L_mirror;

    /* create a new Lua table for binding informations */
    create_private_data(L, data);

    debug(4, "luaL_newstate__stub: RETURN %p\n", (void*)v_L);
    /* return the lua_State value */
    CAMLreturn(v_L);
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
value luaL_loadfile__stub(value L, value filename)
{
  CAMLparam2(L, filename);
  CAMLlocal1(status);

  status = Val_int(luaL_loadfile( lua_State_val(L),
                                  String_val(filename) ));
  CAMLreturn(status);
}


CAMLprim
value luaL_openlibs__stub(value L)
{
  CAMLparam1(L);
  luaL_openlibs(lua_State_val(L));
  CAMLreturn(Val_unit);
}

CAMLprim
value luaL_newmetatable__stub(value L, value tname)
{
  CAMLparam2(L, tname);
  CAMLlocal1(retval);

  retval = Val_int(luaL_newmetatable( lua_State_val(L), String_val(tname) ));
  if (retval == 0)
    CAMLreturn(Val_false);
  else
    CAMLreturn(Val_true);
}

CAMLprim
value luaL_getmetatable__stub(value L, value tname)
{
  CAMLparam2(L, tname);
  luaL_getmetatable(lua_State_val(L), String_val(tname));
  CAMLreturn(Val_unit);
}

CAMLprim
value luaL_gsub__stub(value L, value s, value p, value r)
{
  size_t len = 0;
  const char *value_from_lua;
  CAMLparam4(L, s, p, r);
  CAMLlocal1(ret_val);

  value_from_lua = luaL_gsub(lua_State_val(L), String_val(s), String_val(p), String_val(r));
  len = strlen(value_from_lua);

  ret_val = caml_alloc_string(len);
  char *retval_str = String_val(ret_val);
  memcpy(retval_str, value_from_lua, len);

  CAMLreturn(ret_val);
}

CAMLprim
value luaL_typerror__stub(value L, value narg, value tname)
{
  CAMLparam3(L, narg, tname);
  CAMLlocal1(retval);

  retval = Val_int(luaL_typerror(lua_State_val(L), Int_val(narg), String_val(tname)));

  CAMLreturn(retval);
}

CAMLprim
value luaL_checkstring__stub(value L, value narg)
{
  size_t len = 0;
  const char *value_from_lua;

  CAMLparam2(L, narg);
  CAMLlocal1(ret_val);

  value_from_lua = luaL_checkstring(lua_State_val(L), Int_val(narg));
  len = strlen(value_from_lua);
  ret_val = caml_alloc_string(len);
  char *s = String_val(ret_val);
  memcpy(s, value_from_lua, len);

  CAMLreturn(ret_val);
}

CAMLprim
value luaL_error__stub(value L, value message)
{
  CAMLparam2(L, message);
  luaL_error(lua_State_val(L), String_val(message));
  CAMLreturn(Val_unit);
}

CAMLprim
value luaL_getmetafield__stub(value L, value obj, value e)
{
  CAMLparam3(L, obj, e);
  CAMLlocal1(retval);

  retval = Val_int(luaL_getmetafield(lua_State_val(L), Int_val(obj), String_val(e)));

  if (retval == 0)
    CAMLreturn(Val_false);
  else
    CAMLreturn(Val_true);
}

STUB_STATE_INT_INT_INT(luaL_optinteger, narg, d)

CAMLprim
value luaL_optlong__stub(value L, value narg, value d)
{
    CAMLparam3(L, narg, d);
    long int retval = luaL_optlong(lua_State_val(L), Long_val(narg), Long_val(d));
    CAMLreturn(Val_long(retval));
}

STUB_STATE_INT_INT(luaL_ref, t)

CAMLprim
value luaL_findtable__stub(value L, value idx, value fname, value szhint)
{
    size_t len = 0;
    const char *value_from_lua;

    CAMLparam4(L, idx, fname, szhint);
    CAMLlocal2(ret_string, ret_option);

    value_from_lua = luaL_findtable(lua_State_val(L), Int_val(idx), String_val(fname), Int_val(szhint));
    if (value_from_lua == NULL)
    {
        return Val_int(0);
    }
    else
    {
        len = strlen(value_from_lua);
        ret_string = caml_alloc_string(len);
        char *retval_str = String_val(ret_string);
        memcpy(retval_str, value_from_lua, len);

        ret_option = caml_alloc(1, 0);
        Store_field(ret_option, 0, ret_string);

        CAMLreturn(ret_option);
    }
}

STUB_STATE_INT_INT_VOID(luaL_unref, t, ref)

STUB_STATE_INT_VOID(luaL_where, lvl)
