-- Module
local ErrorService = {}

-- Try to execute a function with the passed arguments and retry if it fails
function ErrorService.TryToExecute(maxTries: number?, delayTime: number?, func: (...any) -> ...any, ...: any)
	-- Setup
	assert(func and typeof(func) == "function", "No function provided")
	maxTries = maxTries or 2
	delayTime = delayTime or 1
	
	-- It trys to execute here
	local tries = 0
	local success, result
	repeat -- loop
		tries += 1
		success, result = pcall(func, ...)
		if not success then
			task.wait(delayTime)
			warn(`{tries}° try of {maxTries}°. Error: {result}; Traceback:\n {debug.traceback()}`)
		end
	until success or tries == maxTries -- condition to stop
	
	-- Return the values
	return success, result
end

return ErrorService
