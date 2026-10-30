// Brand key art for featuring: plumage crest with the app-icon ¡ at its heart. No text,
// no devices. (W, H) canvas; s = scale of the crest (1 ≈ 1100 px tall).
function keyArt(W, H, s) {
  blob(-W * 0.05, -H * 0.15, W * 0.42, H * 1.1, "#0E7C47", 220 * s, .5);
  blob(W * 0.6, H * 0.05, W * 0.42, H * 1.1, "#0E7C47", 220 * s, .45);
  mark("¿", W * 0.06, H * 0.18, 1200 * s, "#16301F", -12);
  mark("¡", W * 0.84, H * 0.02, 1300 * s, "#16301F", 10);
  const cx = W / 2, base = H / 2 + 465 * s;   // crest spans base-1250s … base+320s
  [["#0E7C47",-80],["#3BB273",-54],["#CBEF6B",-27],["#E5482A",0],["#CBEF6B",27],["#3BB273",54],["#0E7C47",80]].forEach(([c, r]) => {
    const f = feather(cx - 190 * s, base - 1250 * s, 380 * s, 1250 * s, c, 0, .96);
    f.style.borderRadius = "50% 50% 50% 50% / 60% 60% 40% 40%";
    f.style.transformOrigin = "50% 100%"; f.style.transform = `rotate(${r}deg)`;
  });
  blob(cx - 420 * s, base - 520 * s, 840 * s, 840 * s, "#0F1A14", 0, 1);
  const g = glyph(0, 0, 640 * s);
  g.style.left = (cx - 640 * s * 249 / 771 / 2) + "px"; g.style.top = (base - 420 * s) + "px";
}
