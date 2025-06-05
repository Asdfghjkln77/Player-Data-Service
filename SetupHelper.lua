--[[
	SetupHelper - Mini API
	-------------------------
	🔧 Purpose:
		Helper module to quickly initialize profiles using PlayerDataService.
		It was made to facilitate the configuration of DataObjects and OrderedDataObjects with minimum complexity.
		Ideal for those who want to plug and play with folders/values ​​already ready in the game.

	📦 Functions:

		🔹 SetupHelper:GetDataObject(storeName: string, defaultData: table) -> DataObject
			→ Creates and returns a DataObject using the PlayerDataService.

		🔹 SetupHelper:GetOrderedDataObjectListFromFolder(folder: Folder) -> OrderedDataObjectList
			→ Analyzes the provided folder and returns a list of OrderedDataObjects based on their NumberValues/IntValues.
			
		🔹 SetupHelper:ConvertFolderToTableTemplate(folder: Folder) -> table
			-> converts a folder to a table in order of PlayerDataService use
		
		🔹 SetupHelper:SetupPlayerForOrderedDataObjectList(player: Player, list: OrderedDataObjectList)
			→ Clones the original folder, places it in the player and connects all OrderedDataObjects correctly.

	🧠 Types:

		type OrderedDataObjectList = {
			OriginalFolder: Folder,
			[PlayerDataService.OrderedDataObject]: {
				ValueInstance: NumberValue | IntValue
			}
		}

	📁 Requirements:
		script.Parent must be the `PlayerDataService` module, already functional.

	✅ Example of use: 
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
