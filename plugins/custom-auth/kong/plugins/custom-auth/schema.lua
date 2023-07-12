local typedefs = require "kong.db.schema.typedefs"

return {
  name = "custom-auth",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            authVerifyTokenEndpoint = {
              type     = "string",
              default  = "http://auth-api-service:8080/verifyToken",
            },
          },
        },
      },
    },
  },
}
