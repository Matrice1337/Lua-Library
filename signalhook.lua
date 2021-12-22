if getgenv().hooksignal then
	return getgenv().hooksignal
end

getgenv().conlib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Matrice1337/Lua-Library/main/connectionlib.lua"))() -- my awesome connection library
getgenv().raw = loadstring(game:HttpGet("https://raw.githubusercontent.com/Matrice1337/Lua-Library/main/rawlib.lua"))() -- my awesome raw library

local signalinfo
getgenv().getsignalinfo = function()
	return signalinfo
end

local HookedSignals = {}

getgenv().hooksignal = function(Signal, Function)
	assert(typeof(Signal) == "RBXScriptSignal", string.format("Invalid argument #1 (RBXScriptSignal expected, got %s)", typeof(Signal)))
	assert(type(Function) == "function", string.format("Invalid argument #2 (function expected, got %s)", typeof(Function)))

	local Signals = conlib.getcallingsignal(Signal)
	Signals.Functions[#Signals.Functions+1] = Function

	if not HookedSignals[Signal] then
		HookedSignals[Signal] = true

		conlib.connectionadded(Signal, function(ConTbl)
			raw.connect(ConTbl.Connection, "Disconnect")(ConTbl.Connection)
		end)
		for _,v in pairs(conlib.getconnections(Signal)) do
			raw.connect(v.Connection, "Disconnect")(v.Connection)
		end

		raw.signal(Signal, "Connect")(Signal, newcclosure(function(...)
			for Index,Connection in pairs(conlib.getconnections(Signal)) do
				signalinfo = {Connection = Connection.Connection, Function = Connection.Function, Script = Connection.Script, Index = Index}
				local Args = {...}
				task.spawn(newcclosure(function()
					for i = #Signals.Functions, 1, -1 do
						local success,_ = pcall(function()
							Args = {Signals.Functions[i](unpack(Args))}
						end)
						if not success then
							return
						end
					end

					Connection.Function(unpack(Args))
				end))
			end
		end))
	end
end

return getgenv().hooksignal
