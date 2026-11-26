const fs = require("node:fs");
const path = require("node:path");

const rate = 48000;
const duration = 35;
const count = duration * rate;
const wave = Buffer.alloc(44 + count * 4);
wave.write("RIFF");
wave.writeUInt32LE(wave.length - 8, 4);
wave.write("WAVEfmt ", 8);
wave.writeUInt32LE(16, 16);
wave.writeUInt16LE(1, 20);
wave.writeUInt16LE(2, 22);
wave.writeUInt32LE(rate, 24);
wave.writeUInt32LE(rate * 4, 28);
wave.writeUInt16LE(4, 32);
wave.writeUInt16LE(16, 34);
wave.write("data", 36);
wave.writeUInt32LE(count * 4, 40);

const tau = Math.PI * 2;
const tone = (hz, t) => Math.sin(tau * hz * t);
const envelope = (t, attack, decay) => 0 < t ? Math.min(t / attack, 1) * Math.exp(-t * decay) : 0;
const roots = [36.71, 36.71, 43.65, 34.65];
let seed = 49;
let previousNoise = 0;

for (let i = 0; i < count; i++) {
  const t = i / rate;
  const beat = Math.floor(t * 2);
  const bar = Math.floor(beat / 4);
  const pulse = t - beat / 2;
  const eighth = t % 0.25;
  const root = roots[bar % roots.length];
  const noise = ((seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0) / 0xffffffff) * 2 - 1;
  const highNoise = noise - previousNoise;
  previousNoise = noise;
  const intensity = t < 18 ? 0.72 : 1;
  const closing = t >= 28;
  const kick = closing ? 0 : envelope(pulse, 0.004, 12) *
    Math.sin(tau * (47 * pulse + 2.2 * (1 - Math.exp(-31 * pulse)))) * 0.42 * intensity;
  const bass = closing ? 0 : envelope(eighth, 0.013, 9) *
    (tone(root * 2, t) * 0.14 + tone(root * 4, t) * 0.034 + tone(root * 6, t) * 0.018);
  const hat = closing || t < 4 ? 0 : highNoise * envelope(eighth, 0.004, 43) * (beat % 2 ? 0.04 : 0.024);
  const snare = !closing && t >= 4 && beat % 2 ?
    (noise * 0.66 + tone(165, pulse) * 0.34) * envelope(pulse, 0.003, 26) * 0.092 : 0;
  const swell = Math.sin(Math.PI * Math.min(t / 4, 1) * 0.5);
  const pad = (tone(73.42, t) + 0.5 * tone(110, t) + 0.32 * tone(146.8, t)) *
    (closing ? Math.exp(-(t - 28) * 0.7) * 0.06 : swell * 0.027);
  const chord = [146.83, 174.61, 220, 261.63];
  const note = chord[Math.floor(t * 4) % chord.length] * (bar % 2 ? 1 : 0.5);
  const arp = t >= 8 && !closing ? tone(note, t) * envelope(eighth, 0.018, 13) * 0.052 * intensity : 0;
  let impact = 0;
  for (const time of [0, 4, 18, 22, 28]) {
    const age = t - time;
    if (age >= 0 && age < 1.8) {
      impact += (tone(47, age) * 0.8 + tone(93, age) * 0.25 + noise * Math.exp(-age * 12) * 0.27) *
        envelope(age, 0.008, time === 28 ? 2.4 : 6) * (time === 28 ? 0.35 : 0.24);
    }
  }
  const last = t - 31.5;
  const signal = last > 0 ? (tone(293.66, last) + tone(440.4, last) * 0.38) * envelope(last, 0.06, 1.6) * 0.08 : 0;
  const fade = Math.min((duration - t) / 0.55, 1);
  const center = kick + bass + snare + pad + impact + signal;
  const mix = (x) => Math.round(Math.tanh(x * 1.2) * 30000 * fade);
  wave.writeInt16LE(mix(center + hat + arp), 44 + i * 4);
  wave.writeInt16LE(mix(center + hat * 0.72 + arp * 0.66 + tone(147.15, t) * pad * 0.12), 46 + i * 4);
}

const output = path.resolve(__dirname, "public/media/score.wav");
fs.mkdirSync(path.dirname(output), {recursive: true});
fs.writeFileSync(output, wave);
