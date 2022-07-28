local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = script.Parent.Parent

local Object = require(Packages.object)
local Net = require(Packages.net)
local Util = require(Packages.util)
local Promise = require(Packages.promise)

--- @class ClientService
--- @extends Object
--- This is one of those classes that isn't explained very well
--- by simple API documentation. I suggest you read the topic about
--- services.
local Service = Object:Extend()

--- @prop ServiceList !! { [string]: [ClientService](/api/clientservice) }
Service.ServiceList = {}

--- @prop Yielding !! { [string]: thread }
Service.Yielding = {}

--- @prop Promises !! { [string]: Promise }
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

--- @static GetService
--- @param Name !! string !! 
--- @return [Promise](/api/promise) !! A promise that resolves with the service.
function Service.GetService(Name: string): Promise.Promise
	if Service.Promises[Name] then
		return Service.Promises[Name]
	end

	if Service.ServiceList[Name] then
		return Promise.Resolve(Service.ServiceList[Name])
	end

	Service.Promises[Name] = Promise:New(function(resolve)
		Service.Yielding[Name] = coroutine.running()
		coroutine.yield()
		Service.Promise[Name] = nil
		resolve(Service.ServiceList[Name])
	end)

	return Service.Promises[Name]
end

Util.Each(ReplicatedStorage:WaitForChild("SpineServices"), function(Folder)
	Service:New(Folder)
end, function(Folder)
	Service.ServiceList[Folder.Name]:Destroy()
end)

export type Service = Object.Object<{
	_Folder: Folder,
	_Connections: {[string]: RBXScriptConnection|() -> ()},

	[string]: any,

	GetService: (Name: string) -> (Promise.Promise),
	Destroy: (self: Service) -> (),
}>

return Service :: Service