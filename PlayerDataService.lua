--[[
	📦 PlayerDataService Module API
	=========================

		This module provides an abstract layer for managing player data using DataStores,
		both regular and ordered (for rankings, for example).

	🔧 Setup
	--------
		You can do it "manually" requiring the "PlayerDataService" module or using the "SetupHelper" (parented to the PlayerDataService)
	

	🧪 Available Types
	--------------------
		"DataObject" → Uses "ProfileStore" (new "ProfileService") to save complex data in folders with ValueBase
		"OrderedDataObject" → Uses OrderedDataStore for simple rankings with Number/IntValue

	🧱 Main Functions
	---------------------
		🔹 PlayerDataService.GetDataStore(storeName: string, objectType: "DataObject" | "OrderedDataObject", defaultData: table)
			→ Returns a handler object of the chosen type based on a store name and data template.

		🔹 <DataObject>:SetupPlayerForDataObject(player: Player, folder: Folder): Folder
			→ Creates session data for the player and loads the values ​​into the cloned folder.

		🔹 <OrderedDataObject>:SetupPlayerForOrderedDataObject(player: Player, valueInstance: NumberValue | IntValue)
			→ Loads the ordered DataStore value into a number instance.

		🔹 <DataObject | OrderedDataObject>:LoadPlayer(player: Player, instance: Folder | ValueBase)
			→ Loads the data from the instance (post-setup).

		🔹 <DataObject | OrderedDataObject>:SavePlayer(player: Player, instance: Folder | ValueBase)
			→ Saves the player data from the given instance.

		🔹 GetSortedAsync(pageSize: number, minValue?: number, maxValue?: number, isAscending?: boolean): DataStorePages
			→ Returns a page of sorted results (used with OrderedDataObject).
			
	📌 Notes
	--------------
		- The system uses reconciliation to ensure data integrity in the ProfileStore.
		- When exiting the game, data is automatically saved.
		- Kicks the player if the session does not load correctly.
		- The `IsA("DataObject")` or `IsA("OrderedDataObject")` method can be used for checks.

	🔒 Security and Reliability
	-----------------------------
		- Network call attempts (like GetSortedAsync) are encapsulated with retry to avoid failures.
		- Can be expanded with additional protections in the ErrorService.

	Made by [its_asdf]
]]

-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Sub-Services
local ErrorService = require(script.Parent.ErrorService)
local ProfileStore = require(script.Parent.ProfileStore)

-- Module
local PlayerDataService = {}

-- Types
export type TableTemplate = { [string]: any }

export type DataObjectType = "DataObject"
export type OrderedDataObjectType = "OrderedDataObject"

export type DataObject = {
	-- DataStore
	DataStore: typeof(ProfileStore.New()),

	--  String type
	ObjectType: DataObjectType | OrderedDataObjectType,
	
	-- Functions
	IsA: (self: DataObject, className: DataObjectType | OrderedDataObjectType) -> boolean,
	SetupPlayerForDataObject: (self: DataObject, player: Player, folder: Folder) -> Folder,
	LoadPlayer: (self: DataObject, player: Player, folder: Folder) -> (),
	SavePlayer: (self: DataObject, player: Player, folder: Folder) -> (),
	GetAsync: (self: OrderedDataObject, player: Player) -> any,
	SetAsync: (self: OrderedDataObject, player: Player) -> ()
}
export type OrderedDataObject = {
	-- DataStore
	DataStore: OrderedDataStore,
	
	--  String type
	ObjectType: DataObjectType | OrderedDataObjectType,

	-- Functions
	IsA: (self: DataObject, className: DataObjectType | OrderedDataObjectType) -> boolean,
	SetupPlayerForOrderedDataObject: (self: DataObject, player: Player, valueInstance: IntValue | NumberValue) -> Folder,
	LoadPlayer: (self: DataObject, player: Player, folder: Folder) -> (),
	SavePlayer: (self: DataObject, player: Player, folder: Folder) -> (),
	GetAsync: (self: OrderedDataObject, player: Player) -> any,
	GetSortedAsync: (self: OrderedDataObject, pageSize: number, minValue: number?, maxValue: number?, isAncending: boolean?) -> DataStorePages,
	SetAsync: (self: OrderedDataObject, player: Player) -> ()
}

-- Private EndSession function
local function EndSession(DataObj: DataObject, player: Player)
	if not DataObj:IsA("DataObject") or not player then
		return 
	end
	
	local profile: ProfileStore.Profile<T> = DataObj.Profiles[player]
	if profile then
		profile:Save()
		profile:EndSession()
	end
end

local function HandleAutoSave(DataObject: DataObject | OrderedDataObject, player: Player, ins: Folder | NumberValue | IntValue)
	player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(Players) then
			DataObject:SavePlayer(player, ins)
		end
	end)
end

-- Private ConstructDataObject function
local function ConstructDataObject(ObjectName: string, DataObjectType: DataObjectType | OrderedDataObjectType, defaultData: TableTemplate)
	local DataObject = setmetatable({}, {
		__index = PlayerDataService,
		__tostring = function()
			return ObjectName
		end,
	})
	
	DataObject.ObjectType = DataObjectType
	DataObject.SharedDataObjects = {}
	
	local isNormalDataObject = DataObjectType == "DataObject"
	if isNormalDataObject then
		DataObject.DataStore = ProfileStore.New(ObjectName, defaultData)
		DataObject.Profiles = {} -- [Player] = Profile
	else
		DataObject.DataStore = DataStoreService:GetOrderedDataStore(ObjectName)
	end
	
	return DataObject
end

-- PlayerDataService Constructor (defaultData won't be needed if the objectType is equal to "OrderedDataObject")
function PlayerDataService.GetDataStore(storeName: string, objectType: DataObjectType | OrderedDataObjectType, defaultData: TableTemplate)
	assert(storeName and typeof(storeName) == "string", "No store name provided or invalid type")
	assert(objectType and (typeof(objectType) == "string" and (objectType == "DataObject" or objectType == "OrderedDataObject")), "No ObjectType provided or invalid type")
	assert(objectType == "OrderedDataObject" or (defaultData and typeof(defaultData) == "table"), "Default data must be a table")
	
	return ConstructDataObject(storeName, objectType, defaultData)
end

-- Function that returns if the className is equal to the DataObject ObjectType
function PlayerDataService:IsA(className: DataObjectType | OrderedDataObjectType)
	assert(self, "No self provided or invalid type")
	
	return self.ObjectType == className
end

-- Setup Player DataFolder with the DataObject
function PlayerDataService:SetupPlayerForDataObject(player: Player, folder: Folder, autoConfig: boolean?): Folder
	assert(self, "No self provided or invalid type")
	assert(self:IsA("DataObject"), "Invalid type of DataStore for this function")

	folder = folder:Clone()
	folder.Name = tostring(self)
	folder.Parent = player

	local profile: ProfileStore.Profile<T>? = self.DataStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile() -- Apply default data to missing fields

		profile.OnSessionEnd:Connect(function()
			self.Profiles[player] = nil
			player:Kick("Profile session ended - Please rejoin")
		end)

		if player.Parent ~= Players then
			EndSession(self, player)
			return
		end

		self.Profiles[player] = profile
		-- Populate folder
		self:LoadPlayer(player, folder)
		
		HandleAutoSave(self, player, folder)

		return folder
	end

	warn("Failed to load profile for", player)
	player:Kick("Profile failed to load. Please rejoin.")
end

-- Setup Player DataFolder with the DataObject
function PlayerDataService:SetupPlayerForOrderedDataObject(player: Player, valueInstance: IntValue | NumberValue)
	assert(self, "No self provided or invalid type")
	assert(self:IsA("OrderedDataObject"), "Invalid type of DataStore for this function")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided or invalid type")
	assert(valueInstance and (typeof(valueInstance) == "Instance" and (valueInstance:IsA("IntValue") or valueInstance:IsA("NumberValue"))), "No ValueInstance provided or invalid class")
	
	HandleAutoSave(self, player, valueInstance)
	
	self:LoadPlayer(player, valueInstance)
end

-- Function that loads the player's data with the provided folder with ValueBases
function PlayerDataService:LoadPlayer(player: Player, ins: Folder | NumberValue)
	assert(self, "No self provided")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided or invalid type")
	assert(ins and (typeof(ins) == "Instance" and (ins:IsA("Folder") or ins:IsA("IntValue") or ins:IsA("NumberValue"))), "No Instance provided or invalid type")
	
	local isNormalDataObject = self:IsA("DataObject")
	if isNormalDataObject then
		--print("Cond1", isNormalDataObject)
		local profile: ProfileStore.Profile<T>? = self.Profiles and self.Profiles[player]
		
		if profile.Data then
			--print("Cond2", profile.Data)
			for key, value in pairs(profile.Data) do
				local valInstance = ins:FindFirstChild(key, true)
				if valInstance and valInstance:IsA("ValueBase") then
					valInstance.Value = value
				end
			end
			
			--print("Cond3", profile.Data)

			return print(`{self.ObjectType} "{tostring(self)}" loaded for player "{player.Name}":`, profile.Data)
		end
		return warn(`{self.ObjectType} "{tostring(self)}" failed to load for player "{player.Name}":`, profile.Data)
	else
		local data = self:GetAsync(player)
		if data then
			ins.Value = data
			return print(`{self.ObjectType} "{tostring(self)}" loaded for player "{player.Name}":`, data)
		end
		return print(`{self.ObjectType} "{tostring(self)}" loaded for player "{player.Name}":`, data)
	end
end

-- Function that saves the player's data with the provided Instance with ValueBases or not
function PlayerDataService:SavePlayer(player: Player, ins: Folder | ValueBase)
	assert(self, "No self provided or invalid type")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided or invalid type")
	
	local isNormalDataObject = self:IsA("DataObject")
	
	--print(tostring(self))
	
	local dataToSave
	
	if isNormalDataObject then
		--print("Cond1", isNormalDataObject)
		local profile: ProfileStore.Profile<T>? = self.Profiles[player]
		--print("Cond2", profile)
		if not profile then return end

		dataToSave = {}

		-- Write back from folder to profile
		for _, descendant in pairs(ins:GetDescendants()) do
			if descendant:IsA("ValueBase") then
				dataToSave[descendant.Name] = descendant.Value
			end
		end
		
		--print("Cond3", dataToSave)

		self:SetAsync(player, dataToSave)
		
		profile:EndSession()
	else
		dataToSave = ins.Value
		self:SetAsync(player, dataToSave)
	end
end

-- Function that gets the Sorted Ordered Data Store, useful for leaderboards (only works with OrderedDataObject)
function PlayerDataService:GetSortedAsync(pageSize: number, minValue: number?, maxValue: number?, isAncending: boolean?): DataStorePages?
	assert(self, "No self provided")
	assert(self:IsA("OrderedDataStore"), "Invalid type of DataStore for this function")
	assert(pageSize and typeof(pageSize) == "number", "No number provided")
	
	-- Values setting tom avoid errors
	isAncending = isAncending or false
	minValue = minValue or 0
	maxValue = maxValue or 100

	local success, result = ErrorService.TryToExecute(5, 1, function()
		return self.DataStore:GetSortedAsync(isAncending, pageSize, minValue, maxValue)
	end)
	
	if success then
		return result
	end
	
	return warn(`Failed to get the sorted async from {tostring(self)} :`, result)
end

-- Function that gets the player's data with the provided player (defaultValue parameter is only used when DataObject is Ordered)
function PlayerDataService:GetAsync(player: Player)
	assert(self, "No self provided")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided")
	
	--print(tostring(self))
	
	if self:IsA("DataObject") then
		local profile: ProfileStore.Profile<T>? = self.Profiles and self.Profiles[player]
		if profile then
			--print("Loaded", self, tostring(self), result)
			return profile.Data
		end
		return warn(`Failed to get data from DataStore {tostring(self)} for Player  {player.Name} :`, profile.Data)
	else
		local success, result = ErrorService.TryToExecute(5, 1, function()
			return self.DataStore:GetAsync("Player_" .. player.UserId)
		end)
		if success then
			return result or 0
		end
		return warn(`Failed to get data from DataStore {tostring(self)} for Player  {player.Name} :`, result)
	end
end

-- Function that sets the player's data with the provided player and value
function PlayerDataService:SetAsync(player: Player, value: {[string]: any} | number)
	assert(self, "No self provided")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided or invalid type")
	assert(value, "No value provided")

	local isNormalDataObject = self:IsA("DataObject")
	
	--print(tostring(self))

	if isNormalDataObject then
		--print("Cond1")
		local profile = self.Profiles[player]
		--print("Cond2", profile)
		
		for key, val in pairs(value) do -- This will make sure new value doesn't will overwrite other player's data values
			profile.Data[key] = val
		end
		
		--print("Cond3", profile.Data)

		return print(`Succefully setted {self.ObjectType} "{tostring(self)}" for player {player.Name}`, profile.Data)
	else
		-- OrderedDataStore can only store numbers
		if typeof(value) ~= "number" then
			return warn(`Cannot save non-numeric value to {self.ObjectType} ({tostring(self)}), Invalid value: {tostring(value)}`)
		end

		local success, err = ErrorService.TryToExecute(5, 1, function()
			self.DataStore:SetAsync("Player_" .. player.UserId, value)
		end)

		if success then
			return print(`Succefully setted {self.ObjectType} "{tostring(self)}" for player {player.Name}`, value)
		else
			return warn(`Failed to set data to DataStore "{tostring(self)}" for player {player.Name} :`, err)
		end
	end
end

return PlayerDataService
