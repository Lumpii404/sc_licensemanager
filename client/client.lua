ESX = exports["es_extended"]:getSharedObject()

local function getMarkersFromConfig()
    local markers = {}
    for i = 1, #Config.Coords, 3 do
        local marker = vector3(Config.Coords[i], Config.Coords[i + 1], Config.Coords[i + 2])
        table.insert(markers, marker)
    end
    return markers
end

local markers = getMarkersFromConfig()

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, marker in ipairs(markers) do
            local distance = GetDistanceBetweenCoords(playerCoords, marker.x, marker.y, marker.z, true)

            if distance < 5.0 then
                DrawMarker(1, marker.x, marker.y, marker.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.5, 36, 144, 218, 0.8, false, true, 2, nil, nil, false)

                if distance < 1.0 then
                    ESX.ShowHelpNotification(Translation[Config.Locale]['open_menu'])

                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('sc_lc:checkJobAndOpenMenu')
                    end
                end
            end
        end
    end
end)


RegisterNetEvent('sc_lc:open')
AddEventHandler('sc_lc:open', function()
    lib.showContext('license_menu')
end)

function ShowInputNotification(text)
	SetTextComponentFormat('STRING')
	AddTextComponentString(text)
	EndTextCommandDisplayHelp(0, 0, 1, -1)
end

lib.registerContext({
    id = 'license_menu',
    title = Translation[Config.Locale]['menu_title'],
    options = {
      {
        title = Translation[Config.Locale]['menu_check'],
        icon = 'magnifying-glass',
        iconColor = '#6fa8dc',
        onSelect = function()
          TriggerEvent('sc_lc:openDialog')
        end,
      },
      {
        title = Translation[Config.Locale]['menu_add'],
        icon = 'file-circle-plus',
        iconColor = '#93c47d',
        onSelect = function()
            TriggerEvent('sc_lc:openplus')
        end,
      },
      {
        title = Translation[Config.Locale]['menu_remove'],
        icon = 'file-circle-minus',
        iconColor = '#e06666',
        onSelect = function()
            TriggerEvent('sc_lc:openminus')
        end,
      }
    }
  })


--Licensecheck

RegisterNetEvent('sc_lc:openDialog')
AddEventHandler('sc_lc:openDialog', function()
    local input = lib.inputDialog(Translation[Config.Locale]['menu_check'], {
        {type = 'number', label = Translation[Config.Locale]['dia_sub'], description = '', required = true},
    })

    if not input then return end
    TriggerServerEvent('sc_lc:checklicense', input[1])
end)

RegisterNetEvent('sc_lc:showLicenses')
AddEventHandler('sc_lc:showLicenses', function(playerName, licenses)
    local licenseList = ""
    for i, license in ipairs(licenses) do
        if i > 1 then
            licenseList = licenseList .. ", "
        end
        licenseList = licenseList .. "**" .. license .. "**"
    end

    local alert = lib.alertDialog({
        header = Translation[Config.Locale]['alert_header'] .. playerName,
        content = licenseList,
        centered = true,
        cancel = false
    })
end)

RegisterNetEvent('sc_lm:sendTax')
AddEventHandler('sc_lm:sendTax', function(source, type, amount)
  TriggerServerEvent('esx_billing:sendBill', source, 'society_police', type, amount)
end)

--Add License

RegisterNetEvent('sc_lc:openplus')
AddEventHandler('sc_lc:openplus', function()
    local input = lib.inputDialog(Translation[Config.Locale]['dia_add'], {
        {type = 'number', label = Translation[Config.Locale]['dia_sub'], required = true}
    })

    if not input then return end
    TriggerServerEvent('sc_lc:fetchLicenses', input[1])
end)

RegisterNetEvent('sc_lc:askPay')
AddEventHandler('sc_lc:askPay', function(playerID, availableLicenses)
    local options = {}
    for _, license in ipairs(availableLicenses) do
        table.insert(options, {value = license, label = license})
    end

    local input = lib.inputDialog(Translation[Config.Locale]['dia_add'], {
        {type = 'number', label = Translation[Config.Locale]['dia_enter'], required = true},
        {type = 'select', label = Translation[Config.Locale]['dia_license'], options = options, required = true}
    })

    if not input then return end

    local price = tonumber(input[1])
    local selectedLicense = input[2]

    TriggerServerEvent('sc_lc:addlicense', playerID, selectedLicense, price)
end)

--Remove License

RegisterNetEvent('sc_lc:openminus')
AddEventHandler('sc_lc:openminus', function()
    local input = lib.inputDialog(Translation[Config.Locale]['dia_rem'], {
        {type = 'number', label = Translation[Config.Locale]['dia_sub'], required = true}
    })

    if not input then return end
    TriggerServerEvent('sc_lc:fetchLicensesForRemoval', input[1])
end)

RegisterNetEvent('sc_lc:selectLicenseForRemoval')
AddEventHandler('sc_lc:selectLicenseForRemoval', function(playerID, ownedLicenses)
    local options = {}
    for _, license in ipairs(ownedLicenses) do
        table.insert(options, {value = license, label = license})
    end

    local input = lib.inputDialog(Translation[Config.Locale]['dia_rem'], {
        {type = 'select', label = Translation[Config.Locale]['dia_license'], options = options, required = true}
    })

    if not input then return end
    TriggerServerEvent('sc_lc:removelicense', playerID, input[1])
end)