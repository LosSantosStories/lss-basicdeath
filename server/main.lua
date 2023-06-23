RegisterNetEvent('lss-basicdeath:server:SetDeathStatus', function (isDead)
	local xPlayer = ESX.GetPlayerFromId(source)

	if type(isDead) == 'boolean' then
		MySQL.update('UPDATE users SET is_dead = ? WHERE identifier = ?', { isDead, xPlayer.identifier })
	end

end)

RegisterNetEvent('lss-basicdeath:server:ClearInventory',function ()
	exports.ox_inventory:ClearInventory(source, Config.WhitelistedItems)
end)

lib.callback.register('lss-basicdeath:callback:GetDeathStatus', function(callback)
    return MySQL.scalar.await('SELECT is_dead FROM users WHERE identifier = ?', { ESX.GetPlayerFromId(source)?.identifier or '' })
end)

lib.addCommand('revive', {
    help = locale('admin_revive'),
	restricted = "group.admin",
	params = {
        { name = 'id', help = locale('revive_id'), optional = true },
    }
}, function(source, args)
	if not args.id then
		TriggerClientEvent('lss-basicdeath:client:RevivePlayer', source, 'admin')
	else	
		if args.id ~= 'all' and type(tonumber(args.id)) == 'number' then
			local xPlayer = ESX.GetPlayerFromId(args.id)
			local IsDead = Player(args.id).state.isDead
			if not xPlayer or not IsDead then
				TriggerClientEvent('ox_lib:notify', source, { description = not xPlayer and locale('user_not_found' ,args.id) or not IsDead and locale('not_dead', args.id), type = 'error' })
				return
			end
			TriggerClientEvent('ox_lib:notify', xPlayer.source, { description = locale('got_revived'), type = 'inform' })
			TriggerClientEvent('lss-basicdeath:client:RevivePlayer', xPlayer.source, 'admin')
		elseif args.id == 'all' then
			local Alert = lib.callback.await('lss-basicdeath:callback:GetDialog', source)
			if Alert == 'confirm' then
				local Players = GetPlayers()
				for k,v in pairs(Players) do
					local IsDead = Player(v).state.isDead
					if IsDead then
						local xPlayer = ESX.GetPlayerFromId(v)
						TriggerClientEvent('ox_lib:notify', xPlayer.source, { description = locale('got_revived'), type = 'inform' })
						TriggerClientEvent('lss-basicdeath:client:RevivePlayer', xPlayer.source, 'admin')
					end
				end
			end
		else
			TriggerClientEvent('ox_lib:notify', source, { description = locale('went_wrong'), type = 'error' })
		end
	end
end)

lib.addCommand('kill', {
    help = locale('admin_kill'),
	restricted = "group.admin",
	params = {
        { name = 'id', help = locale('kill_id'), optional = true },
    }
}, function(source, args)
	if not args.id then
		TriggerClientEvent('lss-basicdeath:client:SetPlayerDead', source)
	else	
		if type(tonumber(args.id)) == 'number' then
			local xPlayer = ESX.GetPlayerFromId(args.id)
			local IsDead = Player(args.id).state.isDead
			if not xPlayer or IsDead then
				TriggerClientEvent('ox_lib:notify', source, { description = not xPlayer and locale('user_not_found' ,args.id) or not IsDead and locale('already_dead', args.id), type = 'error' })
				return
			end
			TriggerClientEvent('ox_lib:notify', xPlayer.source, { description = locale('got_killed'), type = 'inform' })
			TriggerClientEvent('lss-basicdeath:client:SetPlayerDead', xPlayer.source)
		else
			TriggerClientEvent('ox_lib:notify', source, { description = locale('went_wrong'), type = 'error' })
		end	
	end
end)
