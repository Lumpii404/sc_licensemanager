ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('sc_lc:checkJobAndOpenMenu')
AddEventHandler('sc_lc:checkJobAndOpenMenu', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer and xPlayer.job.name == 'police' and xPlayer.job.grade >= 10 then
        TriggerClientEvent('sc_lc:open', source)
    else
        TriggerClientEvent('esx:showNotification', _source, Translation[Config.Locale]['no_perms'])
    end
end)

ESX.RegisterServerCallback('sc_lc:getPlayerName', function(source, cb, playerID)
    local xPlayer = ESX.GetPlayerFromId(playerID)
    if xPlayer then
        cb(xPlayer.getName())
    else
        cb(nil)
    end
end)

local allLicenses = Config.Types

RegisterServerEvent('sc_lc:checklicense')
AddEventHandler('sc_lc:checklicense', function(playerID)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(playerID)

    if xPlayer then
        local licenses = MySQL.Sync.fetchAll("SELECT * FROM user_licenses WHERE owner = @owner", {
            ['@owner'] = xPlayer.identifier
        })

        local licenseNames = {}
        for _, license in ipairs(licenses) do
            table.insert(licenseNames, license.type)
        end

        local playerName = xPlayer.getName()
        TriggerClientEvent('sc_lc:showLicenses', src, playerName, licenseNames)
    else
        TriggerClientEvent('sc_lc:showLicenses', src, Translation[Config.Locale]['unk'], {Translation[Config.Locale]['no_id']})
    end
end)


RegisterServerEvent('sc_lc:fetchLicenses')
AddEventHandler('sc_lc:fetchLicenses', function(playerID)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(playerID)

    if xPlayer then
        local licenses = MySQL.Sync.fetchAll("SELECT * FROM user_licenses WHERE owner = @owner", {
            ['@owner'] = xPlayer.identifier
        })

        local ownedLicenses = {}
        for _, license in ipairs(licenses) do
            ownedLicenses[license.type] = true
        end

        local availableLicenses = {}
        for _, license in ipairs(allLicenses) do
            if not ownedLicenses[license] then
                table.insert(availableLicenses, license)
            end
        end

        TriggerClientEvent('sc_lc:askPay', src, playerID, availableLicenses)
    else
        TriggerClientEvent('sc_lc:showLicenses', src, {Translation[Config.Locale]['no_id']})
    end
end)

RegisterServerEvent('sc_lc:addlicense')
AddEventHandler('sc_lc:addlicense', function(playerID, licenseType, price)
    TriggerClientEvent('ox_lib:notify', source, {
        title = Translation[Config.Locale]['add_license'],
        description = Translation[Config.Locale]['add_li1'] .. licenseType .. Translation[Config.Locale]['add_li2'],
        type = 'success'
    })
    local xPlayer = ESX.GetPlayerFromId(playerID)

    if xPlayer then
        local playerIdentifier = xPlayer.identifier
        local jobName = xPlayer.job.name

        MySQL.Sync.execute("INSERT INTO user_licenses (type, owner) VALUES (@type, @owner)", {
            ['@type'] = licenseType,
            ['@owner'] = playerIdentifier
        })
        if price == 0 then
            TriggerClientEvent('ox_lib:notify', playerID, {
                id = 'invoice_3',
                title = Translation[Config.Locale]['rev_li'],
                description = Translation[Config.Locale]['rev_li1'] .. licenseType,
                duration = 5000,
                position = 'top-right',
                icon = 'file-circle-plus',
                iconColor = '#12b886'
            })
        end

        if price > 0 then
            exports.pefcl:createInvoice(playerID, {
                to = xPlayer.getName(),
                toIdentifier = playerIdentifier,
                from = jobName,
                fromIdentifier = jobName,
                amount = price,
                message = Translation[Config.Locale]['pur_li'] .. licenseType .. Translation[Config.Locale]['lic'],
                receiverAccountIdentifier = jobName
            })
            TriggerClientEvent('ox_lib:notify', playerID, {
                id = 'invoice_1',
                title = Translation[Config.Locale]['rec_inv'],
                description = Translation[Config.Locale]['pur_1'] .. licenseType .. Translation[Config.Locale]['pur_2'] .. price .. Translation[Config.Locale]['money'],
                duration = 5000,
                position = 'top-right',
                icon = 'receipt',
                iconColor = '#2490DA'
            })
        end
    end
end)

RegisterServerEvent('sc_lc:fetchLicensesForRemoval')
AddEventHandler('sc_lc:fetchLicensesForRemoval', function(playerID)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(playerID)

    if xPlayer then
        local licenses = MySQL.Sync.fetchAll("SELECT * FROM user_licenses WHERE owner = @owner", {
            ['@owner'] = xPlayer.identifier
        })

        local ownedLicenses = {}
        for _, license in ipairs(licenses) do
            table.insert(ownedLicenses, license.type)
        end

        TriggerClientEvent('sc_lc:selectLicenseForRemoval', src, playerID, ownedLicenses)
    else
        TriggerClientEvent('sc_lc:showLicenses', src, {Translation[Config.Locale]['no_id']})
    end
end)

RegisterServerEvent('sc_lc:removelicense')
AddEventHandler('sc_lc:removelicense', function(playerID, license)
    TriggerClientEvent('ox_lib:notify', source, {
        title = Translation[Config.Locale]['rem_li'],
        description = Translation[Config.Locale]['rem_li1'] .. license .. Translation[Config.Locale]['rem_li2'],
        type = 'success'
    })
    local xPlayer = ESX.GetPlayerFromId(playerID)

    if xPlayer then
        MySQL.Sync.execute("DELETE FROM user_licenses WHERE type = @type AND owner = @owner", {
            ['@type'] = license,
            ['@owner'] = xPlayer.identifier
        })
    end
    TriggerClientEvent('ox_lib:notify', playerID, {
        id = 'invoice_2',
        title = Translation[Config.Locale]['rem_li'],
        description = Translation[Config.Locale]['rem_li3'] .. license .. Translation[Config.Locale]['rem_li4'],
        duration = 5000,
        position = 'top-right',
        icon = 'file-circle-minus',
        iconColor = '#e06666'
    })
end)
