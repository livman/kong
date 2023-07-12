-- handler.lua

local kong = kong

local CustomHandler = {
  VERSION  = "1.0.0",
  PRIORITY = 20
}


function split(s, delimiter)
  local result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end

function getDiffTimeMs(startTime)
  local t = os.clock() 
  --kong.log("time last:", t)
  --kong.log("time diff:", t - startTime)
  return (t - startTime) * 1000
end


function CustomHandler:access(config)
  local startTime = os.clock()

  --kong.log("time start:", startTime)


  kong.log("forwarded ip:", kong.client.get_forwarded_ip())



  for k,item in pairs(config.headersCustom) do 
    local tmp = split(item, ":")
    kong.log("key:", tmp[1], "value:", tmp[2])
    ngx.req.set_header(tmp[1], tmp[2])
  end


  --kong.log(string.format("elapsed_time test: %.2fms", getDiffTimeMs(startTime)))

  --kong.log(config.some_array)
  
end


return CustomHandler
