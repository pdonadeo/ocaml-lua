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
static pthread_mutex_t alloc_lock = PTHREAD_MUTEX_INITIALIZER;



/******************************************************************************/
/*****                         UTILITY FUNCTIONS                          *****/
/******************************************************************************/
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
        debug(6, "    custom_alloc: calling free(%p)\n", ptr);
        free(ptr);
        debug(6, "    custom_alloc: returning NULL\n");

        pthread_mutex_unlock(&alloc_lock);
        return NULL;
    }
    else
    {
        debug(5, "    custom_alloc: calling caml_stat_resize(%p, %d)\n", ptr, nsize);
        realloc_result = caml_stat_resize(ptr, nsize);
        debug(5, "    custom_alloc: returning %p\n", realloc_result);

        pthread_mutex_unlock(&alloc_lock);
        return realloc_result;
    }
}

static int default_gc(lua_State *L)
{
    debug(3, "default_gc(%p)\n", (void*)L);
    value *lua_ud = (value*)lua_touserdata(L, 1);
    caml_remove_global_root(lua_ud);
    return 0;
}

CAMLprim
value default_gc__stub(value L)
{
    CAMLparam1(L);
    int retval = default_gc(lua_State_val(L));
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
    lua_pushcfunction(L, default_gc);
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
    debug(3, "finalize_lua_State(value L)\n");

    lua_State *state = lua_State_val(L);

    push_lud_array(state);
    int table_pos = lua_gettop(state);
    lua_pushnil(state);  /* first key */
    while (lua_next(state, table_pos) != 0)
    {
        /* key at -2, value (light userdata) at -1 */
        value *ocaml_lud_value = (value*)lua_touserdata(state, -1);
        caml_remove_global_root(ocaml_lud_value);
        debug(4, "    caml_stat_free(%p)\n", (void*)ocaml_lud_value);
        caml_stat_free(ocaml_lud_value);
        lua_pop(state, 1);
    }

    ocaml_data *data = get_ocaml_data(state);
    caml_remove_global_root(&(data->panic_callback));
    caml_remove_global_root(&(data->state_value));
    caml_stat_free(data);
    lua_close(state);

    debug(4, "    EXIT finalize_lua_State(value L)\n");
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
value luaL_newstate__stub (value unit)
{
    CAMLparam1(unit);
    CAMLlocal2(v_L, v_L_mirror);

    value *default_panic_v = caml_named_value("default_panic");

    /* create a fresh new Lua state */
    lua_State *L = lua_newstate(custom_alloc, NULL);
    debug(3, "luaL_newstate__stub: calling lua_newstate -> %p\n", (void*)L);
    lua_atpanic(L, &default_panic);

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

