$WshShell = New-Object -ComObject WScript.Shell

# 1. Atalho na Área de Trabalho (Desktop)
$DesktopShortcut = $WshShell.CreateShortcut("C:\Users\TI\Desktop\JTech Fit.lnk")
$DesktopShortcut.TargetPath = "C:\Users\TI\Desktop\Foco\JTech-Fit.vbs"
$DesktopShortcut.WorkingDirectory = "C:\Users\TI\Desktop\Foco"
$DesktopShortcut.Description = "Aplicativo de Acompanhamento de Treinos JTech Fit"
$DesktopShortcut.IconLocation = "C:\Users\TI\Desktop\Foco\assets\icons\jtech_fit.ico"
$DesktopShortcut.Save()

# 2. Atalho na pasta do projeto
$FolderShortcut = $WshShell.CreateShortcut("C:\Users\TI\Desktop\Foco\JTech Fit.lnk")
$FolderShortcut.TargetPath = "C:\Users\TI\Desktop\Foco\JTech-Fit.vbs"
$FolderShortcut.WorkingDirectory = "C:\Users\TI\Desktop\Foco"
$FolderShortcut.Description = "Aplicativo de Acompanhamento de Treinos JTech Fit"
$FolderShortcut.IconLocation = "C:\Users\TI\Desktop\Foco\assets\icons\jtech_fit.ico"
$FolderShortcut.Save()

Write-Host "Atalhos com ícone ICO nativo atualizados com sucesso!"
