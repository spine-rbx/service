local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = script.Parent.Parent

local Object = require(Packages.object)
local Net = require(Packages.net)
local Util = require(Packages.util)

local GlobalFolder = ReplicatedStorage:FindFirstChild("SpineServices") or Util.Make("Folder", {
	Name = "SpineServices",
	Parent = ReplicatedStorage,
})

local ServiceClient = Object:Extend()

local VALUE = newproxy()
local SIGNAL = newproxy()
local CALLBACK = newproxy()

function ServiceClient:Constructor(Name: string, Server)
	self._Name = Name
	self._Server = Server
	self._Hidden = {}

	getmetatable(self).__newindex = self.__newindex
end

function ServiceClient:_Make()
	rawset(self, "_Make", function() end)

	rawset(
		self,
		"_Instance",
		Util.Make("Folder", {
			Name = self._Name,
			Parent = GlobalFolder,
		})
	)
end

function ServiceClient:__newindex(i, v)
	self:_Make()

	if type(v) == "function" then
		if self._Hidden[i] == nil then
			self._Hidden[i] = Net.Server.RemoteCallback:New(self._Instance, i)
			self._Hidden[i].Callback = function(...)
				return v(self._Server, ...)
			end
		end
	elseif v == SIGNAL then
		v = Net.Server.RemoteSignal:New(self._Instance, i)
	elseif v == CALLBACK then
		v = Net.Server.RemoteCallback:New(self._Instance, i)
	elseif v == VALUE then
		v = Net.Server.RemoteValue:New(self._Instance, i)
	elseif v == nil and self._Hidden[i] ~= nil then
		self._Hidden[i]:Destroy()
		self._Hidden[i] = nil
	end

	rawset(self, i, v)
end

local Service = Object:Extend()

Service.VALUE = VALUE
Service.SIGNAL = SIGNAL
Service.CALLBACK = CALLBACK

function Service:Constructor(Name: string)
	self.Client = ServiceClient:New(Name, self)
end

export type ServiceClient = Object.Object<{
	_Name: string,
	_Server: Service,
	_Hidden: { [string]: any },
	_Instance: Instance,

	_Make: () -> (),
	__newindex: (self: ServiceClient, i: string, v: any) -> (),
}, (string, Service)>

export type Service = Object.Object<{
	Client: ServiceClient,

	VALUE: any,
	SIGNAL: any,
	CALLBACK: any,
}, (string)>

return Service :: Service
