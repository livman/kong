-- schema.lua
local typedefs = require "kong.db.schema.typedefs"


return {
  name = "custom-header",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            headersCustom = {
              type = "array",
              elements = {
                type = "string",
              },
            },
          },
        },
      },
    },
  },
}
