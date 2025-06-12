local typedefs = require "kong.db.schema.typedefs"

return {
  name = "jwt_policy_cookie_validator",
  fields = {
    { consumer = typedefs.no_consumer },
    { config = {
        type = "record",
        fields = {
          { secret = { type = "string", required = true } },
          { failure_url = { type = "string", required = false } },
          { required_permissions = {
              type = "array",
              required = false,
              default = {},
              elements = {
                type = "record",
                fields = {
                  { action = { type = "string", required = true } },
                  { leftOperand = { type = "string", required = true } },
                  { operator = { type = "string", required = true } },
                  { rightOperand = { type = "string", required = true } },
                }
              }
          }},
          { prohibited_targets = {
              type = "array",
              required = false,
              default = {},
              elements = {
                type = "record",
                fields = {
                  { action = { type = "string", required = true } },
                  { target = { type = "string", required = true } }
                }
              }
          }},
        },
    } }
  }
}
