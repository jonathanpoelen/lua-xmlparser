package = "xmlparser"
version = "2.2-0"
source = {
  url = "git://github.com/jonathanpoelen/lua-xmlparser",
  tag = "v2.2.0"
}
description = {
  summary = "Fast XML parser written entirely in Lua 5.",
  detailed = [[
    Enables parsing a XML file and converting it to a Lua table,
    which can be handled directly by your application.
  ]],
  homepage = "https://github.com/jonathanpoelen/lua-xmlparser",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    xmlparser = "xmlparser.lua"
  }
}
