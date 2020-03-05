#include "hmi_adapter/lua_lib/hmi_adapter_client_lua_wrapper.h"

#include <iostream>

#include "common/constants.h"
#include "hmi_adapter/hmi_adapter_client.h"

#include "rpc/detail/log.h"

namespace lua_lib {
RPCLIB_CREATE_LOG_CHANNEL(HmiAdapterClientLuaWrapper)

int HmiAdapterClientLuaWrapper::create_SDLRemoteTestAdapter(lua_State *L) {
  LOG_INFO("{0}", __func__);
  luaL_checktype(L, 1, LUA_TTABLE);
  // Index -1(top) - table shm_params_array
  // Index -2 - table out_params
  // Index -3 - table in_params
  // Index -4 - RemoteClient instance
  // index -5 - Library table

  auto tcp_params = build_TCPParams(L);
  lua_pop(L, 1); // Remove value from the top of the stack
  // Index -1(top) - table in_params
  // Index -2 - RemoteClient instance
  // Index -3 - Library table

  RemoteClient **user_data =
      reinterpret_cast<RemoteClient **>(luaL_checkudata(L, 2, "RemoteClient"));

  if (nullptr == user_data) {
    std::cout << "RemoteClient was not found" << std::endl;
    return 0;
  }

  RemoteClient *client = *user_data;
  lua_pop(L, 1); // Remove value from the top of the stack
  // Index -1(top) - Library table

  try {
    HmiAdapterClient *qt_client = new HmiAdapterClient(client, tcp_params);

    // Allocate memory for a pointer to client object
    HmiAdapterClient **s =
        (HmiAdapterClient **)lua_newuserdata(L, sizeof(HmiAdapterClient *));
    // Index -1(top) - instance userdata
    // Index -2 - Library table

    *s = qt_client;
  } catch (std::exception &e) {
    std::cout << "Exception occurred: " << e.what() << std::endl;
    lua_pushnil(L);
    // Index -1(top) - nil
    // Index -2 - Library table

    return 1;
  }

  HmiAdapterClientLuaWrapper::registerSDLRemoteTestAdapter(L);
  // Index -1 (top) - registered SDLRemoteTestAdapter metatable
  // Index -2 - instance userdata
  // Index -3 - Library table

  lua_setmetatable(L, -2); // Set class table as metatable for instance userdata
  // Index -1(top) - instance table
  // Index -2 - Library table

  return 1;
}

int HmiAdapterClientLuaWrapper::destroy_SDLRemoteTestAdapter(lua_State *L) {
  LOG_INFO("{0}", __func__);
  auto instance = get_instance(L);
  delete instance;
  return 0;
}

void HmiAdapterClientLuaWrapper::registerSDLRemoteTestAdapter(lua_State *L) {
  LOG_INFO("{0}", __func__);
  static const luaL_Reg SDLRemoteTestAdapterFunctions[] = {
      {"connect", HmiAdapterClientLuaWrapper::lua_connect},
      {"write", HmiAdapterClientLuaWrapper::lua_write},
      {NULL, NULL}};

  luaL_newmetatable(L, "HmiAdapterClient");
  // Index -1(top) - SDLRemoteTestAdapter metatable

  lua_newtable(L);
  // Index -1(top) - created table
  // Index -2 : SDLRemoteTestAdapter metatable

  luaL_setfuncs(L, SDLRemoteTestAdapterFunctions, 0);
  // Index -1(top) - table with SDLRemoteTestAdapterFunctions
  // Index -2 : SDLRemoteTestAdapter metatable

  lua_setfield(L, -2,
               "__index"); // Setup created table as index lookup for  metatable
  // Index -1(top) - SDLRemoteTestAdapter metatable

  lua_pushcfunction(L,
                    HmiAdapterClientLuaWrapper::destroy_SDLRemoteTestAdapter);
  // Index -1(top) - destroy_SDLRemoteTestAdapter function pointer
  // Index -2 - SDLRemoteTestAdapter metatable

  lua_setfield(L, -2,
               "__gc"); // Set garbage collector function to metatable
  // Index -1(top) - SDLRemoteTestAdapter metatable
}

HmiAdapterClient *HmiAdapterClientLuaWrapper::get_instance(lua_State *L) {
  LOG_INFO("{0}", __func__);
  // Index 1 - lua instance

  HmiAdapterClient **user_data = reinterpret_cast<HmiAdapterClient **>(
      luaL_checkudata(L, 1, "HmiAdapterClient"));

  if (nullptr == user_data) {
    return nullptr;
  }
  return *user_data; //*((HmiAdapterClient**)ud);
}

std::vector<parameter_type>
HmiAdapterClientLuaWrapper::build_TCPParams(lua_State *L) {
  LOG_INFO("{0}", __func__);
  // Index -1(top) - table params

  lua_getfield(L, -1, "host"); // Pushes onto the stack the value params[host]
  // Index -1(top) - string host
  // Index -2 - table params

  const char *host = lua_tostring(L, -1);
  lua_pop(L, 1); // remove value from the top of the stack
  // Index -1(top) - table params

  lua_getfield(L, -1, "port");
  // Pushes onto the stack the value params[port]
  // Index -1(top) - number port
  // Index -2 - table params

  const int port = lua_tointeger(L, -1);
  lua_pop(L, 1); // Remove value from the top of the stack
  // Index -1(top) - table params

  std::vector<parameter_type> TCPParams;
  TCPParams.push_back(
      std::make_pair(std::string(host), constants::param_types::STRING));
  TCPParams.push_back(
      std::make_pair(std::to_string(port), constants::param_types::INT));

  return TCPParams;
}

int HmiAdapterClientLuaWrapper::lua_connect(lua_State *L) {
  LOG_INFO("{0}", __func__);
  // Index -1(top) - table instance

  auto instance = get_instance(L);
  instance->connect();
  return 0;
}

int HmiAdapterClientLuaWrapper::lua_write(lua_State *L) {
  LOG_INFO("{0}", __func__);
  // Index -1(top) - string data
  // Index -2 - table instance

  auto instance = get_instance(L);
  auto data = lua_tostring(L, -1);
  int result = instance->send(data);
  lua_pushinteger(L, result);
  return 1;
}

} // namespace lua_lib
