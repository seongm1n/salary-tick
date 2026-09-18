// 아래가 트인 240도 타코미터 호. mac/App.swift의 Gauge 포팅.
import { useMemo } from "react";

function polar(cx: number, cy: number, r: number, angleDeg: number) {
  const rad = (angleDeg * Math.PI) / 180;
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
}

/** 진행률 t(0~1)에 대응하는 호 위 각도 */
function angleAt(t: number): number {
  return 150 + 240 * t;
}

function arcPath(cx: number, cy: number, r: number, fromT: number, toT: number): string {
  const start = polar(cx, cy, r, angleAt(fromT));
  const end = polar(cx, cy, r, angleAt(toT));
  const largeArc = (toT - fromT) * 240 > 180 ? 1 : 0;
  return `M ${start.x} ${start.y} A ${r} ${r} 0 ${largeArc} 1 ${end.x} ${end.y}`;
}

export interface GaugeProps {
  size?: number;
  title: string;
  progress: number;
  amount: string;
  caption: string;
  from: string;
  to: string;
  glow?: number;
}

export function Gauge({
  size = 220,
  title,
  progress,
  amount,
  caption,
  from,
  to,
  glow = 0,
}: GaugeProps) {
  const cx = size / 2;
  const cy = size / 2;
  const r = size / 2 - 11;
  const p = Math.min(Math.max(progress, 0), 1);

  const ticks = useMemo(
    () =>
      Array.from({ length: 41 }, (_, i) => {
        const t = i / 40;
        const angle = angleAt(t);
        const isQuarter = t % 0.25 < 0.01;
        const len = isQuarter ? 6 : 3;
        const outer = polar(cx, cy, r - 3, angle);
        const inner = polar(cx, cy, r - 3 - len, angle);
        return { t, outer, inner, lit: t <= p };
      }),
    [cx, cy, r, p],
  );

  const tip = polar(cx, cy, r, angleAt(p));

  return (
    <div style={{ position: "relative", width: size, height: size }}>
      <svg width={size} height={size} style={{ position: "absolute", inset: 0 }}>
        <defs>
          <linearGradient id="gaugeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#91dbbf" />
            <stop offset="50%" stopColor="#6bbcb8" />
            <stop offset="100%" stopColor="#91dbbf" />
          </linearGradient>
        </defs>

        <path
          d={arcPath(cx, cy, r, 0, 1)}
          stroke="rgba(255,255,255,0.07)"
          strokeWidth={3}
          strokeLinecap="round"
          fill="none"
        />

        {ticks.map((tick, i) => (
          <line
            key={i}
            x1={tick.inner.x}
            y1={tick.inner.y}
            x2={tick.outer.x}
            y2={tick.outer.y}
            stroke={tick.lit ? "rgba(145,219,191,0.38)" : "rgba(255,255,255,0.09)"}
            strokeWidth={1}
          />
        ))}

        <path
          d={arcPath(cx, cy, r, 0, Math.max(p, 0.0001))}
          stroke="url(#gaugeGradient)"
          strokeWidth={3}
          strokeLinecap="round"
          fill="none"
          style={{
            filter: `drop-shadow(0 0 ${4 + glow * 3}px rgba(145,219,191,${0.12 + glow * 0.15}))`,
          }}
        />

        {p > 0.002 && (
          <circle
            cx={tip.x}
            cy={tip.y}
            r={2.5}
            fill="white"
            style={{ filter: "drop-shadow(0 0 3px rgba(145,219,191,0.35))" }}
          />
        )}
      </svg>

      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: 10,
        }}
      >
        <span style={{ fontSize: 12, fontWeight: 500, color: "rgba(255,255,255,0.58)" }}>
          {title}
        </span>
        <span
          style={{
            fontSize: 34,
            fontWeight: 600,
            color: "rgba(255,255,255,0.95)",
            fontVariantNumeric: "tabular-nums",
            whiteSpace: "nowrap",
            padding: "0 18px",
            maxWidth: size,
            overflow: "hidden",
            textOverflow: "ellipsis",
          }}
        >
          {amount}
        </span>
        <span
          style={{
            fontSize: 11,
            color: "rgba(255,255,255,0.58)",
            fontVariantNumeric: "tabular-nums",
          }}
        >
          {caption}
        </span>
      </div>

      <div
        style={{
          position: "absolute",
          top: size * 0.35 + size / 2 - 8,
          left: (size - size * 0.8) / 2,
          width: size * 0.8,
          display: "flex",
          justifyContent: "space-between",
          fontSize: 11,
          fontWeight: 600,
          color: "rgba(255,255,255,0.58)",
          fontVariantNumeric: "tabular-nums",
        }}
      >
        <span>{from}</span>
        <span>{to}</span>
      </div>
    </div>
  );
}
