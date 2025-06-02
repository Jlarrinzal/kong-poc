local typedefs = require "kong.db.schema.typedefs"

return {
  name = "jwt_cookie_validator",
  fields = {
    { consumer = typedefs.no_consumer },
    { config = {
        type = "record",
        fields = {
          { secret = { type = "string", required = true } },
          { failure_url = { type = "string", required = false }, },
        },
    } }
  }
}
