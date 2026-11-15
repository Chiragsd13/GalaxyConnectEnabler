# Troubleshooting & FAQ 🛠️

Comprehensive troubleshooting guide for Samsung Multi Control, Nearby Devices (Galaxy Connect), Storage Share, and Continuity on Windows 11.

---

## 1. Devices not showing up in Multi Control or Nearby Devices

### Cause A: Device is asleep or screen is locked
Samsung Galaxy devices throttle or pause Bluetooth Low Energy (BLE) proximity advertising beacons when locked in deep sleep.
- **Fix**: Unlock your Galaxy phone or tablet and keep the screen turned on. Open **Settings > Connected devices > Multi control** once to trigger an immediate beacon broadcast.

### Cause B: Bluetooth or Wi-Fi is turned off
Multi Control requires both Bluetooth (for device discovery and handoff negotiation) and Wi-Fi (for data and input streaming) to be active on all devices.
- **Fix**: Ensure Bluetooth and Wi-Fi are turned ON on your PC, tablet, and phone.

### Cause C: Samsung Account mismatch
All devices must be logged into the **same Samsung Account**.
- **Fix**: Check your account in the Samsung Account app on Windows and **Settings > Samsung Account** on your Galaxy mobile devices.

### Cause D: Multi Control toggled off on the mobile device
- **Fix**: On your Galaxy phone/tablet:
  1. Open **Settings**.
  2. Tap **Connected devices**.
  3. Ensure **Multi control** is turned **ON**.
  4. Tap **Multi control** and set *Connect phone/tablet* to automatically or manually as desired.
  5. Ensure **Continue apps on other devices** is also turned **ON**.

---

## 2. University, Campus, Hotel, or Public Wi-Fi (AP Isolation / Client Isolation)

### The Problem
If you are connected to a campus network (e.g. `uvic.ca`, `eduroam`), hotel, or public Wi-Fi, your laptop network profile defaults to **`Public`**. Furthermore, enterprise campus routers enforce **Access Point (AP) Isolation / Client Isolation**, which intentionally blocks devices from talking directly to each other over the local subnet.

### Symptoms
- Multi Control discovers your device for a split second, then immediately drops to `DISCONNECTED`.
- Logs show `Remove Device. Connection state DISCONNECTED`.

### The Solution
1. **Option A (Recommended on Campus): Mobile Hotspot**
   - Turn on **Mobile Hotspot** on your Galaxy phone or tablet.
   - Connect your laptop to your mobile hotspot (or vice versa).
   - Because you are on a private direct network with no AP isolation, Multi Control and Nearby Devices connect instantly with ultra-low latency.
2. **Option B: Windows Firewall Any-Profile Exemption**
   - Run `Enable-GalaxyConnect.bat`. It automatically configures Windows Firewall rules to allow inbound UDP discovery (`1900, 3702, 5353, 5355`) and TCP streaming (`49200-49202, 8080, 8443`) on **ALL network profiles** (`Domain`, `Private`, and `Public`).

---

## 3. Multi Control connects and then immediately disconnects

### Cause: Missing `FamilyMDE` setting or wrong `EnclosureType`
- When `EnclosureType` is set to `10` (Laptop), Samsung Continuity enforces an Intel/Qualcomm whitelist and terminates connections on MediaTek, Realtek, or AMD systems.
- When `FamilyMDE\Settings` is missing from the user hive (`HKCU`), the UWP client drops P2P sessions.
- **Fix**: Run `Enable-GalaxyConnect.bat` as Administrator. It enforces:
  - `EnclosureType = 3` (Desktop bypass mode)
  - `HKLM\...\FamilyMDE\Settings = 1`
  - `HKCU\...\FamilyMDE\Settings = 1`

---

## 4. "Location permission is required" prompt in Samsung Apps

### Why it happens
Windows 11 treats Bluetooth Low Energy beacon scanning as a location-sensitive capability. If Samsung apps do not have explicit capability consent, Windows blocks proximity discovery.

### How it is resolved
`Enable-GalaxyConnect.bat` automatically configures Windows CapabilityAccessManager:
```powershell
HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location -> Value: "Allow"
HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location -> Value: "Allow"
```
It grants permission to all Samsung packaged UWP apps and NonPackaged desktop processes so this banner never appears again.

---

## 5. Boot Persistence & Verification

### How to verify after a Windows reboot:
Run `Check-Status.bat`. Everything should show **[OK]**:
- `System Manufacturer : SAMSUNG ELECTRONICS CO., LTD. [OK]`
- `Enclosure Type      : 3 (Desktop Mode) [OK]`
- `HKLM FamilyMDE      : 1 [OK]`
- `HKCU FamilyMDE      : 1 [OK]`
- `Engineering Flags   : Active in MultiControl & NearbyDevices [OK]`
- `Background Services : RUNNING [OK]`

### How persistence works:
- **At Boot**: The scheduled task `GalaxyConnectEnabler-Boot` runs at system startup as `NT AUTHORITY\SYSTEM` with a 5-second delay, ensuring the BIOS keys are spoofed before Samsung services load.
- **At Logon**: The `SamsungEcosystemSync` entry in `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` ensures user-level `FamilyMDE` and location permissions are active in your user session.

---

## 6. How to cleanly uninstall and restore genuine OEM BIOS values

If you ever wish to revert all changes back to your original factory BIOS values:
1. Run `Disable-GalaxyConnect.bat` as Administrator.
2. The script reads `%LOCALAPPDATA%\GalaxyConnectEnabler\original-bios.json` (created during initial setup) and restores your original manufacturer, model, and enclosure type.
3. It cleans up scheduled tasks, HKCU Run keys, and engineering test flags.
