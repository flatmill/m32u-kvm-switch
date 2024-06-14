# KVM Switch for M32U

( English version / [日本語版](./README_ja.md) )

This is a software KVM switch for GIGABYTE M32U displays that runs on Windows.

## Description

- You can switch between displays from a shell command or the notification area without having to reach behind the display.
- By installing this tool on two connected Windows PCs, the display can be switched after the video output of the PC to be switched is turned on. This ensures stable display switching.

## Requirement

The following devices are required:

- [GIGABYTE M32U Gaming Monitor](https://www.gigabyte.com/Monitor/M32U#kf)
  - Other GIGABYTE displays may also work.
- Two Windows PCs connected to the above displays
  - To turn on the video output of the PC to be switched, the two PCs must be on the same network.

## Installation

Run it on each of the two PCs.

Download (clone) the file from the repository.

```powershell
PS> git clone https://github.com/flatmill/m32u-kvm-switch
```

Files downloaded from the Internet may block the script from running.
Unblock it for the `setup.ps1` and `m32u-kvm-switch.ps1` files in the repository.

```powershell
PS> cd m32u-kvm-switch
PS> Unblock-File -Path setup.ps1
PS> Unblock-File -Path m32u-kvm-switch.ps1
```

## Usage

### Adding a notify icon at Windows logon

Install the startup shortcut `startup-m32u-kvm-switch` to add the KVM switch to the notification area at Windows logon.
Use the `setup.ps1` script included in the repository for installation.

```powershell
PS> cd C:\path\to\m32u-kvm-switch
PS> .\setup.ps1 -Install -IPAddr xxx.xxx.xxx.xxx -MacAddr XX-XX-XX-XX-XX-XX
```

The meaning of the options in the `setup.ps1` script is as follows:

- `-Install` ... Installs the startup shortcut.
- `-Uninstall` ... Removes the installed startup shortcut.
- `-IPAddr xxx.xxx.xxx.xxx.xxx` ... Specify the IP address of the PC to switch to or the broadcast IP address of the network.
  - Example: If the network address is `192.168.0.0/24`, the following value is valid.
    - `-IPAddr 192.168.0.22` (IP address of the PC to switch to)
    - `-IPAddr 192.168.0.255` (Broadcast IP address)
- `-MacAddr XX-XX-XX-XX-XX-XX-XX-XX` ... Specifies the Mac address of the PC to switch to. The delimiter can be one of `-`, `:`, or omitted.

If neither `-Install` nor `-Uninstall` is specified, the startup folder will be opened in Explorer.

### Using Notification Icons

When resident, the following icons appear in the notification area.

![Icon for light mode](./kvm-switch-light.ico)(for light mode) / ![Icons for dark mode](./kvm-switch-dark.ico)(for dark mode)

Left-clicking this icon switches the display.

Right-clicking this icon displays the following context menu.

- KVM Switch ... The display will switch.
- Shutdown after KVM Switch ... Shutdown Windows after switching the display (a confirmation dialog will appear).
- Exit ... Exits resident and removes the icon from the notification area.

### Operating from the CLI

You can switch displays from the command line by running the `m32u-kvm-switch.ps1` script directly as follows:

```powershell
PS> cd C:\path\to\m32u-kvm-switch
PS> powershell -NoProfile -NoLogo -ExecutionPolicy Unrestricted -File .\m32u-kvm-switch.ps1 -IPAddr xxx.xxx.xxx.xxx -MacAddr XX-XX-XX-XX-XX-XX
```

Also, add the KVM switch to the notify area by adding `-Notify` to the `m32u-kvm-switch.ps1` script options as follows:

```powershell
PS> cd C:\path\to\m32u-kvm-switch
PS> powershell -NoProfile -NoLogo -ExecutionPolicy Unrestricted -File .\m32u-kvm-switch.ps1 -Notify -IPAddr xxx.xxx.xxx.xxx -MacAddr XX-XX-XX-XX-XX-XX
```

The `-IPAddr` and `-MacAddr` options are the same as those specified in the setup script.
However, the `-MacAddr` delimiter is valid only for `-` and cannot be omitted.

### Uninstall this tool

Remove the startup shortcut.
Execute the following command:

```powershell
PS> cd C:\path\to\m32u-kvm-switch
PS> .\setup.ps1 -Uninstall
```

Delete all downloaded (cloned) files and you are done.

## Author

flatmill

## License

[MIT](LICENSE.txt)
