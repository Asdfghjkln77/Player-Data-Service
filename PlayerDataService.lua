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

-- Asserts to check if the module is present
assert(ErrorService, "Missing module: ErrorService")
assert(ProfileStore, "Missing module: ProfileStore")

-- Module
local PlayerDataService = {}

-- Settings
local DEFAULT_KEY_FORMAT = "Player_%d"

local MAX_RETRIES = 10
local RETRY_DELAY = 3

-- Asserts to check if the settins is valids
assert(MAX_RETRIES and typeof(MAX_RETRIES) == "number" and MAX_RETRIES % 1 == 0, "Invalid MAX_RETRIES value")
assert(RETRY_DELAY and typeof(RETRY_DELAY) == "number" and RETRY_DELAY % 1 == 0, "Invalid MAX_RETRIES value")

-- Types
export type TableTemplate = { [string]: any }

export type DataObjectType = "DataObject"
export type OrderedDataObjectType = "OrderedDataObject"

export type PlayerProfile = ProfileStore.Profile<T>

export type DataObject = {
	-- DataStore
	DataStore: typeof(ProfileStore.New()),

	--  String type
	ObjectType: DataObjectType | OrderedDataObjectType,
	
	-- Functions
	IsA: (self: DataObject, className: DataObjectType | OrderedDataObjectType) -> boolean,
	SetupPlayerForDataObject: (self: DataObject, player: Player, folder: Folder, autoSaveTime: number) -> (PlayerProfile, Folder),
	LoadPlayer: (self: DataObject, player: Player, folder: Folder) -> (),
	SavePlayer: (self: DataObject, player: Player, folder: Folder, endSession: boolean?) -> (),
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
	SetupPlayerForOrderedDataObject: (self: DataObject, player: Player, valueInstance: IntValue | NumberValue, autoSaveTime: number) -> Folder,
	LoadPlayer: (self: DataObject, player: Player, folder: Folder) -> (),
	SavePlayer: (self: DataObject, player: Player, folder: Folder, endSession: boolean?) -> (),
	GetAsync: (self: OrderedDataObject, player: Player) -> any,
	GetSortedAsync: (self: OrderedDataObject, isAncending: boolean, pageSize: number, minValue: number?, maxValue: number?) -> DataStorePages,
	SetAsync: (self: OrderedDataObject, player: Player) -> ()
}

-- Private EndSession function
local function EndSession(DataObj: DataObject, player: Player): ()
	-- Checks
	if not DataObj:IsA("DataObject") or not player then
		return 
	end
	
	-- End session
	local profile: PlayerProfile = DataObj.Profiles[player]
	if profile then
		profile:Save()
		profile:EndSession()
	end
end

local function HandleAutoSave(DataObject: DataObject | OrderedDataObject, player: Player, ins: Folder | NumberValue | IntValue, autoSaveTime: number)
	-- Auto-save loop
	if autoSaveTime then
		task.spawn(function()
			while player and player:IsDescendantOf(Players) do
				task.wait(autoSaveTime)
				DataObject:SavePlayer(player, ins, false)
			end
		end)
	end
	
	-- End session when player leaves
	player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(Players) then
			DataObject:SavePlayer(player, ins, true)
		end
	end)
end

-- Private ConstructDataObject function
local function ConstructDataObject(ObjectName: string, DataObjectType: DataObjectType | OrderedDataObjectType, defaultData: TableTemplate): ()
	-- Create DataObject
	local DataObject = setmetatable({}, {
		__index = PlayerDataService,
		__tostring = function()
			return ObjectName
		end,
	})
	
	-- Set DataObject properties
	DataObject.ObjectType = DataObjectType
	DataObject.SharedDataObjects = {}
	
	-- Set DataObject methods
	local isNormalDataObject = DataObjectType == "DataObject"
	if isNormalDataObject then
		DataObject.DataStore = ProfileStore.New(ObjectName, defaultData)
		DataObject.Profiles = {} -- [Player] = Profile
	else
		DataObject.DataStore = DataStoreService:GetOrderedDataStore(ObjectName)
	end
	
	-- Return DataObject
	return DataObject
end

-- PlayerDataService Constructor (defaultData won't be needed if the objectType is equal to "OrderedDataObject")
function PlayerDataService.GetDataStore(storeName: string, objectType: DataObjectType | OrderedDataObjectType, defaultData: TableTemplate): DataObject | OrderedDataObject
	-- Checks
	assert(storeName and typeof(storeName) == "string", "No store name provided or invalid type")
	assert(objectType and (typeof(objectType) == "string" and (objectType == "DataObject" or objectType == "OrderedDataObject")), "No ObjectType provided or invalid type")
	assert(objectType == "OrderedDataObject" or (defaultData and typeof(defaultData) == "table"), "Default data must be a table")
	
	return ConstructDataObject(storeName, objectType, defaultData)
end

-- Function that returns if the className is equal to the DataObject ObjectType
function PlayerDataService:IsA(className: DataObjectType | OrderedDataObjectType): boolean
	-- Checks
	assert(self, "No self provided or invalid type")
	
	return self.ObjectType == className
end

-- Setup Player DataFolder with the DataObject
function PlayerDataService:SetupPlayerForDataObject(player: Player, folder: Folder, autoSaveTime: number): (PlayerProfile, Folder)
	-- Checks
	assert(self, "No self provided or invalid type")
	assert(self:IsA("DataObject"), "Invalid type of DataStore for this function")
	
	-- Create Profile
	folder = folder:Clone()
	folder.Name = tostring(self)
	folder.Parent = player

	local profile: PlayerProfile? = self.DataStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	
	-- Load Profile
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
		
		HandleAutoSave(self, player, folder, autoSaveTime)

		return profile, folder
	end
	
	-- Failed to load profile
	warn("Failed to load profile for", player)
	player:Kick("Profile failed to load. Please rejoin.")
end

-- Setup Player DataFolder with the DataObject
function PlayerDataService:SetupPlayerForOrderedDataObject(player: Player, valueInstance: IntValue | NumberValue, autoSaveTime: number)
	-- Checks
	assert(self, "No self provided or invalid type")
	assert(self:IsA("OrderedDataObject"), "Invalid type of DataStore for this function")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided or invalid type")
	assert(valueInstance and (typeof(valueInstance) == "Instance" and (valueInstance:IsA("IntValue") or valueInstance:IsA("NumberValue"))), "No ValueInstance provided or invalid class")

	-- Create Profile
	HandleAutoSave(self, player, valueInstance, autoSaveTime)
	self:LoadPlayer(player, valueInstance)
end

-- Function that loads the player's data with the provided folder with ValueBases
function PlayerDataService:LoadPlayer(player: Player, ins: Folder | NumberValue | IntValue): ()
	-- Checks
	assert(self, "No self provided")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided or invalid type")
	assert(ins and (typeof(ins) == "Instance" and (ins:IsA("Folder") or ins:IsA("IntValue") or ins:IsA("NumberValue"))), "No Instance provided or invalid type")
	
	-- Checks
	local isNormalDataObject = self:IsA("DataObject")
	if isNormalDataObject then
		local profile: PlayerProfile? = self.Profiles and self.Profiles[player]
		
		if profile.Data then
			for key, value in pairs(profile.Data) do
				local valInstance = ins:FindFirstChild(key, true)
				if valInstance and valInstance:IsA("ValueBase") then
					valInstance.Value = value
				end
			end
			

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
function PlayerDataService:SavePlayer(player: Player, ins: Folder | NumberValue | IntValue, endSession: boolean?): ()
	-- Checks
	assert(self, "No self provided or invalid type")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided or invalid type")
	endSession = endSession or false
	
	local isNormalDataObject = self:IsA("DataObject")
	
	local dataToSave
	
	if isNormalDataObject then
		-- Get the profile
		local profile: PlayerProfile? = self.Profiles[player]
		if not profile then return end

		dataToSave = {}

		-- Write back from folder to profile
		for _, descendant in pairs(ins:GetDescendants()) do
			if descendant:IsA("ValueBase") then
				dataToSave[descendant.Name] = descendant.Value
			end
		end
		
		-- Save the profile
		self:SetAsync(player, dataToSave)		
		if endSession then
			profile:EndSession()
		end
	else
		dataToSave = ins.Value
		self:SetAsync(player, dataToSave)
	end
end

-- Function that gets the Sorted Ordered Data Store, useful for leaderboards (only works with OrderedDataObject)
function PlayerDataService:GetSortedAsync(isAncending: boolean, pageSize: number, minValue: number?, maxValue: number?): DataStorePages?
	-- Checks
	assert(self, "No self provided")
	assert(self:IsA("OrderedDataObject"), "Invalid type of DataStore for this function")
	assert(pageSize and typeof(pageSize) == "number", "No number provided")
	
	-- Values setting tom avoid errors
	isAncending = isAncending or false
	minValue = minValue or 0
	maxValue = maxValue or 100

	local success, result = ErrorService.TryToExecute(MAX_RETRIES, RETRY_DELAY, function()
		return self.DataStore:GetSortedAsync(isAncending, pageSize, minValue, maxValue)
	end)
	
	if success then
		return result
	end
	
	return warn(`Failed to get the sorted async from {tostring(self)} :`, result)
end

-- Function that gets the player's data with the provided player (defaultValue parameter is only used when DataObject is Ordered)
function PlayerDataService:GetAsync(player: Player): any
	-- Checks
	assert(self, "No self provided")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided")

	if self:IsA("DataObject") then
		-- Get the profile
		local profile: PlayerProfile? = self.Profiles and self.Profiles[player]
		if profile then
			return profile.Data
		end
		return warn(`Failed to get data from DataStore {tostring(self)} for Player  {player.Name} :`, profile.Data)
	else
		-- Get the key
		local key = string.format(DEFAULT_KEY_FORMAT, player.UserId)
		local success, result = ErrorService.TryToExecute(MAX_RETRIES, RETRY_DELAY, function()
			return self.DataStore:GetAsync(key)
		end)
		if success then
			return result or 0
		end
		return warn(`Failed to get data from DataStore {tostring(self)} for Player  {player.Name} :`, result)
	end
end

-- Function that sets the player's data with the provided player and value
function PlayerDataService:SetAsync(player: Player, value: {[string]: any} | number): ()
	-- Checks
	assert(self, "No self provided")
	assert(player and (typeof(player) == "Instance" and player:IsA("Player")), "No Player provided or invalid type")
	assert(value, "No value provided")

	local isNormalDataObject = self:IsA("DataObject") 

	if isNormalDataObject then
		-- Get the profile
		local profile = self.Profiles[player]
		
		-- This will make sure new value doesn't will overwrite other player's data values
		for key, val in pairs(value) do
			profile.Data[key] = val
		end
		
		-- Save the profile
		return print(`Succefully set {self.ObjectType} "{tostring(self)}" for player {player.Name}`, profile.Data)
	else
		-- OrderedDataStore can only store numbers
		if typeof(value) ~= "number" then
			error(`Cannot save non-numeric value to {self.ObjectType} ({tostring(self)}), Invalid value: {tostring(value)}`)
		end
		
		-- Get the key
		local playerKey = string.format(DEFAULT_KEY_FORMAT, player.UserId)
		local success, err = ErrorService.TryToExecute(MAX_RETRIES, RETRY_DELAY, function()
			self.DataStore:SetAsync(playerKey, value)
		end)
		
		-- Check if the value was setted
		if success then
			return print(`Succefully setted {self.ObjectType} "{tostring(self)}" for player {player.Name}`, value)
		else
			return warn(`Failed to set data to DataStore "{tostring(self)}" for player {player.Name} :`, err)
		end
	end
end

return PlayerDataService
