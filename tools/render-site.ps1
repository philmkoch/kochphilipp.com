[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$quartoCommand = Get-Command quarto -ErrorAction SilentlyContinue
$quartoPath = if ($quartoCommand) {
  $quartoCommand.Source
}
else {
  'C:\Program Files\Quarto\bin\quarto.exe'
}

if (-not (Test-Path -LiteralPath $quartoPath)) {
  throw 'Quarto is not installed. Install it from https://quarto.org/docs/get-started/ and run this command again.'
}

& $quartoPath render
