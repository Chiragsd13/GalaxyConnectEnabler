# Galaxy Connect Enabler 🌌

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6.svg)](https://microsoft.com)
[![Architecture](https://img.shields.io/badge/Architecture-AMD%20Ryzen%20%7C%20Intel-ED8B00.svg)](docs/COMPATIBILITY.md)
[![Wi-Fi](https://img.shields.io/badge/Wi--Fi-MediaTek%20%7C%20Realtek%20%7C%20Qualcomm-green.svg)](docs/COMPATIBILITY.md)

**Galaxy Connect Enabler** is an open-source utility that unlocks Samsung's full cross-device ecosystem (**Multi Control**, **Nearby Devices / Galaxy Connect**, **Storage Share**, **Second Screen**, and **Samsung Continuity**) on any Windows 11 PC — with native support for **AMD Ryzen** processors and **MediaTek, Realtek, and Qualcomm** Wi-Fi/Bluetooth hardware.

---

## ⚡ The Problem & The Discovery

Historically, Samsung cross-device features failed on non-Samsung and AMD/MediaTek systems:
- If spoofed as a Samsung laptop, Samsung Continuity (`WindowsMCFCore.exe`) crashed or rejected the network card with `"Non Supporting Wi-Fi vendor"`.
- If unspoofed or spoofed as Lenovo/ASUS/Dell, Multi Control and Nearby Devices failed device discovery or dropped P2P pairing.

### The Breakthrough
Reverse-engineering `Commons.dll` (`MCFCommons.Helpers.DriverHelper.DeviceSupportHelper.HasSupportedWiFi`) revealed Samsung's internal check:
```csharp
MachineType currentMachineType = MachineDetailsHelper.GetCurrentMachineType();
if (!isSamsung || currentMachineType == MachineType.Desktop)
{
    // "All WiFi Drivers are supported for Non-Samsung PC || Desktop PC"
    return true;
}
```
Samsung **only** enforces an Intel/Qualcomm-only whitelist on **laptops** (`EnclosureType = 10 / 31`). On **Desktop PCs (`EnclosureType = 3`)**, Samsung Continuity **explicitly allows ALL Wi-Fi and Bluetooth chipsets**!

By spoofing `SystemManufacturer = SAMSUNG ELECTRONICS CO., LTD.` with `EnclosureType = 3` and enabling `FamilyMDE`:
1. **Samsung Continuity** whitelists MediaTek and Realtek Wi-Fi.
2. **Multi Control** detects a genuine Samsung PC and maintains active P2P connections.
3. **Nearby Devices (Galaxy Connect)** discovers Galaxy phones, tablets, and buds.
4. **Location Permissions** are automatically granted to eliminate background discovery pop-ups.

---

## 🚀 Quick Start (1-Click Run)

### Method 1: Clone & Run
```powershell
git clone https://github.com/Chiragsd13/GalaxyConnectEnabler.git
cd GalaxyConnectEnabler
.\Enable-GalaxyConnect.bat
```
*(Right-click and select **Run as administrator** if prompted).*

### Method 2: One-Liner (PowerShell 7 / Admin)
```powershell
irm https://raw.githubusercontent.com/Chiragsd13/GalaxyConnectEnabler/main/scripts/Enable-GalaxyConnect.ps1 | iex
```

---

## 📱 Features Enabled

- **Samsung Multi Control**: Control your Galaxy phone or tablet seamlessly with your PC keyboard and mouse, with unified clipboard copy/paste.
- **Galaxy Connect (Nearby Devices)**: Proximity device status, battery levels, and instant pairing bubble.
- **Storage Share**: Direct File Explorer access to files on your Galaxy phone or tablet.
- **Second Screen**: High-speed wireless display expansion to Galaxy Tab.
- **Quick Share**: Fast peer-to-peer file transfer.
- **Samsung Notes**: Direct cloud sync with Samsung Cloud.
- **Location Fix**: Automatically resolves the Windows 11 "Location permission is required" prompt in Samsung apps.

---

## 🛠️ Included Tools

| File | Purpose |
|---|---|
| `Enable-GalaxyConnect.bat` | One-click setup: applies BIOS spoof, firewall rules, location permissions, and boot persistence. |
| `Check-Status.bat` | Real-time diagnostic tool: audits BIOS status, services, test flags, and connected devices. |
| `Disable-GalaxyConnect.bat` | Clean uninstaller: restores original BIOS values from backup and removes all persistence tasks. |

---

## 📖 Documentation

- [Architecture & Reverse-Engineering Deep Dive](docs/ARCHITECTURE.md)
- [Hardware Compatibility Matrix](docs/COMPATIBILITY.md)
- [Troubleshooting & FAQ](docs/TROUBLESHOOTING.md)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
Author: **Chirag** ([@Chiragsd13](https://github.com/Chiragsd13))
Contributed in connection with [Bananz0/GalaxyBookEnabler Issue #100](https://github.com/Bananz0/GalaxyBookEnabler/issues/100).
