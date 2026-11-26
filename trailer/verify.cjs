const {execFileSync, spawnSync} = require("node:child_process");
const path = require("node:path");
const ffmpeg = require("ffmpeg-static");
const ffprobe = require("ffprobe-static").path;

const file = path.join(__dirname, "out", "abyss-trailer.mp4");
const media = path.join(__dirname, "public", "media");
const inspect = JSON.parse(execFileSync(ffprobe, [
  "-v", "error", "-show_streams", "-show_format", "-of", "json", file,
], {encoding: "utf8", windowsHide: true}));
const picture = inspect.streams.find((stream) => stream.codec_type === "video");
const sound = inspect.streams.find((stream) => stream.codec_type === "audio");
if (
  !picture || picture.codec_name !== "h264" || picture.width !== 1920 || picture.height !== 1080 ||
  picture.avg_frame_rate !== "60/1" || Number(picture.nb_frames) !== 2100 ||
  !sound || sound.codec_name !== "aac" || Number(sound.channels) !== 2 ||
  Math.abs(Number(inspect.format.duration) - 35) > 0.04 ||
  Math.abs(Number(picture.duration) - Number(sound.duration)) > 0.04
) throw new Error("El archivo no cumple la duración, imagen o audio esperados.");
console.log(`H.264 ${picture.width}×${picture.height}, ${picture.nb_frames} fotogramas, AAC estéreo, ${inspect.format.duration} s.`);

const audit = spawnSync(ffmpeg, [
  "-nostdin", "-hide_banner", "-i", file,
  "-vf", "blackdetect=d=0:pic_th=0.99999:pix_th=0.008",
  "-af", "volumedetect", "-f", "null", "-",
], {encoding: "utf8", windowsHide: true, stdio: ["ignore", "pipe", "pipe"]});
if (audit.status !== 0 || /black_start:/.test(audit.stderr)) {
  throw new Error(audit.stderr);
}
const peak = /max_volume: ([\d.\-]+) dB/.exec(audit.stderr);
console.log(`Decodificación completa sin cuadros negros. Pico de audio: ${peak?.[1]} dBFS.`);

function decode(source, start, duration) {
  const pcm = execFileSync(ffmpeg, [
    "-nostdin", "-v", "error", "-i", source, "-ss", String(start), "-t", String(duration),
    "-vn", "-af", "highpass=f=870", "-ac", "1", "-ar", "8000", "-f", "s16le", "pipe:1",
  ], {windowsHide: true});
  return new Int16Array(pcm.buffer, pcm.byteOffset, pcm.length / 2);
}

for (const [name, start, offset] of [["hook", 0, 0.24], ["bank", 4, 0.74], ["guardian", 21.5, 1.18]]) {
  const original = decode(path.join(media, name + ".mp4"), offset, 0.86);
  const mixed = decode(file, start + offset - 0.08, 1.04);
  let best = {lag: 0, score: 0};
  for (let shift = 0; shift <= 1280; shift++) {
    let dot = 0;
    let left = 0;
    let right = 0;
    for (let i = 0; i < original.length && i + shift < mixed.length; i++) {
      const a = original[i];
      const b = mixed[i + shift];
      dot += a * b;
      left += a * a;
      right += b * b;
    }
    const score = dot / Math.sqrt(left * right);
    if (score > best.score) best = {lag: (shift - 640) / 8, score};
  }
  if (best.score < 0.12 || Math.abs(best.lag) > 17) {
    throw new Error(`El efecto de ${name} no coincide con su punto de corte: ${JSON.stringify(best)}`);
  }
  console.log(`${name}: efecto de Godot alineado (${best.lag.toFixed(2)} ms).`);
}
