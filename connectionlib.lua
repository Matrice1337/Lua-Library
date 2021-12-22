if getgenv().conlib then
	return getgenv().conlib
end

getgenv().conlib = {}

getgenv().raw = loadstring(game:HttpGet("https://pastebin.com/raw/aVDqbsU2"))() -- raw library

local InstSignals = {}
local SignalInsts = {}

getgenv().conlib.getconnections = function(Signal)
    assert(typeof(Signal) == "RBXScriptSignal", string.format("Invalid argument #1 (RBXScriptSignal expected, got %s)", typeof(Signal)))
    local Signals = InstSignals[SignalInsts[Signal]]
    return Signals and Signals.Connections or {}
end

getgenv().conlib.connectionadded = function(Signal, Function)
    assert(typeof(Signal) == "RBXScriptSignal", string.format("Invalid argument #1 (RBXScriptSignal expected, got %s)", typeof(Signal)))
    assert(type(Function) == "function", string.format("Invalid argument #2 (function expected, got %s)", typeof(Function)))

    local Signals = InstSignals[SignalInsts[Signal]]
    local Connection = newcclosure(Function)

    Signals.CAdded[#Signals.CAdded+1] = Connection

    local Con = {}
    function Con:Disconnect()
        for i,v in pairs(Signals.CAdded) do
            if v == Connection then
                table.remove(Signals.CAdded, i)
            end
        end
    end

    return Con
end

getgenv().conlib.connectionremoved = function(Signal, Function)
    assert(typeof(Signal) == "RBXScriptSignal", string.format("Invalid argument #1 (RBXScriptSignal expected, got %s)", typeof(Signal)))
    assert(type(Function) == "function", string.format("Invalid argument #2 (function expected, got %s)", typeof(Function)))

    local Signals = InstSignals[SignalInsts[Signal]]
    local Connection = newcclosure(Function)

    Signals.CRemoved[#Signals.CRemoved+1] = Connection

    local Con = {}
    function Con:Disconnect()
        for i,v in pairs(Signals.CAdded) do
            if v == Connection then
                table.remove(Signals.CAdded, i)
            end
        end
    end

    return Con
end

getgenv().conlib.getcallingsignal = function(Signal)
    return InstSignals[SignalInsts[Signal]]
end

getgenv().conlib.getsignals = function(Instance)
    return InstSignals[Instance] and InstSignals[Instance].CTypes
end

do
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local Args = {...}
        local Self = Args[1]
        if Self ~= nil and typeof(Self) == "Instance" then
            local success, output = pcall(function()
                return Self[getnamecallmethod()]
            end)

            if success and type(output) == "function" then
                local Result = {OldNamecall(...)}
                for _,Signal in pairs(Result) do
                    if typeof(Signal) == "RBXScriptSignal" then
                        if not InstSignals[Self] then
                            InstSignals[Self] = {Connections = {}, Functions = {}, CAdded = {}, CRemoved = {}, CTypes = {}}
                        end
                        if not table.find(InstSignals[Self].CTypes, Signal) then
                            InstSignals[Self].CTypes[#InstSignals[Self].CTypes+1] = Signal
                        end
                        SignalInsts[Signal] = Self
                    end
                end
                return unpack(Result)
            end
        end
        return OldNamecall(...)
    end))
end

do
	local OldIndex
    OldIndex = hookmetamethod(game, "__index", newcclosure(function(...)
		local Args = {...}
		local Self = Args[1]
		if Self ~= nil then
			local Result = {OldIndex(...)}
			for _,Signal in pairs(Result) do
				if typeof(Signal) == "RBXScriptSignal" then
					if not InstSignals[Self] then
						InstSignals[Self] = {Connections = {}, Functions = {}, CAdded = {}, CRemoved = {}, CTypes = {}}
					end
                    if not table.find(InstSignals[Self].CTypes, Signal) then
                        InstSignals[Self].CTypes[#InstSignals[Self].CTypes+1] = Signal
                    end
					SignalInsts[Signal] = Self
				end
			end
			return unpack(Result)
		end
        return OldIndex(...)
    end))
end

local Connections = {}

do
	local OldIndex
	OldIndex = hookmetamethod(raw.get(game, "Changed"), "__index", newcclosure(function(...)
		local Args = {...}
		if Args[2] == "Connect" then
			local Connector = OldIndex(...)

			local OldConnector
			OldConnector = hookfunction(Connector, newcclosure(function(Signal, Function)
				local Connection = OldConnector(Signal, Function)
				local Signals = InstSignals[SignalInsts[Signal]]
                if Signals ~= nil then
                    Connections[Connection] = Signal
                    local ConTbl = {Enabled = true, Connection = Connection, Function = newcclosure(Function), Script = getfenv(Function).script}
                    function ConTbl:Enable()
                        if self.Enabled ~= true then
							if self.Enabled == nil then
								Signals.Connections[#Signals.Connections+1] = ConTbl
							end

                            Connections[Connection] = nil
                            Connection = raw.signal(Signal, "Connect")(Signal, ConTbl.Function)
                            Connections[Connection] = Signal
                            ConTbl.Connection = Connection

                            ConTbl.Enabled = true
                        end
                    end
                    function ConTbl:Disable()
                        if ConTbl.Enabled == true then
                            raw.connect(Connection, "Disconnect")(Connection)
							ConTbl.Enabled = false
                        end
                    end
                    Signals.Connections[#Signals.Connections+1] = ConTbl
					task.spawn(newcclosure(function()
						for _,Con in pairs(Signals.CAdded) do
							Con(ConTbl)
						end	
					end))
                end

				return Connection
			end))

			return Connector
		end
		return OldIndex(...)
	end))
end

do
	local OldIndex
	OldIndex = hookmetamethod(raw.signal(raw.get(game, "Changed"), "Connect")(raw.get(game, "Changed"), function()end), "__index", newcclosure(function(...)
		local Args = {...}
		if Args[2] == "Disconnect" then
			local Signals = InstSignals[SignalInsts[Connections[Args[1]]]]

            if Signals ~= nil then
                for i,v in pairs(Signals.Connections) do
                    if v.Connection == Args[1] then
						v.Enabled = nil
                        table.remove(Signals.Connections, i)
						task.spawn(newcclosure(function()
							for _,Con in pairs(Signals.CRemoved) do
								Con(v)
							end
						end))
					end
                end
                Connections[Args[1]] = nil
            end
		end
		return OldIndex(...)
	end))
end

return getgenv().conlib