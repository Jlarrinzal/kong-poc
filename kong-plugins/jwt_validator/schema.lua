local typedefs = require "kong.db.schema.typedefs"

return {
  name = "jwt_validator",
  fields = {
    { consumer = typedefs.no_consumer },
    { config = {
        type = "record",
        fields = {
          { secret = { type = "string", required = true } },
          { success_url = { type = "string", required = false }, },
          { failure_url = { type = "string", required = false }, },
          { domain = { type = "string", required = false }, },
        },
    } }
  }
}
