local secret = "clave-super-secreta"

local function base64url_decode(input)
  input = input:gsub('-', '+'):gsub('_', '/')
  local pad = #input % 4
  if pad > 0 then
    input = input .. string.rep('=', 4 - pad)
  end
  return ngx.decode_base64(input)
end

local function decode_json(s)
  local ok, res = pcall(function() return assert(loadstring("return " .. s))() end)
  return ok and res or nil
end

local function hmac_sha256(key, msg)
  return ngx.hmac_sha256(key, msg)
end

local function validar_jwt(token)
  local header_b64, payload_b64, signature_b64 = token:match("([^%.]+)%.([^%.]+)%.([^%.]+)")
  if not header_b64 or not payload_b64 or not signature_b64 then
    return false, "Token malformado"
  end

local header_json = base64url_decode(header_b64)
if not header_json or not header_json:match('"alg"%s*:%s*"HS256"') then
  return false, "Algoritmo no permitido"
end

local payload_json = base64url_decode(payload_b64)
if not payload_json then
  return false, "Payload no valido"
end

local exp_str = payload_json:match('"exp"%s*:%s*(%d+)')
local exp = tonumber(exp_str)
if not exp then
  return false, "Campo 'exp' no encontrado"
end

if exp < os.time() then
  return false, "Token expirado"
end

  local signing_input = header_b64 .. "." .. payload_b64
  local signature = ngx.hmac_sha256(secret, signing_input)
  local signature_b64_calc = ngx.encode_base64(signature):gsub('+', '-'):gsub('/', '_'):gsub('=+$', '')

  if signature_b64_calc ~= signature_b64 then
    return false, "Firma invalida"
  end

  return true
end

local args = ngx.req.get_uri_args()
local jwt = args["token"]
if not jwt then
  return kong.response.exit(401, "Token no enviado")
end

local ok, err = validar_jwt(jwt)
if not ok then
  ngx.log(ngx.ERR, "JWT invalido: ", err)
  return kong.response.exit(401, "JWT invalido: " .. err)
end

kong.response.set_header("Set-Cookie", "token="..jwt.."; Domain=grafana-poc; Path=/; HttpOnly")
return kong.response.exit(302, "", { ["Location"] = "http://grafana-poc.test:8000" })
