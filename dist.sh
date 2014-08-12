echo "Distribute"

gulp dist

mkdir -p gen/dist/gen
mkdir -p gen/dist/peg

cp package.json gen/dist
cp gen/T5.js gen/dist/gen
cp peg/* gen/dist/peg
cp README.md gen/dist

echo "Ready to publish"
echo "npm publish gen/dist"
