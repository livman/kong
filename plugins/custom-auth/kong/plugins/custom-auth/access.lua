local _M = { conf = {} }
local http = require "resty.http"
local pl_stringx = require "pl.stringx"
local cjson = require "cjson.safe"

local jwt = require "resty.jwt"
local inspect = require('inspect')

local emptyJson = "{}"

function _M.error_response(res_body, status)
    ngx.header['Content-Type'] = 'application/json'
    ngx.status = status
    ngx.say(res_body)
    ngx.exit(status)
end

function _M.success_response(res_body, status)
    ngx.header['Content-Type'] = 'application/json'
    ngx.status = status
    ngx.say(res_body)
    ngx.exit(status)
end

function _M.response(res_body, status)
    ngx.header['Content-Type'] = 'application/json'
    ngx.status = status
    ngx.say(res_body)
    ngx.exit(status)
end

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function _M.verify_access_token(access_token, config)
    print("access token : " .. access_token)
    --local key = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAk9HBsVNzDO0nwbCzqXvqTjOKU0MQqn/E3pHt4COhtzoFnOzZHd1Chd+/df45OBn9Obrug/zAXoZxmaq1vKf0q62E8xSt/u5siaShD1+Nw4UQVyB3L7pvunDkIv3LdEG0ML9wK+U+K002mPQIcrX/oEC80HNSKhGXoQ84D+/fB5K/zcgJG733lr1GnFTelfzTal8YNUl60NhDBd2UhZQY/Pg8tUPr42cvACi5Ld8vdKBISLnfYgN7SN2mrRk6xPZc+cchWcVWx2ZGWpk3DF4y6QsYGFFWyQCH7f43qWQnBguJ2EyIfcIVtG91kObVtsrWpHzJ0DPT5mT2ZKoCCyjwVQIDAQAB\n-----END PUBLIC KEY-----"
    local key = "-----BEGIN PUBLIC KEY-----\n".. config.keycloakPubKey .."\n-----END PUBLIC KEY-----"
    local jwt_obj = jwt:verify(key, access_token)
    kong.log.inspect("jwt_obj: ", jwt_obj)
    kong.log.inspect("verified: ", jwt_obj.verified)
    jwt_obj.userId = jwt_obj.payload.sub
    return jwt_obj
end

function _M.getDiffTimeMs(startTime)
    return (os.clock() - startTime) * 1000
end




function _M.getAdminToken(config)
    local httpc = http:new()

    local param = "client_id=admin-cli&grant_type=password&username=".. config.keycloakAdminUser .."&password=".. config.keycloakAdminPassword
    local res, err = httpc:request_uri(config.keycloakEndpoint .."/auth/realms/master/protocol/openid-connect/token", {
        method = "POST",
        ssl_verify = false,
        body = param,
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })

    local res_data = cjson.decode(res.body)

    kong.log.inspect("get admin token: ", res_data)

    if res_data.access_token then
        return res_data.access_token
    end

    return nil
end



function _M.searchUser(reqBody, accessTokenAdmin, config)

    local res, err = httpc:request_uri(config.keycloakEndpoint .."/auth/admin/realms/".. config.keycloakRealms .."/users?briefRepresentation=true&first=0&max=20&search=", {
        method = "GET",
        ssl_verify = false,
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer ".. accessTokenAdmin,
        }
    })

end


function _M.getJsonBody(conf)
    ngx.req.read_body()
    local body_json = ngx.req.get_body_data()
    if body_json == nil then
        local response_data = '{"message": "Requred data"}'
        _M.response(response_data, 400)
    end
    --kong.log("json body req: ", body_json)
    local reqBody = cjson.decode(body_json)
    return reqBody
end

function _M.validateToken(accessToken, config, headers)
    local startTime = os.clock()

    local httpc = http:new()

    local bodyParam = '{"accessToken": "'.. accessToken ..'"}'

    local res, err = httpc:request_uri(config.authVerifyTokenEndpoint, {
        method = "POST",
        body = bodyParam,
        ssl_verify = false,
        headers = {
            ["Content-Type"] = "application/json",
            ["Uber-Trace-Id"] = headers.uber_trace_id
        }
    })
    local res_data = cjson.decode(res.body)

    kong.log("res status: ", res.status)


    kong.log("validateToken keycloak: ", string.format(" %.2fms", _M.getDiffTimeMs(startTime) ))

    if res.status ~= 200 then
        local response_data = '{"code": ' .. ngx.HTTP_UNAUTHORIZED .. ',"data": '.. emptyJson ..'}'
        _M.response(response_data, ngx.HTTP_UNAUTHORIZED)
    end

    local auth_data = res_data.data

    if ( auth_data.email == cjson.null ) then
        kong.log("email is null")
        auth_data.email = ""
    end

    --kong.log("response validate token: ", res_data)

    kong.log("User-Id: ", auth_data.userId)
    kong.log("Username: ", auth_data.username)
    kong.log("Email: ", auth_data.email)

    --res_data = res_data.data
    auth_data.verified = true


    return auth_data
end

function _M.routeFilter(conf, headers)
    _M.conf = conf
    -- verfiy auth
    local access_token = ngx.req.get_headers()["Authorization"]
    if not access_token then
        local response_data = '{"code": '.. ngx.HTTP_UNAUTHORIZED ..',"data": {}}'
        _M.response(response_data, ngx.HTTP_UNAUTHORIZED)
    end

    --kong.log("acccess token from req: ", access_token)

    local token = split(access_token, " ")

    local res = nil

    res = _M.validateToken(token[2], _M.conf, headers)

    if res.verified ~= true then
        local response_data = '{"code": '.. ngx.HTTP_UNAUTHORIZED ..',"data": {}}'
        _M.response(response_data, ngx.HTTP_UNAUTHORIZED)
    end

    ngx.req.clear_header("Authorization")
    ngx.req.set_header("User-Id", res.userId)
    ngx.req.set_header("Username", res.username)
    ngx.req.set_header("Email", res.email)
    --ngx.req.set_header("tenantId", _M.conf.keycloakTenantId)

    --kong.service.request.clear_header("Authorization")
    --kong.service.request.set_header("User-Id", res.userId)
end


return _M