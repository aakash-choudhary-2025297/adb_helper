# ADB Helper — Product Requirements & Functionality Spec

**Version:** 1.0  
**Target:** Desktop only — **macOS** and **Windows**  
**Scope:** MVP — Devices, Shell, Apps, Misc (clear cache / clear data)

---

## 1. Overview

A Flutter desktop application that exposes Android Debug Bridge (ADB) through a UI. The app runs on the host machine, invokes the system `adb` binary, and displays results in the interface. One device is active at a time.

---

## 2. Platform & Technical

| Item | Decision |
|------|----------|
| **Platforms** | macOS, Windows only |
| **ADB** | Assume `adb` is on PATH; **Settings** must allow user to set custom path to `adb` |
| **Permissions** | No admin/root required for normal ADB usage |
| **Concurrency** | **One device at a time** — user selects active device from list |
| **ADB not installed** | Handle gracefully: in-app instructions and/or download link (e.g. Android SDK / platform-tools) |
| **Min OS versions** | Define and document (e.g. Windows 10+, macOS 10.14+); document in app/settings or help |

---

## 3. MVP Features

### 3.1 Devices

- **List** connected devices (USB and wireless).
- **Show:** device ID, model (if available), state (e.g. device/offline).
- **Select** one device as the active target for all other features.
- **Refresh** list on demand (and optionally auto-refresh when list is focused).
- **In-app help:** Short explanation of what “devices” means and how to connect (USB debugging, wireless).

### 3.2 Shell

- **Input:** Text field (or small terminal-like area) to type shell commands.
- **Execute:** Button to run the command against the active device.
- **Output:** Scrollable area showing stdout/stderr (and exit code if useful).
- **In-app help:** What ADB shell is, examples (e.g. `ls`, `pm list packages`), and that commands run on the device.

### 3.3 Apps

- **List** installed packages on the active device (with optional search/filter by name).
- **Actions per app (or selection):**
  - **Uninstall** (with confirmation).
  - **Clear app cache** (with confirmation).
  - **Clear app data** (with confirmation).
- **In-app help:** What packages are, difference between clear cache vs clear data, and that uninstall is irreversible.

### 3.4 Misc (Clear cache / Clear data)

- Treated as part of **Apps**: clear app cache and clear app data are app-level actions (see 3.3).
- If you add a separate “Misc” section later, it can group: reboot, device info, etc., each with short help.

---

## 4. Safety & Confirmations

- **Uninstall:** Always show confirmation (e.g. “Uninstall &lt;package&gt;? This cannot be undone.”).
- **Clear app data:** Confirm (e.g. “Clear all data for &lt;app&gt;? Logins and local data will be removed.”).
- **Clear app cache:** Confirm (e.g. “Clear cache for &lt;app&gt;?”).
- Optional: Settings toggle for “Skip confirmations for clear cache only” if you want to allow power users to skip that one.

---

## 5. In-App Help & Docs

- **Per feature:** Short “What this does” and basic usage (e.g. tooltip, info icon, or collapsible panel).
- **ADB not found:** Clear message + link/instructions to install Android SDK platform-tools (and optionally set PATH or app’s ADB path in Settings).
- **Min OS versions:** Document in Help/About or Settings (e.g. “Requires Windows 10+ / macOS 10.14+”).

---

## 6. Settings

- **ADB path:** Optional custom path to `adb` executable (default: use `adb` from PATH).
- **Persist** the path (e.g. local storage / preferences) and validate on save (e.g. run `adb version`).

---

## 7. Out of Scope for MVP

- Multiple devices in tabs or split view.
- File push/pull.
- Logcat viewer.
- Screenshot / screen recording.
- Backup/restore, port forwarding, or other advanced ADB features.

---

## 8. Future scope (not now)

- **System tray / menu bar:** Add the app to the **macOS menu bar** and **Windows system tray** so it’s quick to open from the toolbar.
- **Background running:** Option to keep the app running in the background (minimize to tray / close window but keep process) for easier access without a full window always open.

Implementation approach: use Flutter desktop packages for tray and window lifecycle (e.g. **tray_manager**, **window_manager**) when this phase is started.

---

## 9. Summary Checklist

- [ ] Desktop: macOS + Windows only  
- [ ] ADB on PATH + configurable path in Settings  
- [ ] One device at a time  
- [ ] Devices: list, select, refresh + help  
- [ ] Shell: input, run, show output + help  
- [ ] Apps: list (with filter), uninstall / clear cache / clear data + confirmations + help  
- [ ] Handle “ADB not installed” with instructions/download link  
- [ ] Document min OS versions in-app  
- [ ] No admin/root required  

Use this doc as the single source of truth for scope when you start implementation.
c