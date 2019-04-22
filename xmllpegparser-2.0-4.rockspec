package = "xmllpegparser"
version = "2.0-4"
source = {
  url = "git://github.com/jonathanpoelen/lua-xmlparser",
  tag = "v2.0.4"
}
description = {
  summary = "An Fast XML Parser written with lpeg.",
  detailed = [[
    Enables parsing an XML file and converting it to a Lua table,
    which can be handled directly by your application.
  ]],
  homepage = "https://github.com/jonathanpoelen/lua-xmlparser",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "lpeg >= 1.0"
}
build = {
  type = "builtin",
  modules = {
    xmllpegparser = "xmllpegparser.lua"
  }
}
