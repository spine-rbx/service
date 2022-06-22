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
Service.Promises = {}

function Service:Constructor(Folder: Folder)
	self._Folder = Folder

	self._Connections = Util.Each(Folder, function(Child)
		local SpineNetType = Child:GetAttribute("SpineNetType")

		if SpineNetType == 1 then
			self[Child.Name] = Net.Client.RemoteSignal:New(Child)
		elseif SpineNetType == 2 then
			self[Child.Name] = Net.Client.RemoteCallback:New(Child)
		elseif SpineNetType == 3 then
			self[Child.Name] = Net.Client.RemoteValue:New(Child)
		end
	end, function(Child)
		self[Child.Name]:Destroy()
		self[Child.Name] = nil
	end)

	Service.ServiceList[Folder.Name] = self

	if Service.Yielding[Folder.Name] then
		coroutine.resume(Service.Yielding[Folder.Name])
		Service.Yielding[Folder.Name] = nil
	end
end

function Service:Destroy()
	self._Connections:Disconnect()
	self._Connections = nil
	self._Folder = nil
	Service.ServiceList[self._Folder.Name] = nil
end

function Service.GetService(Name: string): Promise<Service>
	if Service.Promises[Name] then
		return Service.Promises[Name]
	end

	if Service.ServiceList[Name] then
		return Promise.resolve(Service.ServiceList[Name])
	end

	Service.Promises[Name] = Promise.new(function(resolve)
		Service.Yielding[Name] = coroutine.running()
		coroutine.yield()
		Service.Promise[Name] = nil
		resolve(Service.ServiceList[Name])
	end)

	return Service.Promises[Name]
end

Util.Each(ReplicatedStorage:WaitForChild("SpineServices"), function(Folder: Folder)
	Service:New(Folder)
end, function(Folder: Folder)
	Service.ServiceList[Folder.Name]:Destroy()
end)

export type Service = Object.Object<{
	_Folder: Folder,
	_Connections: {[string]: RBXScriptConnection|() -> ()},

	[string]: Net.Client.RemoteSignal|Net.Client.RemoteCallback|Net.Client.RemoteValue,

	GetService: (Name: string) -> Promise<Service>,
	Destroy: (self: Service) -> (),
}>

return Service