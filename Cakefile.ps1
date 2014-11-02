node node_modules\bower\bin\bower install
cp static\coffee\*.coffee static\coffee.out\
if (!(test-path static\coffee.out\workers)) { mkdir static\coffee.out\workers }
cp static\coffee\workers\* static\coffee.out\workers\
gci static/coffee.out/*.coffee | % {
  Write-Output "Compiling $($_.FullName)"
  node node_modules\iced-coffee-script\bin\coffee -c -m -o static/coffee.out/ $_.FullName
}
gci static\coffee.out\workers\*.coffee | % {
  Write-Output "Compiling $($_.FullName)"
  node node_modules\iced-coffee-script\bin\coffee -c -m -o static\coffee.out\workers\ $_.FullName
}
if (test-path static\coffee.out\bundle.map) { rm -force static\coffee.out\bundle.map }
if (test-path static\coffee.out\bundle.js) { rm -force static\coffee.out\bundle.js }
node node_modules\mapcat\bin\mapcat (gci static/coffee.out/*.map | % { $_.FullName }) -m static/coffee.out/bundle.map -j static/coffee.out/bundle.js
gci static\*.jade | % {
  node node_modules\jade\bin\jade -P -o static\ $_.FullName
}
