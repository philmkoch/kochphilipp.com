[CmdletBinding()]
param(
  [string]$DestinationRoot = (Join-Path $PSScriptRoot '..\archive\snapshots')
)

$ErrorActionPreference = 'Stop'
$siteRoot = [Uri]'https://www.kochphilipp.com/'
$snapshotName = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH-mm-ssZ')
$snapshotPath = Join-Path $DestinationRoot $snapshotName
$pagesPath = Join-Path $snapshotPath 'source-pages'
$downloadsPath = Join-Path $snapshotPath 'downloads'

New-Item -ItemType Directory -Force -Path $pagesPath, $downloadsPath | Out-Null

$pageSpecs = @(
  [PSCustomObject]@{ Name = 'home'; Url = 'https://www.kochphilipp.com/' },
  [PSCustomObject]@{ Name = 'publications'; Url = 'https://www.kochphilipp.com/publications' },
  [PSCustomObject]@{ Name = 'policy'; Url = 'https://www.kochphilipp.com/policy' }
)

$headers = @{ 'User-Agent' = 'kochphilipp.com migration archive' }
$inventory = [System.Collections.Generic.List[object]]::new()

function Resolve-AbsoluteUrl {
  param([string]$BaseUrl, [string]$Href)
  if ([string]::IsNullOrWhiteSpace($Href)) { return $null }
  try { return ([Uri]::new([Uri]$BaseUrl, $Href)).AbsoluteUri } catch { return $null }
}

function Get-AssetKind {
  param([string]$Url, [string]$Element)
  $path = ([Uri]$Url).AbsolutePath.ToLowerInvariant()
  if ($path.EndsWith('.pdf')) { return 'pdf' }
  if ($path -match '\.(png|jpe?g|webp|svg)$') { return 'image' }
  if ($Element -eq 'image') { return 'image' }
  return 'link'
}

foreach ($page in $pageSpecs) {
  Write-Host "Archiving $($page.Url)"
  $response = Invoke-WebRequest -Uri $page.Url -Headers $headers -UseBasicParsing -MaximumRedirection 10
  [System.IO.File]::WriteAllText((Join-Path $pagesPath "$($page.Name).html"), $response.Content, [System.Text.UTF8Encoding]::new($false))

  foreach ($link in $response.Links) {
    $absoluteUrl = Resolve-AbsoluteUrl -BaseUrl $page.Url -Href $link.href
    if ($absoluteUrl) {
      $inventory.Add([PSCustomObject]@{
        source_page = $page.Url
        element = 'link'
        label = (($link.innerText -replace '\s+', ' ').Trim())
        url = $absoluteUrl
        kind = (Get-AssetKind -Url $absoluteUrl -Element 'link')
      })
    }
  }

  foreach ($image in $response.Images) {
    $absoluteUrl = Resolve-AbsoluteUrl -BaseUrl $page.Url -Href $image.src
    if ($absoluteUrl) {
      $inventory.Add([PSCustomObject]@{
        source_page = $page.Url
        element = 'image'
        label = $image.alt
        url = $absoluteUrl
        kind = 'image'
      })
    }
  }
}

$uniqueInventory = $inventory | Sort-Object source_page, element, url -Unique
$uniqueInventory | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $snapshotPath 'link-inventory.csv')
$uniqueInventory | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $snapshotPath 'link-inventory.json')

$downloadCandidates = $uniqueInventory |
  Where-Object { $_.kind -in @('pdf', 'image') } |
  Sort-Object url -Unique

$manifest = [System.Collections.Generic.List[object]]::new()
$assetIndex = 0
foreach ($asset in $downloadCandidates) {
  $assetIndex++
  $assetUri = [Uri]$asset.url
  $leafName = [System.IO.Path]::GetFileName($assetUri.AbsolutePath)
  if ([string]::IsNullOrWhiteSpace($leafName)) { $leafName = "asset-$assetIndex" }
  $leafName = ($leafName -replace '[^A-Za-z0-9._-]', '_')
  $localName = ('{0:D2}-{1}' -f $assetIndex, $leafName)
  $localPath = Join-Path $downloadsPath $localName

  try {
    $downloadResponse = Invoke-WebRequest -Uri $asset.url -Headers $headers -UseBasicParsing -MaximumRedirection 10 -OutFile $localPath -PassThru
    $manifest.Add([PSCustomObject]@{
      kind = $asset.kind
      source_page = $asset.source_page
      original_url = $asset.url
      local_path = (Resolve-Path -LiteralPath $localPath).Path
      content_type = $downloadResponse.Headers['Content-Type']
      bytes = (Get-Item -LiteralPath $localPath).Length
      sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $localPath).Hash
      error = $null
    })
  }
  catch {
    if (Test-Path -LiteralPath $localPath) { Remove-Item -LiteralPath $localPath -Force }
    $manifest.Add([PSCustomObject]@{
      kind = $asset.kind
      source_page = $asset.source_page
      original_url = $asset.url
      local_path = $null
      content_type = $null
      bytes = $null
      sha256 = $null
      error = $_.Exception.Message
    })
  }
}

$manifest | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $snapshotPath 'download-manifest.csv')
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $snapshotPath 'download-manifest.json')

[PSCustomObject]@{
  snapshot = $snapshotName
  root = (Resolve-Path -LiteralPath $snapshotPath).Path
  pages = $pageSpecs.Count
  links = $uniqueInventory.Count
  downloaded_assets = @($manifest | Where-Object { -not $_.error }).Count
  failed_assets = @($manifest | Where-Object { $_.error }).Count
} | ConvertTo-Json
