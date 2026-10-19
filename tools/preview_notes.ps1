[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Directory,
    [string]$OutputName = "预览.html"
)

$ErrorActionPreference = "Stop"
$resolvedDirectory = (Resolve-Path -LiteralPath $Directory).Path
$markdownFiles = Get-ChildItem -LiteralPath $resolvedDirectory -Filter "*.md" -File |
    Sort-Object Name

if (-not $markdownFiles) {
    throw "No Markdown files found in $resolvedDirectory"
}

$sections = New-Object System.Collections.Generic.List[string]
$navigation = New-Object System.Collections.Generic.List[string]
$index = 0

foreach ($file in $markdownFiles) {
    $index++
    $anchor = "note-$index"
    $title = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $rendered = (ConvertFrom-Markdown -LiteralPath $file.FullName).Html
    $encodedTitle = [System.Net.WebUtility]::HtmlEncode($title)
    $navigation.Add("<a href=`"#$anchor`">$encodedTitle</a>")
    $sections.Add(@"
<section id="$anchor" class="note-section">
$rendered
</section>
"@)
}

$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$html = @"
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(Split-Path -Leaf $resolvedDirectory) - 笔记预览</title>
<style>
:root {
  --page: #f3f0e8;
  --paper: #ffffff;
  --ink: #202124;
  --muted: #6b7280;
  --line: #ded8cc;
  --accent: #1f6f5f;
  --accent-soft: #e8f3ef;
  --code: #f5f3ee;
}
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0;
  background: var(--page);
  color: var(--ink);
  font-family: "Segoe UI", "Microsoft YaHei", "PingFang SC", sans-serif;
  line-height: 1.75;
}
.layout {
  display: grid;
  grid-template-columns: 280px minmax(0, 1fr);
  gap: 24px;
  width: min(1560px, 100%);
  margin: 0 auto;
  padding: 24px;
}
nav {
  position: sticky;
  top: 24px;
  align-self: start;
  max-height: calc(100vh - 48px);
  overflow: auto;
  padding: 22px;
  background: var(--paper);
  border: 1px solid var(--line);
  border-radius: 16px;
  box-shadow: 0 12px 32px rgba(51, 43, 29, .08);
}
nav h2 {
  margin: 0 0 14px;
  font-size: 18px;
}
nav a {
  display: block;
  margin: 7px 0;
  padding: 8px 10px;
  color: var(--ink);
  text-decoration: none;
  border-radius: 8px;
}
nav a:hover { background: var(--accent-soft); color: var(--accent); }
.meta {
  margin-top: 20px;
  color: var(--muted);
  font-size: 12px;
}
main {
  min-width: 0;
  padding: 48px clamp(24px, 5vw, 72px);
  background: var(--paper);
  border: 1px solid var(--line);
  border-radius: 16px;
  box-shadow: 0 12px 32px rgba(51, 43, 29, .08);
}
.note-section + .note-section {
  margin-top: 64px;
  padding-top: 40px;
  border-top: 2px solid var(--line);
}
h1, h2, h3, h4 { line-height: 1.35; scroll-margin-top: 20px; }
h1 { margin: 0 0 24px; font-size: clamp(30px, 4vw, 44px); }
h2 {
  margin-top: 46px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--line);
  font-size: 28px;
}
h3 { margin-top: 34px; font-size: 22px; color: var(--accent); }
h4 { margin-top: 28px; font-size: 18px; }
p { margin: 12px 0; }
img {
  display: block;
  width: 100%;
  height: auto;
  margin: 18px auto 30px;
  border: 1px solid var(--line);
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(33, 37, 41, .10);
}
table {
  display: block;
  width: 100%;
  margin: 18px 0;
  overflow-x: auto;
  border-collapse: collapse;
}
th, td {
  padding: 10px 12px;
  border: 1px solid var(--line);
  text-align: left;
  vertical-align: top;
}
th { background: var(--accent-soft); }
blockquote {
  margin: 20px 0;
  padding: 14px 18px;
  background: var(--accent-soft);
  border-left: 4px solid var(--accent);
  border-radius: 0 8px 8px 0;
}
code {
  padding: 2px 6px;
  background: var(--code);
  border-radius: 4px;
  font-family: "Cascadia Code", Consolas, monospace;
}
pre {
  padding: 18px;
  overflow: auto;
  background: var(--code);
  border: 1px solid var(--line);
  border-radius: 10px;
}
pre code { padding: 0; background: transparent; }
ul, ol { padding-left: 26px; }
hr { margin: 32px 0; border: 0; border-top: 1px solid var(--line); }
@media (max-width: 900px) {
  .layout { grid-template-columns: 1fr; padding: 12px; }
  nav { position: static; max-height: none; }
  main { padding: 26px 20px; }
}
@media print {
  body { background: white; }
  .layout { display: block; padding: 0; }
  nav { display: none; }
  main { border: 0; box-shadow: none; padding: 0; }
  .note-section + .note-section { page-break-before: always; }
  img { box-shadow: none; }
}
</style>
</head>
<body>
<div class="layout">
  <nav>
    <h2>章节索引</h2>
    $($navigation -join "`n")
    <div class="meta">生成时间：$generatedAt</div>
  </nav>
  <main>
    $($sections -join "`n")
  </main>
</div>
</body>
</html>
"@

$outputPath = Join-Path $resolvedDirectory $OutputName
[System.IO.File]::WriteAllText(
    $outputPath,
    $html,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Output $outputPath
