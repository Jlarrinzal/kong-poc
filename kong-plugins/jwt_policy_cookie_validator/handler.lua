local jwt_decoder = require "resty.jwt"
local http = require "resty.http"
local cjson = require "cjson"
local kong = kong

local plugin = {
  PRIORITY = 1001,
  VERSION = "1.0.0"
}

function plugin:access(conf)
  kong.log.err("🧪 Entrando en jwt_policy_cookie_validator plugin")
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

  -- 🔒 Validación de IP externa
  local client_ip = kong.client.get_ip()
  local domain = kong.request.get_host()

  local httpc = http.new()

  -- 1️⃣ Validación de IP
  local res_ip, err_ip = httpc:request_uri("http://192.168.1.41:5005/validate-ip", {
    method = "POST",
    body = cjson.encode({
      ip = client_ip,
      domain = domain
    }),
    headers = {
      ["Content-Type"] = "application/json"
    }
  })

  if not res_ip then
    kong.log.err("Error contacting validate-ip: ", err_ip)
    return kong.response.exit(500, "Error validating IP")
  end

  local body_ip = cjson.decode(res_ip.body)
  if not body_ip.allowed then
    kong.log.warn("🚫 IP ", client_ip, " no permitida para el dominio ", domain)
    return kong.response.exit(403, "Access denied: your IP is not allowed")
  end

  -- 2️⃣ Validación de límite de peticiones
  local res_req, err_req = httpc:request_uri("http://192.168.1.41:5005/validate-request", {
    method = "POST",
    body = cjson.encode({
      ip = client_ip,
      domain = domain
    }),
    headers = {
      ["Content-Type"] = "application/json"
    }
  })

  if not res_req then
    kong.log.err("Error contacting validate-request: ", err_req)
    return kong.response.exit(500, "Error validating request limit")
  end

  local body_req = cjson.decode(res_req.body)
  if not body_req.allowed then
    kong.log.warn("🚫 Peticiones agotadas para ", client_ip, " en ", domain)
    return kong.response.exit(429, "Request limit exceeded")
  end

  kong.log.debug("✅ IP permitida y request contabilizada correctamente")
end

return plugin