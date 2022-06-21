local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = script.Parent.Parent

if not RunService:IsServer() or not RunService:IsRunning() then
	return false
end

local Object = require(Packages.Object)
local Net = require(Packages.Net)
local Util = require(Packages.Util)

local Folder = Object:Extend()

function Folder:Constructor(Parent, Name)
	self._Parent = Parent
	self._Name = Name

	self._Hidden = {}

	self.DELETE = newproxy()
	self.SIGNAL = newproxy()
	self.VALUE = newproxy()
	self.CALLBACK = newproxy()

	getmetatable(self).__newindex = self.__newindex
end

function Folder:_Make()
	self._Make = function() end

	self._Instance = Util.Make("Folder", {
		Name = self._Name,
		Parent = self._Parent,
	})
end

function Folder:__index(i)
	self:_Make()
	local NewFolder = Folder:New(self._Instance, i)
	rawset(self, i, NewFolder)
	return NewFolder
end

function Folder:__newindex(i, v)
	self:_Make()

	if v == self.DELETE then
		rawset(self, i, nil)
		return
	elseif v == self.SIGNAL then
		rawset(self, i, Net.Server.RemoteSignal:New(self._Instance, i))
		return
	elseif v == self.VALUE then
		rawset(self, i, Net.Server.RemoteValue:New(self._Instance, i, nil))
		return
	elseif v == self.CALLBACK then
		rawset(self, i, Net.Server.RemoteCallback:New(self._Instance, i))
		return
	end

	local tv = typeof(v)
	local Hidden = self._Hidden[i]

	if tv == "function" then
		if Hidden ~= nil then
			if getmetatable(Hidden).__parent ~= Net.Server.RemoteCallback then
				Hidden:Destroy()
			end
		else
			self._Hidden[i] = Net.Server.RemoteCallback:New(self._Instance, i)
			self._Hidden[i].Callback = function(...)
				return rawget(self, i)(...)
			end
		end
	else
		if Hidden ~= nil then
			if getmetatable(Hidden).__parent ~= Net.Server.RemoteValue then
				Hidden:Destroy()
			else
				Hidden:Set(v)
			end
		else
			self._Hidden[i] = Net.Server.RemoteValue:New(self._Instance, i, v)
		end
	end

	rawset(self, i, v)
end

local Service = Object:Extend()

local GlobalParent = Util.Make("Folder", {
	Name = "SpineServices",
	Parent = ReplicatedStorage,
})

function Service:Constructor(Name: string)
	self.Client = Folder:New(GlobalParent, Name)
end

export type ServiceFolder = Object.Object<{
	_Make: (self: ServiceFolder) -> (),
	__index: (self: ServiceFolder, i: any) -> (any),
	__newindex: (self: ServiceFolder, i: any, v: any) -> (),

	DELETE: any,
	SIGNAL: any,
	VALUE: any,
	CALLBACK: any,

	_Parent: Instance,
	_Name: string,
	_Hidden: {[any]: any},
}, (Parent: Instance, Name: string)>

export type Service = Object.Object<{
	Client: ServiceFolder,
}, (Name: string)>

return Service