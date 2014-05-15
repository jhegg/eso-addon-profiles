eso-addon-profiles
==================

An Elder Scrolls Online addon that allows you to use profiles to change which addons should currently be enabled.

It provides a settings menu section with a slider bar that represents 5 possible profiles. Each profile displays the list of installed addons with an on/off button, allowing you to specify whether the addon should be enabled or disabled. You can then use the slash command '/addonprofiles #' (where # is the profile number 1 through 5), and the specified addons will be disabled/enabled and your UI will be reloaded, causing the changes to take effect.

By using account-wide SavedVariables, your addon profiles will be the same across all characters. So, you might setup one profile for your main that enables combat and questing and exploration mods, and a different profile for your alts that enables crafting mods.

Todo:
- [x] Get basic functionality working
- [x] Get SavedVariables hooked up
- [ ] Scalability test with 50 addons
- [ ] Scalability test with 100 addons
- [ ] Release 1.0
- [ ] Publish to esoui and curse
