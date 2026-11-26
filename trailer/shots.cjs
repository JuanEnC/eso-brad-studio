const {execFileSync} = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const ffmpeg = require("ffmpeg-static");

const source = process.argv[2] || "master";
const logName = source === "gameplay" ? "capture" : source;
const log = fs.readFileSync(path.join(__dirname, "capture", logName + ".log"), "utf8");
const markers = Object.fromEntries([...log.matchAll(/TAKE (\w+) (\d+)/g)].map((match) => [match[1], Number(match[2])]));
const cutlist = [
  ["hook", "frac", 125, 90],
  ["dash", "combate", 43, 150],
  ["bank", "rebote", 22, 210],
  ["opening", "combate", 102, 180],
  ["fracture", "frac", 6, 240],
  ["laser", "descenso", 0, 210],
  ["descent", "descenso", 210, 210],
  ["guardian", "guardian", 9, 180],
  ["fury", "guardian", 201, 210],
];

const media = path.join(__dirname, "public", "media");
fs.mkdirSync(media, {recursive: true});
for (const [file, marker, offset, frames] of cutlist) {
  const frame = markers[marker];
  if (!Number.isFinite(frame)) throw new Error(`Falta la marca de captura ${marker}`);
  const duration = frames / 60;
  const sound = [
    "highpass=f=45",
    "acompressor=threshold=0.15:ratio=3:attack=4:release=95",
    "volume=5dB",
    "alimiter=limit=0.67:level=false:latency=true",
    "afade=t=in:st=0:d=0.025",
    `afade=t=out:st=${(duration - 0.035).toFixed(4)}:d=0.035`,
  ];
  execFileSync(ffmpeg, [
    "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-ss", ((frame + offset) / 60).toFixed(6),
    "-i", path.join(__dirname, "capture", source + ".avi"), "-t", duration.toFixed(6),
    "-map", "0:v:0", "-map", "0:a:0", "-c:v", "libx264", "-preset", "veryfast", "-crf", "16",
    "-threads", "3", "-r", "60", "-pix_fmt", "yuv420p", "-af", sound.join(","), "-c:a", "aac",
    "-b:a", "192k", "-movflags", "+faststart", path.join(media, file + ".mp4"),
  ], {stdio: "inherit", windowsHide: true});
  process.stdout.write(`${file}: ${frame + offset} → ${frame + offset + frames - 1}\n`);
}
