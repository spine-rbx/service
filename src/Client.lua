local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = script.Parent.Parent

if RunService:IsServer() or not RunService:IsRunning() then
	return false
end

local Object = require(Packages.object)
local Net = require(Packages.net)
local Util = require(Packages.util)
local Promise = require(Packages.promise)

local Service = Object:Extend()

Service.ServiceList = {}
Service.Yielding = {}

function Service:Constructor(Folder: Folder, IsRoot: boolean)
	self._Instance = Folder
	self._Hidden = {}

	self._Connections = Util.Each(Folder, function(Child)
		local Name = Child.Name

		if Child:IsA("Folder") then
			self[Name] = Service:New(Child, false)
		else
			local NetType = Child:GetAttribute("SpineNetType")

			if NetType == 1 then
				self[Name] = Net.Client.RemoteSignal:New(Child)
			elseif NetType == 2 then
				self[Name] = Net.Client.RemotePipe:New(Child)
			elseif NetType == 3 then
				self[Name] = Net.Client.RemoteValue:New(Child)
			elseif NetType == 4 then
				self._Hidden[Name] = Net.Client.RemoteFunction:New(Child)
				self[Name] = function(_, ...)
					return self._Hidden[Name]:InvokeServer(...)
				end
			end
		end
	end, function(Child)
		local Name = Child.Name

		if self._Hidden[Name] then
			self._Hidden[Name]:Destroy()
			self[Name] = nil
		else
			self[Name]:Destroy()
			self[Name] = nil
		end
	end)

	self._Connections["Destroying"] = Folder.Destroying:Connect(function()
		self:Destroy()
	end)

	if IsRoot then
		self.ServiceList[Folder.Name] = self
		
		if self.Yielding[Folder.Name] ~= nil then
			for _,v in ipairs(self.Yielding[Folder.Name]) do
				coroutine.resume(v)
			end

			self.Yielding[Folder.Name] = nil
		end
	end
end

function Service:Destroy()
	for _,v in pairs(self.Connections) do
		v:Disconnect()
	end

	self._Connections = nil
	self._Hidden = nil
	self._Instance = nil
end

function Service.Get(Name: string)
	if Service.ServiceList[Name] then
		return Promise.resolve(Service.ServiceList[Name])
	end

	if Service.Yielding[Name] == nil then
		Service.Yielding[Name] = {}
	end

	return Promise.new(function(resolve)
		Service.Yielding[Name][#Service.Yielding[Name]+1] = coroutine.running()
		coroutine.yield()
		resolve(Service.ServiceList[Name])
	end)
end

Util.Each(ReplicatedStorage:WaitForChild("SpineServices"), function(Folder: Folder)
	Service:New(Folder, true)
end, function(Folder: Folder)
	Service.ServiceList[Folder.Name]:Destroy()
end)

return Service