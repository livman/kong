local cache = kong.cache

local access = require "kong.plugins.custom-auth.access"

local CustomAuthHandler = {
  VERSION  = "1.0.0",
  PRIORITY = 10
}

--CustomAuthHandler.access = access

--local inspect = require('inspect')




function CustomAuthHandler:access(conf)

  --kong.log("In EchoHandler:accept(). self.echo_string is: " .. self.echo_string)

  kong.log(CustomAuthHandler.PRIORITY)



  local route = kong.router.get_route()
  local service = kong.router.get_service()

  --self.echo_string = kong.request.get_header(conf.requestHeader)

  --kong.log.inspect("get route: ", route)
  kong.log("get current service name: ", service.name)

  local headers = kong.request.get_headers()

  access.routeFilter(conf, headers)
  
end




return CustomAuthHandler
