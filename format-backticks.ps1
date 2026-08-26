$files = Get-ChildItem -Path "src/reference-designs/gemfire" -Filter "*.md"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # We want to replace gfsh if it's not preceded by a backtick, not in a URL, and not in a markdown heading anchor
    # A safe way is to use a negative lookbehind and lookahead for backticks and hyphens/slashes
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?<![`/\-])\bgfsh\b(?![`\-])', '`gfsh`')
    
    # Let's fix log4j2.xml
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?<![`/])\blog4j2\.xml\b(?!`)', '`log4j2.xml`')
    
    # Let's fix gemfire.properties
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?<![`/])\bgemfire\.properties\b(?!`)', '`gemfire.properties`')

    # cache.xml
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?<![`/])\bcache\.xml\b(?!`)', '`cache.xml`')

    # cluster.xml
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?<![`/])\bcluster\.xml\b(?!`)', '`cluster.xml`')

    # cluster.properties
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?<![`/])\bcluster\.properties\b(?!`)', '`cluster.properties`')

    Set-Content -Path $file.FullName -Value $content -NoNewline
}
