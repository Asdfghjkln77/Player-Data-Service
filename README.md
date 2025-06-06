# 🔧 Roblox PlayerDataService Module

A modular data storage system for Roblox, easy to integrate and highly extensible. Ideal for developers who want to create persistent profiles for players, with support for ordered objects, integration with value folders and much more.

---
## 📦 Modules

### 📁 `PlayerDataService`

Main module that deals with DataStores and offers support for two types:

- `DataObject`: Data table saved by player, that use the ProfileStore (new ProfileService) to handle all requirements.
- `OrderedDataObject`: Object with support for ordering by values ​​(e.g. for ranking systems).

### 🧰 `SetupHelper`

Auxiliary module that makes it easier to use `PlayerDataService`, ideal for beginners or for projects that only need to connect existing values ​​in folders and get it working.

---

## 🚀 How to Use

### 1. Basic Configuration

```lua
-- Services
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Module References
local dataModule = ServerStorage.Modules.PlayerPlayerDataService

-- Sub-Services
local PlayerPlayerDataService = require(dataModule)
local PlayerPlayerDataService_SetupHelper = require(dataModule.SetupHelper)

-- DataStore References
local dataFolder = ServerStorage.DataFolders.PlayerAttributes -- Remove if you don't want a DataStore
local tableTemplate = PlayerPlayerDataService_SetupHelper:ConvertFolderToTableTemplate(dataFolder) -- Remove if you don't want a DataStore
local data = PlayerPlayerDataService_SetupHelper:GetDataObject(dataFolder.Name, tableTemplate) -- Remove if you don't want a DataStore

-- OrderedDataStore References
local leaderstats = ServerStorage.DataFolders.leaderstats -- Remove if you don't want a OrderedDataStore
local orderedDataList = PlayerPlayerDataService_SetupHelper:GetOrderedDataObjectListFromFolder(leaderstats) -- Remove if you don't want a OrderedDataStore

-- Leaderboard References
local KillsData = PlayerPlayerDataService.GetDataStore("Kills_Data", "OrderedDataObject") -- Remove if you don't want a Leaderboard
local leaderPart = workspace.LeaderPart -- Remove if you don't want a Leaderboard
local surfacegui = leaderPart.SurfaceGui -- Remove if you don't want a Leaderboard
local container = surfacegui.Container -- Remove if you don't want a Leaderboard-
local template: TextLabel = container.Template -- Remove if you don't want a Leaderboard

-- Control
local autoSaveTime = 250
local leaderboardAutoUpdateTime = 300 -- Remove if you don't want a Leaderboard

-- Remove if you don't want a OrderedDataStore
task.spawn(function()
	while true do
		local pages = KillsData:GetSortedAsync(false, 10, 1)
		local firstPage = pages:GetCurrentPage()
		
		for rank, dict in ipairs(firstPage) do
			local userId = string.sub(dict.key, 8)
			local kills = dict.value
			local username = Players:GetNameFromUserIdAsync(userId)
			local clone = template:Clone()
			
			local oldTextLabel = container:FindFirstChild(rank)
			if oldTextLabel then
				oldTextLabel:Destroy()
			end
			
			clone.Text = string.format("%d° | %s | Kills: %d", rank, username, kills)
			clone.Name = rank
			clone.LayoutOrder = rank
			clone.Visible = true
			clone.Parent = container
		end
		
		task.wait(leaderboardAutoUpdateTime)
	end
end)

-- Function that handles when a player is added
local function OnPlayerAdded(player: Player)
	data:SetupPlayerForDataObject(player, dataFolder, autoSaveTime) -- Remove if you don't want a DataStore
	PlayerPlayerDataService_SetupHelper:SetupPlayerForOrderedDataObjectList(player, orderedDataList, autoSaveTime) -- Remove if you don't want a OrderedDataStore
end

Players.PlayerAdded:Connect(OnPlayerAdded)
```
