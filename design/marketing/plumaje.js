// Plumaje marketing art helpers. Query: ?cap=<dir with "Lorito iPhone-<scene>.png" captures>.
const params = new URLSearchParams(location.search);
const CAP = params.get("cap") || "../../fastlane/screenshots_raw/ru";
const cap = scene => `${CAP}/Lorito iPhone-${scene}.png`;

function el(html) { const t = document.createElement("template"); t.innerHTML = html.trim(); return document.body.appendChild(t.content.firstChild); }

// The app-icon ¡: Lima stem + Chile eye. h = height in px; x, y = top-left.
function glyph(x, y, h, opts = {}) {
  const w = h * 249 / 771;
  return el(`<svg class="glyph" viewBox="40 -615 249 771" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px;${opts.style || ""}">
    <g transform="scale(1 -1)"><path d="M284 -155H45L83 317H246Z" fill="${opts.stem || "#CBEF6B"}"/>
    <circle cx="164.5" cy="490.5" r="124" fill="${opts.eye || "#E5482A"}"/></g></svg>`);
}
// Inline icon tile (rounded Loro square with the ¡), size in px.
function iconTile(size) {
  return `<div style="width:${size}px;height:${size}px;border-radius:${size*0.225}px;background:#0E7C47;flex:none;display:flex;align-items:center;justify-content:center">
    <svg viewBox="40 -615 249 771" style="height:${size*0.71}px"><g transform="scale(1 -1)"><path d="M284 -155H45L83 317H246Z" fill="#CBEF6B"/><circle cx="164.5" cy="490.5" r="124" fill="#E5482A"/></g></svg></div>`;
}
// Upright ¿ / ¡ as type in Unbounded (decorative, low contrast).
function mark(ch, x, y, size, color, rot = 0, op = 1) {
  return el(`<div class="title" style="position:absolute;left:${x}px;top:${y}px;font-size:${size}px;line-height:1;color:${color};opacity:${op};transform:rotate(${rot}deg)">${ch}</div>`);
}
function blob(x, y, w, h, color, blur = 0, op = 1) {
  return el(`<div class="blob" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px;background:${color};--blur:${blur}px;opacity:${op}"></div>`);
}
function feather(x, y, w, h, color, rot = 0, op = 1) {
  return el(`<div class="feather" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px;background:${color};transform:rotate(${rot}deg);opacity:${op}"></div>`);
}
// Phone frame; x, y = top-left; w = outer width (height follows the 1320×2868 capture).
function phone(scene, x, y, w, rot = 0) {
  return el(`<div class="phone" style="--pw:${w}px;left:${x}px;top:${y}px;transform:rotate(${rot}deg)"><img src="${cap(scene)}"></div>`);
}
const phoneH = w => (w - 2 * w * 0.028) * 2868 / 1320 + 2 * w * 0.028;
