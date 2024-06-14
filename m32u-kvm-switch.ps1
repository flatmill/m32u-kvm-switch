# SPDX-License-Identifier: MIT
# See LICENSE.txt for more information.

# Software KVM Switch for GIGABYTE M32U
#
# SYNTAX
#   m32u-kvm-switch.ps1 [-Notify] -IPAddr <string> -MacAddr <string>
#
# e.g.)
#   m32u-kvm-switch.ps1 -Notify -IPAddr 192.168.0.255 -MacAddr 12-34-56-78-9a-bc

param (
    [switch]$Notify,
    [string]$IPAddr,
    [string]$MacAddr
)

# UDP receive port No.
$UDP_PORT = 9;
# UDP timer interval (milliseconds)
$UDP_TIMER_INTERVAL = 100;
# KVM switch delay (milliseconds)
$KVM_DELAY = 500;

Add-Type -AssemblyName System.Windows.Forms;

# HidDevicePathFinder class
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class HidDevicePathFinder {
    private const uint DIGCF_DEVICEINTERFACE = 0x00000010;
    private const uint DIGCF_PRESENT = 0x00000002;
    private const int INVALID_HANDLE_VALUE = -1;

    [DllImport("hid.dll")]
    private static extern void HidD_GetHidGuid(out Guid hidGuid);

    [DllImport("setupapi.dll", SetLastError = true)]
    private static extern IntPtr SetupDiGetClassDevs(ref Guid classGuid, [MarshalAs(UnmanagedType.LPTStr)] string enumerator, IntPtr hwndParent, uint flags);

    [DllImport("setupapi.dll", SetLastError = true)]
    private static extern bool SetupDiEnumDeviceInterfaces(IntPtr hDevInfo, IntPtr deviceInfoData, ref Guid interfaceClassGuid, uint memberIndex, ref SP_DEVICE_INTERFACE_DATA deviceInterfaceData);

    [DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetupDiGetDeviceInterfaceDetail(IntPtr hDevInfo, ref SP_DEVICE_INTERFACE_DATA deviceInterfaceData, ref SP_DEVICE_INTERFACE_DETAIL_DATA deviceInterfaceDetailData, uint deviceInterfaceDetailDataSize, out uint requiredSize, ref SP_DEVINFO_DATA deviceInfoData);

    [DllImport("setupapi.dll", CharSet = CharSet.Auto, EntryPoint = "SetupDiGetDeviceInterfaceDetail", SetLastError = true)]
    private static extern IntPtr SetupDiGetDeviceInterfaceDetail_GetSize(IntPtr hDevInfo, ref SP_DEVICE_INTERFACE_DATA deviceInterfaceData, IntPtr deviceInterfaceDetailData, uint deviceInterfaceDetailDataSize, out uint requiredSize, ref SP_DEVINFO_DATA deviceInfoData);

    [StructLayout(LayoutKind.Sequential)]
    private struct SP_DEVICE_INTERFACE_DATA {
        public uint cbSize;
        public Guid InterfaceClassGuid;
        public uint Flags;
        public IntPtr Reserved;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private struct SP_DEVICE_INTERFACE_DETAIL_DATA {
        public uint cbSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string DevicePath;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct SP_DEVINFO_DATA {
        public uint cbSize;
        public Guid ClassGuid;
        public uint DevInst;
        public IntPtr Reserved;
    }

    public static string GetDevicePath(ushort vendorId, ushort productId) {
        Guid hidGuid;
        HidD_GetHidGuid(out hidGuid);

        IntPtr hDevInfo = SetupDiGetClassDevs(ref hidGuid, null, IntPtr.Zero, DIGCF_DEVICEINTERFACE | DIGCF_PRESENT);
        if (hDevInfo.ToInt64() == INVALID_HANDLE_VALUE) {
            return null;
        }

        SP_DEVICE_INTERFACE_DATA deviceInterfaceData = new SP_DEVICE_INTERFACE_DATA();
        deviceInterfaceData.cbSize = (uint)Marshal.SizeOf(deviceInterfaceData);

        SP_DEVINFO_DATA deviceInfoData = new SP_DEVINFO_DATA();
        deviceInfoData.cbSize = (uint)Marshal.SizeOf(deviceInfoData);

        string targetDeviceStr = string.Format("vid_{0:x4}&pid_{1:x4}", vendorId, productId);

        uint memberIndex = 0;
        while (SetupDiEnumDeviceInterfaces(hDevInfo, IntPtr.Zero, ref hidGuid, memberIndex, ref deviceInterfaceData)) {
            uint requiredSize = 0;
            SetupDiGetDeviceInterfaceDetail_GetSize(hDevInfo, ref deviceInterfaceData, IntPtr.Zero, 0, out requiredSize, ref deviceInfoData);

            SP_DEVICE_INTERFACE_DETAIL_DATA deviceInterfaceDetailData = new SP_DEVICE_INTERFACE_DETAIL_DATA();
            deviceInterfaceDetailData.cbSize = (uint)(IntPtr.Size == 8 ? 8 : 5);
            
            if (SetupDiGetDeviceInterfaceDetail(hDevInfo, ref deviceInterfaceData, ref deviceInterfaceDetailData, requiredSize, out requiredSize, ref deviceInfoData) != IntPtr.Zero) {
                string devicePath = deviceInterfaceDetailData.DevicePath;
                if (devicePath.ToLower().Contains(targetDeviceStr)) {
                    return devicePath;
                }
            }
            memberIndex++;
        }

        return null;
    }
}
"@

# HidReportSender class
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public class HidReportSender {
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern SafeFileHandle CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        IntPtr lpSecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool WriteFile(
        SafeFileHandle hFile,
        byte[] lpBuffer,
        uint nNumberOfBytesToWrite,
        out uint lpNumberOfBytesWritten,
        IntPtr lpOverlapped
    );

    public static bool SendHidReport(string devicePath, byte reportId, byte[] reportData) {
        SafeFileHandle hidDevice = CreateFile(
            devicePath,
            0xC0000000, // GENERIC_READ (0x80000000) | GENERIC_WRITE (0x40000000)
            3, // FILE_SHARE_READ (0x00000001) | FILE_SHARE_WRITE (0x00000002),
            IntPtr.Zero,
            3, // OPEN_EXISTING
            0,
            IntPtr.Zero
        );

        if (!hidDevice.IsInvalid) {
            // Add Report ID first
            byte[] reportBuffer = new byte[reportData.Length + 1];
            reportBuffer[0] = reportId;
            Array.Copy(reportData, 0, reportBuffer, 1, reportData.Length);

            uint bytesWritten;
            bool success = WriteFile(hidDevice, reportBuffer, (uint)reportBuffer.Length, out bytesWritten, IntPtr.Zero);
            //if (!success) {
            //    Console.WriteLine("Failed to send HID report. Error code: " + Marshal.GetLastWin32Error());
            //}
            return success;
        } else {
            //Console.WriteLine("Failed to open HID device.");
            return false;
        }
    }
}
"@

$SendMouseEvent = Add-Type -memberDefinition @' 
     [DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
     public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
'@ -name "Win32MouseEventNew" -namespace Win32Functions -passThru
$MOUSEEVENTF_MOVE = 0x00000001

function IsEqual-ByteArrays {
    param (
        [byte[]] $lhs,
        [byte[]] $rhs
    )
    if ($lhs.Length -ne $rhs.Length) {
        return $false;
    }
    for ($i = 0; $i -lt $lhs.Length; $i++) {
        if ($lhs[$i] -ne $rhs[$i]) {
            return $false;
        }
    }
    return $true;
}

function exec_kvm_switch {
    try {
        $targetIP = [System.Net.IPAddress]::Parse($IPAddr);
        
        # Send WOL magic packet
        $mac = [byte[]]($MacAddr.split("-") | ForEach-Object{[Convert]::ToInt32($_, 16)});
        $magicPacket = ([byte[]](@(0xff) * 6)) + $mac * 16;
        $udpClient=new-object System.Net.Sockets.UdpClient;
        $udp = New-Object System.Net.Sockets.UdpClient;
        [void]$udp.Connect($targetIP, $UDP_PORT);
        [void]$udp.Send($magicPacket, $magicPacket.Length);
        [void]$udp.Close();
        
        # Delay
        Start-Sleep -Milliseconds $KVM_DELAY;
    } catch {
    }
    
    # Send KVM switch to M32U (VID=0x0BDA, PID=0x1100)
    #   HID Report was generated with reference to the algorithm from the following project:
    #       https://github.com/kelvie/gbmonctl
    $vendorId = 0x0BDA;
    $productId = 0x1100;
    $reportId = 0;
    [byte[]]$reportData = @(0x40, 0xc6,    0,    0,    0,    0, 0x20,    0,
                            0x6e,    0, 0x80,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                            0x51, 0x85, 0x03, 0xe0, 0x69,    0, 0x00,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0,
                               0,    0,    0,    0,    0,    0,    0,    0);
    $devicePath = [HidDevicePathFinder]::GetDevicePath($vendorId, $productId);
    if ($devicePath -eq $null) {
        return "Device not found.";
    }
    #Write-Host "Sent KVM switch";
    $result = [HidReportSender]::SendHidReport($devicePath, $reportId, $reportData);
    if (!$result) {
        return "Failed to send HID report.";
    }
    return $null;    # No error
}

function receive_udp_message {
    param (
        [byte[]] $msg
    )    
    # Get MAC Addresses
    foreach ($macAddrStr in (Get-NetAdapter | Select MacAddress)) {
        $mac = [byte[]]($macAddrStr.MacAddress.split("-") | ForEach-Object{[Convert]::ToInt32($_, 16)});
        $magicPacket = ([byte[]](@(0xff) * 6)) + $mac * 16;
        if (IsEqual-ByteArrays $msg $magicPacket) {
            # Move mouse
            $SendMouseEvent::mouse_event($MOUSEEVENTF_MOVE, -10, 0, 0, 0);
            Start-Sleep -Milliseconds 50;
            $SendMouseEvent::mouse_event($MOUSEEVENTF_MOVE, 10, 0, 0, 0);
            #Write-Host "Received magic packet";
        }
    }
}

function main() {
    $MUTEX_NAME = 'mutex/m32u-kvm-switch';
    $mutex = New-Object System.Threading.Mutex($false, $MUTEX_NAME)
    if (!($mutex.WaitOne(0, $false))) {
        $mutex.Close();
        exit;
    }
    
    # Add udp receive timer
    $udpRecv = New-Object Net.Sockets.UdpClient($UDP_PORT);
    $timer = New-Object Windows.Forms.Timer;
    $timer.Add_Tick({
        if ($udpRecv.Available) {
            $timer.Stop();
            $buf = $udpRecv.Receive([ref]$null);
            receive_udp_message($buf);
            $timer.Interval = $UDP_TIMER_INTERVAL;
            $timer.Start();
        }
    });
    $timer.Interval = $UDP_TIMER_INTERVAL;
    $timer.Start();
    
    # Hide Powershell Terminal
    $code = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);';
    $asyncWindow = Add-Type -MemberDefinition $code -Name Win32ShowWindowAsync -NameSpace 'Win32' -PassThru;
    $windowHandle = (Get-Process -PID $pid).MainWindowHandle;
    [void]$asyncWindow::ShowWindowAsync($windowHandle, 0);
    
    # Add icon to task tray
    $notifyIcon = New-Object Windows.Forms.NotifyIcon;
    $code = '[DllImport("UXTheme.dll", SetLastError = true, EntryPoint = "#138")] public static extern bool ShouldSystemUseDarkMode();';
    $systemUseDarkMode = Add-Type -MemberDefinition $code -Name UXThemeShouldSystemUseDarkMode -NameSpace 'Win32' -PassThru;
    $isDarkMode = $systemUseDarkMode::ShouldSystemUseDarkMode();
    if ($isDarkMode) {
        $iconPath = Join-Path $PSScriptRoot kvm-switch-dark.ico
    } else {
        $iconPath = Join-Path $PSScriptRoot kvm-switch-light.ico
    }
    $notifyIcon.Icon = New-Object System.Drawing.Icon $iconPath
    $notifyIcon.Text = 'KVM Switch for M32U';
    $notifyIcon.add_Click({
        if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $result = exec_kvm_switch;
            if (![string]::IsNullOrEmpty($result)) {
                $notifyIcon.ShowBalloonTip(5000, 'KVM Switch for M32U', $result, [System.Windows.Forms.ToolTipIcon]::Error);
            }
        }
    });
    $notifyIcon.Visible = $true;
    
    # Initialize ApplicationContext
    $applicationContext = New-Object Windows.Forms.ApplicationContext;

    # KVM Switch Menu
    $menuItemKVM = New-Object Windows.Forms.MenuItem;
    $menuItemKVM.Text = 'KVM Switch';
    $menuItemKVM.add_Click({
        $result = exec_kvm_switch;
        if (![string]::IsNullOrEmpty($result)) {
            $notifyIcon.ShowBalloonTip(5000, 'KVM Switch for M32U', $result, [System.Windows.Forms.ToolTipIcon]::Error);
        }
    });

    # Shutdown after KVM Switch Menu
    $menuItemShutdown = New-Object Windows.Forms.MenuItem;
    $menuItemShutdown.Text = 'Shutdown after KVM Switch';
    $menuItemShutdown.add_Click({
        $answer = [System.Windows.Forms.MessageBox]::Show("Shutdown now?", "KVM Switch for M32U", "YesNo", "Question", "Button2", "DefaultDesktopOnly");
        if ($answer -eq "Yes") {
            $result = exec_kvm_switch;
            if (![string]::IsNullOrEmpty($result)) {
                $notifyIcon.ShowBalloonTip(5000, 'KVM Switch for M32U', $result, [System.Windows.Forms.ToolTipIcon]::Error);
            } else {
                Stop-Computer;
            }
        }
    });

    # Exit Menu
    $menuItemExit = New-Object Windows.Forms.MenuItem;
    $menuItemExit.Text = 'Exit';
    $menuItemExit.add_Click({
        $applicationContext.ExitThread();
    });

    # Add contextmenu
    $notifyIcon.ContextMenu = New-Object Windows.Forms.ContextMenu;
    $notifyIcon.contextMenu.MenuItems.AddRange($menuItemKVM);
    $notifyIcon.contextMenu.MenuItems.AddRange($menuItemShutdown);
    $notifyIcon.contextMenu.MenuItems.AddRange('-');
    $notifyIcon.contextMenu.MenuItems.AddRange($menuItemExit);

    try {
        [void][Windows.Forms.Application]::Run($applicationContext);
    } finally {
        $notifyIcon.Visible = $false;
        $timer.Stop();
        $udpRecv.Close();
        $mutex.ReleaseMutex();
        $mutex.Close();
    }
}

if ($Notify) {
    main;
} else {
    exec_kvm_switch;
}
