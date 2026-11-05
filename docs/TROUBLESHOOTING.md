# Troubleshooting & FAQ

### 1. Devices not showing up in Multi Control or Nearby Devices
- **Verify Network**: Ensure your PC and Galaxy device are connected to the same Wi-Fi network (5 GHz recommended) and signed into the same Samsung account.
- **Check Location Permissions**: Ensure Windows Location Services is on in Windows Settings > Privacy & security > Location. Run `Check-Status.bat` to verify.
- **Firewall Check**: Confirm that inbound UDP discovery ports (`1900, 3702, 5353, 5355`) and TCP ports (`49200-49202`) are allowed. Running `Enable-GalaxyConnect.bat` configures these automatically.
- **Run Diagnostic**: Run `Check-Status.bat` to see a full status report of all services, registry keys, and test flags.

### 2. Multi Control connects and then immediately disconnects
- This occurs when `FamilyMDE\Settings` is missing or when `EnclosureType` is set to `10` (Laptop). Run `Enable-GalaxyConnect.bat` to apply `EnclosureType = 3` and `FamilyMDE\Settings = 1`.

### 3. "Turn on Location in Windows Settings" banner in Samsung Apps
- Windows 11 restricts UWP background proximity scans if app consent is `Prompt`. `Enable-GalaxyConnect.bat` grants `Allow` across all Samsung packages in `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location`.

### 4. How to uninstall or restore genuine OEM BIOS values
- Run `Disable-GalaxyConnect.bat` as Administrator. It restores your original BIOS settings from the automatic backup file (`%LOCALAPPDATA%\GalaxyConnectEnabler\original-bios.json`) and removes all persistence tasks.
