local jwt_decoder = require "resty.jwt"
local kong = kong
local plugin = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}

function plugin:access(conf)
  local token = kong.request.get_query_arg("token")

  if not token then
    return kong.response.exit(302, nil, {
      ["Location"] = conf.failure_url
    })
  end

  local jwt_obj = jwt_decoder:verify(conf.secret, token)

  if not jwt_obj.verified then
    return kong.response.exit(302, nil, {
      ["Location"] = conf.failure_url
    })
  end

  local payload = jwt_obj.payload
  if payload.exp and tonumber(payload.exp) < os.time() then
    return kong.response.exit(302, nil, {
      ["Location"] = conf.failure_url
    })
  end

  return kong.response.exit(302, nil, {
    ["Location"] = conf.success_url
  })
end

return plugin