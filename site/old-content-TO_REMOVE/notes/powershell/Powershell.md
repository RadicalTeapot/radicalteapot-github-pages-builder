---
resource: Powershell
title: Powershell
---

> [!NOTE]
> A repository with the current profile and oh-my-posh theme [can be found here](https://github.com/RadicalTeapot/powershell-profile)

## Links

- <https://devtut.github.io/powershell/>

## Tips

### Run a Powershell script by double-clicking it

Just create a shortcut and use the following as the target value

`"C:\Program Files\PowerShell\7\pwsh.exe" -ExecutionPolicy Bypass -NoProfile -File "<absolute-path-to-ps1-file>.ps1"`

### `which` equivalent

`Get-Command <command-name>`

### Use arguments in a `ps1` file

```powershell
param($arg1, $anotherArg)
Write-Output "Args are $arg1 and $anotherArg"
```

### How to make a Powershell function stop and wait for user input before continuing?

To make a Powershell function stop and wait for user input before continuing, you can use the `Read-Host` cmdlet to
prompt the user for input. Here's an example:

```powershell
function WaitForInput { 
    Write-Host "This function will wait for your input"
    Read-Host "Press Enter to continue"
    Write-Host "Continuing..."
}

WaitForInput
```

In this example, the `WaitForInput` function will display a message and then use the `Read-Host` cmdlet to prompt the
user to press Enter to continue. Once the user presses Enter, the function will continue executing and display a message
indicating that it is continuing.

You can customize the message displayed by the `Read-Host` cmdlet to provide more specific instructions for the user if
needed.

### What does the `Read-Host` cmdlet return?

The `Read-Host` cmdlet in Powershell returns a string that represents the text entered by the user in response to the
prompt.

By default, `Read-Host` will return the entire string entered by the user, including any spaces or special characters.
You can capture the value returned by `Read-Host` and assign it to a variable, like this:

```powershell
$name = Read-Host "What is your name?" Write-Host "Hello, $name!"
```

In this example, the user is prompted to enter their name, and the value entered by the user is stored in the `$name`
variable. The `Write-Host` cmdlet is then used to display a greeting that includes the user's name.

You can also specify a prompt message for `Read-Host` without capturing the value entered by the user, like this:

```powershell
Read-Host "Press Enter to continue"
```

In this case, `Read-Host` will display the prompt message and wait for the user to press Enter before continuing. The
value entered by the user is not captured or stored anywhere.

### Create an alias for a command with parameters

From
[here](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/set-alias?view=powershell-7.4#example-5-create-an-alias-for-a-command-with-parameters)

You can't create an alias for a command with parameters and values.

To create an alias for a command, create a function that includes the command, and then create an alias to the function.

```powershell
Function CD32 {Set-Location -Path C:\Windows\System32}
Set-Alias -Name Go -Value CD32
```

### Search through command history

Using [[Fzf|FZF]]

```powershell
Get-Content (Get-PSReadlineOption).HistorySavePath | fzf --reverse  --height=40%
```

### Using .NET objects

Accessing static members

```powershell
[System.Numerics.Matrix4x4]::CreateRotationX(1)
```

Creating a new instance

```powershell
[System.Numerics.Vector3]::new(0,0,0)
```
