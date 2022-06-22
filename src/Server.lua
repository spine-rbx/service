local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = script.Parent.Parent

local Object = require(Packages.object)
local Net = require(Packages.net)
local Util = require(Packages.util)

local GlobalFolder = Util.Make("Folder", {
	Name = "SpineServices",
	Parent = ReplicatedStorage,
})

local ServiceClient = Object:Extend()

function ServiceClient:Constructor(Name: string, Server)
	getmetatable(self).__newindex = self.__newindex

	self._Name = Name
	self._Server = Server
	self._Hidden = {}
	self.Signal = Net.Server.RemoteSignal
	self.Callback = Net.Server.RemoteCallback
	self.Value = Net.Server.RemoteValue
end

function ServiceClient:_Make()
	self._Make = function() end

	self._Instance = Util.Make("Folder", {
		Name = self._Name,
		Parent = GlobalFolder,
	})
end

function ServiceClient:__newindex(i, v)
	self:_Make()

	if type(v) == "function" then
		if self._Hidden[i] == nil then
			self._Hidden[i] = self.Callback:New(self._Instance, i)
			self._Hidden[i].Callback = function(...)
				v(self._Server, ...)
			end
		end
	elseif v == nil and self._Hidden[i] ~= nil then
		self._Hidden[i] = nil
	end

	rawset(self, i, v)
end

local Service = Object:Extend()

function Service:Constructor(Name: string)
	self.Client = ServiceClient:New(Name, self)
end

export type ServiceClient = Object.Object<{
	_Name: string,
	_Server: Service,
	_Hidden: {[string]: Net.ServerRemoteCallback},
	_Instance: Instance,

	Signal: Net.ServerRemoteSignal,
	Callback: Net.ServerRemoteCallback,
	Value: Net.ServerRemoteValue,

	_Make: () -> (),
	__newindex: (self: ServiceClient, i: string, v: any) -> (),
}, (Name: string, Server: Service)>

export type Service = Object.Object<{
	Client: ServiceClient,
}, (Name: string)>

return Service :: Service