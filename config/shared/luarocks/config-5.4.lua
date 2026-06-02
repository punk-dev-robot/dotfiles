-- LuaRocks configuration

rocks_trees = {
	{ name = "user", root = home .. "/.local/share/luarocks" },
	{ name = "system", root = "/usr/local" },
}
lua_interpreter = "lua5.4"
variables = {
	LUA_DIR = "/usr",
	LUA_BINDIR = "/usr/bin",
	LUA_INCDIR = "/usr/include/luajit-2.1",
}
local_by_default = true
