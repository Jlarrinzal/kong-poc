local jwt_decoder = require "resty.jwt"
local kong = kong

local plugin = {
  PRIORITY = 1001,
  VERSION = "1.0.0"
}

function plugin:access(conf)
  local cookie_header = kong.request.get_header("cookie")
  if not cookie_header then
    return kong.response.exit(302, nil, {
      ["Location"] = conf.failure_url
    })
  end

  local token = string.match(cookie_header, "auth_token=([^;]+)")
  if not token then
    return kong.response.exit(302, nil, {
      ["Location"] = conf.failure_url
    })
  end

  local jwt_obj = jwt_decoder:verify(conf.secret, token)
  if not jwt_obj.verified or (jwt_obj.payload.exp and tonumber(jwt_obj.payload.exp) < os.time()) then
    return kong.response.exit(302, nil, {
      ["Location"] = conf.failure_url
    })
  end

  kong.log.debug("✅ JWT cookie valid for user: ", jwt_obj.payload.sub)
  return
end

return plugin
