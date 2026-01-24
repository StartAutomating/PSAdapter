#requires -Module PSSVG

$AssetsPath = $PSScriptRoot | Split-Path | Join-Path -ChildPath "Assets"

if (-not (Test-Path $AssetsPath)) {
    New-Item -ItemType Directory -Path $AssetsPath | Out-Null
}

$fontName = 'Noto Sans'

svg -content $(
    $commonParameters = [Ordered]@{
        Fill        = '#4488FF'
    }

    SVG.GoogleFont -FontName $fontName

    svg.symbol -Id psChevron -Content @(
        svg.polygon -Points (@(
            "40,20"
            "45,20"
            "60,50"
            "35,80"
            "32.5,80"
            "55,50"
        ) -join ' ')
    ) -ViewBox 100, 100


    svg.use -Href '#psChevron' -X -12% -Y 44% @commonParameters -Height 12% -Opacity .7
    svg.use -Href '#psChevron' -X 12% -Y 44% @commonParameters -Height 12% -Opacity .7
    
    svg.line -X1 -100% -X2 200% -Y1 55% -Y2 55% @commonParameters -StrokeWidth 1.2% -Stroke '#4488FF' -Opacity .5
    svg.line -X1 -100% -X2 200% -Y1 45% -Y2 45% @commonParameters -StrokeWidth 1.2% -Stroke '#4488FF' -Opacity .5
    svg.text -Text 'PSAdapter' -X 50% -Y 50% -FontSize .5em @commonParameters -DominantBaseline 'middle' -TextAnchor 'middle' -Style "font-family:'$fontName'"
) -ViewBox 0, 0, 200, 100 -OutputPath $(
    Join-Path $assetsPath PSAdapter.svg
)

