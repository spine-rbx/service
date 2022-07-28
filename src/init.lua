local RunService = game:GetService("RunService")

local LOCKED_TABLE = setmetatable({}, {__index = function()
	error("Attempt to access service across the client-server boundary.")
end})

--- @class Service
--- @prop Server !! [ServerService](/api/serverservice)
--- @prop Client !! [ClientService](/api/clientservice)

return {
	Server = if RunService:IsServer() and RunService:IsRunning() then require(script.Server) else LOCKED_TABLE,
	Client = if not RunService:IsServer() and RunService:IsRunning() then require(script.Client) else LOCKED_TABLE,
}