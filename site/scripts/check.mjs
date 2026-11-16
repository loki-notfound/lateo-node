// Static checks of the site: every page has a title and a description, loads
// nothing from another origin, and links only to pages and assets that exist.
// Run: npm run check (from site/).
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative } from "node:path";

const root = new URL("../public/", import.meta.url).pathname;
const failures = [];

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? walk(path) : [path];
  });
}

function resolveLocal(href) {
  const path = href.split("#")[0];
  if (path === "") return true;
  const target = join(root, path);
  if (path.endsWith("/")) return existsSync(join(target, "index.html"));
  return existsSync(target);
}

for (const file of walk(root).filter((f) => f.endsWith(".html"))) {
  const name = relative(root, file);
  const html = readFileSync(file, "utf8");
  if (!/<title>[^<]+<\/title>/.test(html)) failures.push(`${name}: no title`);
  if (!/<meta name="description" content="[^"]+">/.test(html)) failures.push(`${name}: no description`);
  if (/<script\b/i.test(html)) failures.push(`${name}: contains a script`);
  for (const [tag] of html.matchAll(/<link\b[^>]*>/gi)) {
    if (/\bhref="(?!\/)/.test(tag)) failures.push(`${name}: external link element ${tag}`);
  }
  for (const [, attr, value] of html.matchAll(/\b(src|href)="([^"]*)"/g)) {
    if (value.startsWith("/")) {
      if (!resolveLocal(value)) failures.push(`${name}: broken link ${value}`);
    } else if (attr === "src") {
      failures.push(`${name}: external resource ${value}`);
    } else if (!value.startsWith("https://")) {
      failures.push(`${name}: link is neither local nor https: ${value}`);
    }
  }
}

if (failures.length) {
  console.error(failures.join("\n"));
  process.exit(1);
}
console.log("site check OK");
