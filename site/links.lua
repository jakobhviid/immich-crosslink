-- Links between the docs point at .md files, so they work on GitHub; on the site they point at the .html pages.
function Link(link)
  if not link.target:match("^%a[%w+.-]*:") then
    link.target = link.target:gsub("^([^#?]-)%.md([#?].*)$", "%1.html%2"):gsub("^([^#?]-)%.md$", "%1.html")
  end
  return link
end
