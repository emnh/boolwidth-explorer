node node_modules\bower\bin\bower install
cp static\coffee\*.coffee static\coffee.out\
if (!(test-path static\coffee.out\workers)) { mkdir static\coffee.out\workers }
cp static\coffee\workers\* static\coffee.out\workers\
Function icedCoffee {
  param($outDir, $in)
  $out = Join-Path $outDir (Split-Path -Leaf $in)
  if ((Get-Item $in).LastWriteTime -gt (Get-Item $outDir).LastWriteTime) {
    Write-Output "Compiling $in"
    node node_modules\iced-coffee-script\bin\coffee --runtime "inline" -c -m -o $outDir $in
  } else {
    Write-Output "Already compiled $in to $out"
  }
}
Function jade {
   param($outDir, $in)
  $out = (Join-Path $outDir (Split-Path -Leaf $in)) -replace 'jade','html'
  if ((Get-Item $in).LastWriteTime -gt (Get-Item $outDir).LastWriteTime) {
    Write-Output "Compiling $in"
    node node_modules\jade\bin\jade -P -o $outDir $in
  } else {
    Write-Output "Already compiled $in to $out"
  }
}
gci static/coffee.out/*.coffee | % {
  icedCoffee static/coffee.out/ $_.FullName
}
gci static\coffee.out\workers\*.coffee | % {
  icedCoffee static\coffee.out\workers\ $_.FullName
}
if (test-path static\coffee.out\bundle.map) { rm -force static\coffee.out\bundle.map }
if (test-path static\coffee.out\bundle.js) { rm -force static\coffee.out\bundle.js }
node node_modules\mapcat\bin\mapcat (gci static/coffee.out/*.map | % { $_.FullName }) -m static/coffee.out/bundle.map -j static/coffee.out/bundle.js
gci static\*.jade | % {
  jade static\ $_.FullName
}
