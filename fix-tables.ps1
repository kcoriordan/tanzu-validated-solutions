$files = Get-ChildItem -Path src/reference-designs/gemfire/ -Filter *.md

foreach ($file in $files) {
    $lines = Get-Content $file.FullName
    $newLines = @()
    $inTable = $false
    $currentRow = ""

    foreach ($line in $lines) {
        if ($line -match '^\s*\|') {
            if ($inTable -and $currentRow -ne "") {
                $newLines += $currentRow
            }
            $inTable = $true
            $currentRow = $line
        } elseif ($inTable) {
            if ($line -match '^\s*$') {
                # Empty line ends the table
                if ($currentRow -ne "") {
                    $newLines += $currentRow
                    $currentRow = ""
                }
                $inTable = $false
                $newLines += $line
            } elseif ($line -match '^\s*#|^\s*\*|^\s*-|^\s*>|^\s*\d+\.|^\s*<|^\s*```') {
                # Another block element ends the table
                if ($currentRow -ne "") {
                    $newLines += $currentRow
                    $currentRow = ""
                }
                $inTable = $false
                $newLines += $line
            } else {
                # Continuation of the table row
                $currentRow += " " + $line.Trim()
            }
        } else {
            $newLines += $line
        }
    }
    if ($currentRow -ne "") {
        $newLines += $currentRow
    }

    Set-Content $file.FullName $newLines -Encoding UTF8
}
