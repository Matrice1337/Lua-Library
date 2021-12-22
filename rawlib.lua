if getgenv().raw then
    return getgenv().raw
end

getgenv().raw = {}

do
	local rawgett;rawgett = hookmetamethod(game,"__index",newcclosure(function(...)return rawgett(...)end))
	getgenv().raw.get = rawgett
end
do
	local rawsett;rawsett = hookmetamethod(game,"__newindex",newcclosure(function(...)return rawsett(...)end))
	getgenv().raw.set = rawsett
end
do
	local rawcall;rawcall = hookmetamethod(game,"__namecall",newcclosure(function(...)return rawcall(...)end))
	getgenv().raw.call = rawcall
end
do
	local rawsignal;rawsignal = hookmetamethod(raw.get(game, "Changed"), "__index", newcclosure(function(...)return rawsignal(...)end))
	getgenv().raw.signal = rawsignal
end
do
	local rawconnect;rawconnect = hookmetamethod(raw.signal(raw.get(game, "Changed"), "Connect")(raw.get(game, "Changed"), function()end), "__index", newcclosure(function(...)return rawconnect(...)end))
	getgenv().raw.connect = rawconnect
end

return getgenv().raw