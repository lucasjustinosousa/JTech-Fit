$WshShell = New-Object -ComObject WScript.Shell

# 1. Atalho na Área de Trabalho (Desktop)
$DesktopShortcut = $WshShell.CreateShortcut("C:\Users\TI\Desktop\TitanNovaFit.lnk")
$DesktopShortcut.TargetPath = "C:\Users\TI\Desktop\Foco\TitanNovaFit.vbs"
$DesktopShortcut.WorkingDirectory = "C:\Users\TI\Desktop\Foco"
$DesktopShortcut.Description = "Aplicativo de Acompanhamento de Treinos TitanNovaFit"
$DesktopShortcut.IconLocation = "C:\Users\TI\Desktop\Foco\assets\icons\titannovafit.ico"
$DesktopShortcut.Save()

# 2. Atalho na pasta do projeto
$FolderShortcut = $WshShell.CreateShortcut("C:\Users\TI\Desktop\Foco\TitanNovaFit.lnk")
$FolderShortcut.TargetPath = "C:\Users\TI\Desktop\Foco\TitanNovaFit.vbs"
$FolderShortcut.WorkingDirectory = "C:\Users\TI\Desktop\Foco"
$FolderShortcut.Description = "Aplicativo de Acompanhamento de Treinos TitanNovaFit"
$FolderShortcut.IconLocation = "C:\Users\TI\Desktop\Foco\assets\icons\titannovafit.ico"
$FolderShortcut.Save()

Write-Host "Atalhos com ícone ICO nativo atualizados com sucesso!"
