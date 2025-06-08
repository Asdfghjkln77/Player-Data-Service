--[[
	SetupHelper - Mini API
	-------------------------
	🔧 Purpose:
		Plug-and-Play module to quickly run the script

	📦 Functions:

		🔹 SetupHelper:GetDataObject(storeName: string, defaultData: table) -> DataObject
			→ Returns a new DataObject from PlayerDataService

		🔹 SetupHelper:GetOrderedDataObjectListFromFolder(folder: Folder) -> OrderedDataObjectList
			→ Iterates over a folder instance and returns a OrderedDataObjectList
			
		🔹 SetupHelper:ConvertFolderToTableTemplate(folder: Folder) -> table
			-> Iterates over a folder instance and returns a "{ [string]: any }" table
		
		🔹 SetupHelper:SetupPlayerForOrderedDataObjectList(player: Player, list: OrderedDataObjectList)
			→ Iterates over the list and setup the OrderedDataObject for the player

	🧠 Types:

		type OrderedDataObjectList = {
			OriginalFolder: Folder,
			[PlayerDataService.OrderedDataObject]: {
				ValueInstance: NumberValue | IntValue
			}
		}

	📁 Requirements:
		Must be the PlayerDataService's child in the hierarchy

	✅ Use example: 
		```lua
		-- Services
		local Players = game:GetService("Players")

		-- Module References
		local dataModule = path.to.PlayerDataService

		-- Sub-Services
		local PlayerDataService = require(dataModule)
		local PlayerDataService_SetupHelper = require(dataModule.SetupHelper)

		-- DataStore References
		local dataFolder = path.to.DataFolder -- Remove if you don't want a DataStore
		local tableTemplate = PlayerDataService.Helpers:ConvertFolderToTableTemplate(dataFolder) -- Remove if you don't want a DataStore
		local data = PlayerDataService_SetupHelper:GetDataObject(dataFolder.Name, tableTemplate) -- Remove if you don't want a DataStore

		-- OrderedDataStore References
		local dataFolder2 = path.to.DataFolder2 -- Remove if you don't want a OrderedDataStore
		local orderedDataList = PlayerDataService_SetupHelper:GetOrderedDataObjectListFromFolder(dataFolder2) -- Remove if you don't want a OrderedDataStore

		-- Function that handles when a player is added
		local function OnPlayerAdded(player: Player)
			data:SetupPlayerForDataObject(player, dataFolder) -- Remove if you don't want a DataStore
			PlayerDataService_SetupHelper:SetupPlayerForOrderedDataObjectList(player, orderedDataList) -- Remove if you don't want a OrderedDataStore
		end

		Players.PlayerAdded:Connect(OnPlayerAdded)
		```

	Made by [its_asdf]
]]

-- Sub-Services
local PlayerDataService = require(script.Parent)

-- Module
local SetupHelper = {}

-- Types
export type OrderedDataObjectList = {
	OriginalFolder: Folder, 
	[PlayerDataService.OrderedDataObject]: {
		ValueInstance: IntValue | NumberValue
	}
}

-- PlayerDataService DataStore Constructor
function SetupHelper:GetDataObject(storeName: string, defaultData: TableTemplate): PlayerDataService.DataObject
	return PlayerDataService.GetDataStore(storeName, "DataObject", defaultData)
end

function SetupHelper:GetOrderedDataObjectListFromFolder(folder: Folder): OrderedDataObjectList
	assert(folder and (typeof(folder) == "Instance" and folder:IsA("Folder")), "No folder provided")
	
	local tb = {}
	for _, v in folder:GetDescendants() do
		if v:IsA("IntValue") or v:IsA("NumberValue") then
			local vData = PlayerDataService.GetDataStore(v.Name .. "_Data", "OrderedDataObject")
			tb[vData] = { ValueInstance = v }
			tb["OriginalFolder"] = folder
		end
	end
	return tb
end

function SetupHelper:ConvertFolderToTableTemplate(folder: Folder): TableTemplate
	local data = {}
	for _, descendant in pairs(folder:GetDescendants()) do
		if descendant:IsA("ValueBase") then
			data[descendant.Name] = descendant.Value
		end
	end
	return data
end

-- Picks every OrderedDataObject and calls SetupPlayerForOrderedDataObject with the ValueInstance that is a Int/NumberValue
function SetupHelper:SetupPlayerForOrderedDataObjectList(player: Player, list: OrderedDataObjectList)
	list = table.clone(list)
	list.OriginalFolder = list.OriginalFolder:Clone()
	list.OriginalFolder.Parent = player
	
	for dataObject, info in list do
		if typeof(info) ~= "table" then
			continue 
		end
		
		info.ValueInstance = list.OriginalFolder:FindFirstChild(info.ValueInstance.Name, true)
		
		dataObject:SetupPlayerForOrderedDataObject(player, info.ValueInstance)
	end
end

return SetupHelper
