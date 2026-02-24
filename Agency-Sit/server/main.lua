-- Agency-Sit - Server Side
-- Discord Support: https://discord.gg/zbG53tTUXR
-- Shop: https://agency-script.tebex.io

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^3========================================^0')
    print('^2Agency-Sit^0 ^7v1.0.0 - Successfully Started^0')
    print('^7Discord Support:^0 ^5https://discord.gg/zbG53tTUXR^0')
    print('^7Get More Scripts:^0 ^5https://agency-script.tebex.io^0')
    print('^7Agency-Notify:^0 ^5https://agency-script.tebex.io/package/6937769^0')
    print('^3========================================^0')
end)
