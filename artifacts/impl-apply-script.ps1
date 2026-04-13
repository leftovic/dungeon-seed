$patches = Get-ChildItem -Path .\neil-docs\impl-task-*.patch | Sort-Object Name
foreach ($p in $patches) {
  Write-Host "Applying $($p.Name)"
  git checkout -b ($p.BaseName)
  git apply --stat $p.FullName
  git apply $p.FullName
  git add -A
  git commit -m "Apply $($p.Name)"
}
Write-Host "All patches applied (local branches created). Review and push as needed."