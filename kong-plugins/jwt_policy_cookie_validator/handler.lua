local jwt_decoder = require "resty.jwt"
local kong = kong

local plugin = {
  PRIORITY = 1001,
  VERSION = "1.3.0"
}

-- Verifica que la política requerida exista exactamente en el JWT
local function policy_exists(user_policies, required)
  for _, policy in ipairs(user_policies) do
    if policy.action == required.action
      and policy.leftOperand == required.leftOperand
      and policy.operator == required.operator
      and policy.rightOperand == required.rightOperand
    then
      return true
    end
  end
  return false
end

-- Verifica que la prohibición exacta exista
local function prohibition_exists(user_prohibitions, target)
  for _, p in ipairs(user_prohibitions) do
    if p.action == target.action and p.target == target.target then
      return true
    end
  end
  return false
end

function plugin:access(conf)
  local cookie_header = kong.request.get_header("cookie")
  if not cookie_header then
    return kong.response.exit(302, nil, { ["Location"] = conf.failure_url })
  end

  local token = string.match(cookie_header, "auth_token=([^;]+)")
  if not token then
    return kong.response.exit(302, nil, { ["Location"] = conf.failure_url })
  end

  local jwt_obj = jwt_decoder:verify(conf.secret, token)
  if not jwt_obj.verified or (jwt_obj.payload.exp and tonumber(jwt_obj.payload.exp) < os.time()) then
    return kong.response.exit(302, nil, { ["Location"] = conf.failure_url })
  end

  local policies = jwt_obj.payload.policies or {}
  local permissions = policies.permission or {}
  local prohibitions = policies.prohibition or {}

  -- Validar que existan todas las policies requeridas literalmente
  if conf.required_permissions and type(conf.required_permissions) == "table" then
    for _, required in ipairs(conf.required_permissions) do
      if not policy_exists(permissions, required) then
        return kong.response.exit(403, { message = "Missing required permission policy." })
      end
    end
  end

  -- Verificar si existe alguna prohibición que coincida con las bloqueadas
  if conf.prohibited_targets and type(conf.prohibited_targets) == "table" then
    for _, prohibited in ipairs(conf.prohibited_targets) do
      if prohibition_exists(prohibitions, prohibited) then
        return kong.response.exit(403, { message = "Access denied due to prohibition policy." })
      end
    end
  end

  kong.log.debug("✅ JWT contiene todas las políticas requeridas para: ", jwt_obj.payload.sub)
  return
end

return plugin
