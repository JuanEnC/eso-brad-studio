import React from "react";
import {
  AbsoluteFill, Audio, Composition, Easing, OffthreadVideo, Sequence,
  interpolate, registerRoot, staticFile, useCurrentFrame,
} from "remotion";

const ink = "#070d17";
const mint = "#80f4e2";
const coral = "#fa879e";
const white = "#eef7fe";
const display = "Bahnschrift, 'Arial Narrow', Arial, sans-serif";
const mono = "'Consolas', monospace";
const ease = Easing.out(Easing.cubic);
const tween = (f, frames, values) => interpolate(f, frames, values, {
  extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease,
});

function Shot({file, duration, push = 1, origin = "center", flash, tint = mint}) {
  const f = useCurrentFrame();
  const scale = tween(f, [0, duration - 1], [1, push]);
  const opacity = flash ? interpolate(f, [0, 2, 9, 18], [0.24, 0.18, 0.035, 0], {
    extrapolateRight: "clamp",
  }) : 0;
  return <AbsoluteFill style={{background: ink, overflow: "hidden"}}>
    <div style={{
      position: "absolute", left: 96, top: 0, width: 1728, height: 1080,
      transform: `scale(${scale})`, transformOrigin: origin,
    }}>
      <OffthreadVideo src={staticFile(`media/${file}.mp4`)} volume={0.9}
        style={{width: "100%", height: "100%", objectFit: "contain"}} />
    </div>
    <AbsoluteFill style={{
      background: "linear-gradient(90deg,#070d17 0%,transparent 9%,transparent 91%,#070d17 100%)",
    }} />
    <AbsoluteFill style={{background: tint, opacity, mixBlendMode: "screen"}} />
    <div style={{position: "absolute", width: 2, top: 160, bottom: 160, left: 46, background: "#80f4e222"}} />
    <div style={{position: "absolute", width: 2, top: 160, bottom: 160, right: 46, background: "#fa879e22"}} />
  </AbsoluteFill>;
}

function Caption({lines, duration, tint = mint, right = false}) {
  const f = useCurrentFrame();
  const alpha = Math.min(tween(f, [0, 10], [0, 1]), tween(f, [duration - 14, duration - 1], [1, 0]));
  const shift = tween(f, [0, 19], [30, 0]);
  return <div style={{
    position: "absolute", bottom: 145, left: right ? undefined : 168, right: right ? 168 : undefined,
    color: white, opacity: alpha, textAlign: right ? "right" : "left", fontFamily: display,
    textShadow: "0 3px 18px #060914, 0 0 30px #060914", transform: `translateY(${shift}px)`,
  }}>
    <div style={{
      width: tween(f, [0, 18], [10, 125]), height: 3, background: tint,
      boxShadow: `0 0 18px ${tint}`, margin: right ? "0 0 17px auto" : "0 0 17px",
    }} />
    {lines.map((line, i) => <div key={line} style={{
      fontSize: lines.length > 1 ? 65 : 58, fontWeight: 700, letterSpacing: 4, lineHeight: 0.94,
      color: i === 1 ? tint : white,
      clipPath: `inset(-10px ${tween(f, [i * 5, i * 5 + 15], [100, 0])}% -10px -2px)`,
    }}>{line}</div>)}
  </div>;
}

function Pulse() {
  const f = useCurrentFrame();
  const width = tween(f, [0, 23], [7, 205]);
  return <AbsoluteFill style={{opacity: tween(f, [1, 25], [0.72, 0]), mixBlendMode: "screen"}}>
    <div style={{
      position: "absolute", left: "50%", top: "50%", width: `${width}%`, aspectRatio: "1",
      border: "4px solid #83ffea", borderRadius: "50%", transform: "translate(-50%,-50%)",
      boxShadow: "inset 0 0 36px #52778e, 0 0 50px #fb809b",
    }} />
  </AbsoluteFill>;
}

function Title() {
  const f = useCurrentFrame();
  const rise = tween(f, [18, 61], [36, 0]);
  const bloom = tween(f, [0, 56], [0.18, 0.73]);
  const cut = tween(f, [12, 60], [100, 0]);
  const cta = tween(f, [143, 177], [0, 1]);
  return <AbsoluteFill style={{
    background: "radial-gradient(ellipse at 50% 43%, #101c2c 0%, #0a101d 38%, #070910 73%)",
    color: white, fontFamily: display, overflow: "hidden",
  }}>
    <AbsoluteFill style={{
      backgroundImage: "linear-gradient(#739ebb10 1px,transparent 1px),linear-gradient(90deg,#739ebb10 1px,transparent 1px)",
      backgroundSize: "72px 72px", opacity: 0.45,
      maskImage: "radial-gradient(ellipse,#000 3%,transparent 69%)",
    }} />
    <svg viewBox="0 0 1920 1080" style={{position: "absolute", inset: 0, opacity: bloom}}>
      <defs><linearGradient id="rim"><stop stopColor={mint}/><stop offset=".49" stopColor="#2b516c"/><stop offset="1" stopColor={coral}/></linearGradient></defs>
      <g transform={`translate(960 503) rotate(${tween(f, [0, 360], [-42, 5])})`} fill="none">
        <circle r="319" stroke="#253649" strokeWidth="1"/>
        <circle r="348" stroke="url(#rim)" strokeWidth="1.8" strokeDasharray="160 79 42 120 98 110"/>
        <circle r="371" stroke="#426878" strokeWidth="1" strokeDasharray="1 14"/>
        <path d="M-395 0h46m698 0h46M0-395v30m0 730v30" stroke="url(#rim)" strokeWidth="1.8"/>
      </g>
    </svg>
    <div style={{
      position: "absolute", inset: "371px 0 auto", textAlign: "center",
      fontSize: 173, fontWeight: 800, letterSpacing: 36, textIndent: 36, transform: `translateY(${rise}px)`,
      clipPath: `inset(0 ${cut / 2}% 0 ${cut / 2}%)`,
      textShadow: "-5px 0 25px #65f7e34e, 5px 0 28px #ff7d9a42, 0 5px 20px #090e1b",
    }}>ABYSS</div>
    <div style={{
      position: "absolute", inset: "629px 0 auto", textAlign: "center", opacity: cta,
      transform: `translateY(${(1 - cta) * 9}px)`, color: mint, fontFamily: mono,
      fontSize: 26, fontWeight: 600, letterSpacing: 8, textIndent: 8,
    }}>JUEGA AHORA</div>
    <div style={{position: "absolute", top: 686, left: 916, height: 1, width: 88,
      opacity: cta * 0.65, background: `linear-gradient(90deg,${mint},${coral})`}} />
  </AbsoluteFill>;
}

function Trailer() {
  return <AbsoluteFill style={{background: ink}}>
    <Audio src={staticFile("media/score.wav")} volume={0.6} />
    <Sequence from={0} durationInFrames={90}><Shot file="hook" duration={90} push={1.12} origin="31% 53%" flash /></Sequence>
    <Sequence from={90} durationInFrames={150}><Shot file="dash" duration={150} push={1.055} origin="31% 56%" flash /></Sequence>
    <Sequence from={240} durationInFrames={210}>
      <Shot file="bank" duration={210} push={1.085} origin="43% 5%" flash tint={coral} />
      <Caption duration={198} lines={["CALCULA", "CADA REBOTE"]} />
    </Sequence>
    <Sequence from={450} durationInFrames={180}>
      <Shot file="opening" duration={180} push={1.035} origin="32% 47%" />
      <Caption duration={158} lines={["ESQUIVA."]} right />
    </Sequence>
    <Sequence from={630} durationInFrames={240}>
      <Shot file="fracture" duration={240} push={1.055} origin="36% 55%" />
      <Caption duration={119} lines={["DESVÍA."]} right />
      <Sequence from={119} durationInFrames={121}><Caption duration={119} lines={["FRACTURA."]} tint={coral} right /></Sequence>
    </Sequence>
    <Sequence from={870} durationInFrames={210}><Shot file="laser" duration={210} push={1.035} /></Sequence>
    <Sequence from={1080} durationInFrames={210}>
      <Shot file="descent" duration={210} flash tint={coral} />
      <Pulse />
      <Caption duration={165} lines={["DESCIENDE."]} tint={coral} />
    </Sequence>
    <Sequence from={1290} durationInFrames={180}>
      <Shot file="guardian" duration={180} flash tint={coral} />
      <Caption duration={142} lines={["EL GUARDIÁN"]} tint={coral} right />
    </Sequence>
    <Sequence from={1470} durationInFrames={210}><Shot file="fury" duration={210} flash tint={coral} /></Sequence>
    <Sequence from={1680} durationInFrames={420}><Title /></Sequence>
  </AbsoluteFill>;
}

registerRoot(() => <Composition id="AbyssTrailer" component={Trailer} durationInFrames={2100} fps={60} width={1920} height={1080} />);
