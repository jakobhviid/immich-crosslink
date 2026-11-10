#!/bin/sh
# Builds the site from docs/ into _site/ with pandoc 3.8 (a local pandoc, or the pandoc/core image with podman or docker).
set -eu
cd "$(dirname "$0")"
if command -v pandoc >/dev/null 2>&1; then
    run() { pandoc "$@"; }
else
    engine=$(command -v podman || command -v docker)
    run() { "$engine" run --rm -v "$PWD:/data:z" -w /data docker.io/pandoc/core:3.8 "$@"; }
fi
rm -rf _site && mkdir -p _site
cp site/style.css site/assets/* _site/
# Pages lets browsers keep files for ten minutes: the stylesheet's and icons' addresses carry their content's hash, so
# a changed file is fetched at once, and an unchanged one stays cached.
version=$(cat site/style.css site/assets/* | sha256sum | cut -c1-10)
for page in docs/*.md; do
    name=$(basename "$page" .md)
    case "$name" in
        spec) extra="--toc --toc-depth=2 --number-sections" ;;
        implementing) extra="--toc --toc-depth=2" ;;
        *) extra="" ;;
    esac
    title=$(sed -n 's/^title: //p' "$page" | head -1)
    case "$title" in
        *immich-crosslink*) pagetitle="$title" ;;
        *) pagetitle="$title · immich-crosslink" ;;
    esac
    # shellcheck disable=SC2086
    run "$page" --from=markdown --to=html5 --standalone --template=site/template.html \
        --lua-filter=site/links.lua --shift-heading-level-by=1 --syntax-highlighting=none \
        --metadata=source:"$name.md" --metadata=version:"$version" --metadata=pagetitle:"$pagetitle" \
        $extra --output="_site/$name.html"
done
echo "Built $(ls _site/*.html | wc -l) pages into _site/"
