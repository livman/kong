package = "custom-header"
version = "0.1.0-1"
source = {

}
description = {

}
dependencies = {
}

local pluginName = "custom-header"

build = {
   type = "builtin",
   modules = {
      ["kong.plugins." ..pluginName..  ".handler"] = "kong/plugins/" ..pluginName.. "/handler.lua",
      ["kong.plugins." ..pluginName.. ".schema"] = "kong/plugins/" ..pluginName.. "/schema.lua"
   }
}
