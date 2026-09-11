# Vérifier les pages finales sans modifier leurs contenus.
$ErrorActionPreference = 'Stop'
$racineSite = (Resolve-Path -LiteralPath '_site').Path
$pages = @('index.html', 'reports/rapport_scientifique.html', 'reports/annexes.html', 'reports/note_decideur.html')
$controles = [System.Collections.Generic.List[object]]::new()
foreach ($page in $pages) {
    $cheminPage = Join-Path $racineSite $page
    if (-not (Test-Path -LiteralPath $cheminPage)) { throw "Page absente : $page" }
    $contenu = Get-Content -LiteralPath $cheminPage -Raw -Encoding UTF8
    $controles.Add([pscustomobject]@{page=$page; controle='Langue française'; cible='lang=fr'; succes=($contenu -match 'lang="fr"')})
    $controles.Add([pscustomobject]@{page=$page; controle='Mention simulation'; cible='Données simulées'; succes=($contenu -match 'Données simulées')})
    $controles.Add([pscustomobject]@{page=$page; controle='Références résolues'; cible='aucune référence inconnue'; succes=($contenu -notmatch 'quarto-xref-unresolved|\?\?\s*(tbl|fig)-')})
    foreach ($lien in [regex]::Matches($contenu, '(?:href|src)="([^"]+)"')) {
        $url = [System.Net.WebUtility]::HtmlDecode($lien.Groups[1].Value)
        if ($url -match '^(https?:|mailto:|data:|javascript:)' -or $url -in @('', '#', '#top')) { continue }
        $morceaux = $url.Split('#',2)
        $partie = [uri]::UnescapeDataString(($morceaux[0] -split '\?')[0])
        if ($partie -eq '') { $cible = $cheminPage }
        elseif ($partie.StartsWith('/')) { $cible = Join-Path $racineSite $partie.TrimStart('/') }
        else { $cible = Join-Path (Split-Path $cheminPage -Parent) $partie }
        $existe = Test-Path -LiteralPath $cible
        if ($existe -and (Get-Item -LiteralPath $cible).PSIsContainer) { $cible = Join-Path $cible 'index.html'; $existe = Test-Path -LiteralPath $cible }
        $ok = $existe
        if ($ok -and $morceaux.Count -gt 1 -and $morceaux[1] -ne '' -and $cible.EndsWith('.html')) {
            $ancre = [regex]::Escape([uri]::UnescapeDataString($morceaux[1]))
            $texteCible = Get-Content -LiteralPath $cible -Raw -Encoding UTF8
            $ok = $texteCible -match ('id="' + $ancre + '"')
        }
        $controles.Add([pscustomobject]@{page=$page; controle='Lien ou ressource locale'; cible=$url; succes=$ok})
    }
}
$controles | Export-Csv -LiteralPath 'outputs/tables/audit_rapport.csv' -NoTypeInformation -Encoding UTF8
$echecs = @($controles | Where-Object { -not $_.succes })
Write-Output "Contrôles HTML : $($controles.Count) ; échecs : $($echecs.Count)"
if ($echecs.Count -gt 0) { $echecs | Format-Table -AutoSize; throw 'Corriger les liens ou ressources avant publication.' }
