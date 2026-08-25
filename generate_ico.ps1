Add-Type -AssemblyName System.Drawing

$pngPath = "c:\Users\TI\Desktop\Foco\assets\icons\icon-512.png"
$icoPath = "c:\Users\TI\Desktop\Foco\assets\icons\jtech_fit.ico"

$bmp = [System.Drawing.Bitmap]::FromFile($pngPath)
$hIcon = $bmp.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($hIcon)

$stream = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
$icon.Save($stream)
$stream.Close()

Write-Host "Arquivo ICO nativo gerado em jtech_fit.ico!"
