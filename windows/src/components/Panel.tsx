import { useState } from "react";
import { exit } from "@tauri-apps/plugin-process";
import { useAutostart } from "../hooks/useAutostart";
import { useClock } from "../hooks/useClock";
import { useConfigStore } from "../hooks/useConfigStore";
import { Gauge } from "./Gauge";
import { money } from "../lib/money";
import {
  type Scope,
  configEarned,
  configProgress,
  hourOfDay,
  scopeLabel,
  total,
  workdays,
} from "../lib/pay";

const SCOPES: Scope[] = ["day", "month", "year"];

function hm(hours: number): string {
  const m = Math.round(hours * 60);
  return m >= 60 ? `${Math.floor(m / 60)}시간 ${m % 60}분` : `${m}분`;
}

function clock24(h: number): string {
  const hh = Math.floor(h);
  const mm = Math.round((h - hh) * 60);
  return `${String(hh).padStart(2, "0")}:${String(mm).padStart(2, "0")}`;
}

function hourToTimeInput(h: number): string {
  const hh = Math.floor(h);
  const mm = Math.round((h - hh) * 60);
  return `${String(hh).padStart(2, "0")}:${String(mm).padStart(2, "0")}`;
}

function timeInputToHour(v: string): number {
  const [hh, mm] = v.split(":").map(Number);
  return hh + mm / 60;
}

export function Panel() {
  const now = useClock();
  const [cfg, setCfg] = useConfigStore();
  const [showSettings, setShowSettings] = useState(false);
  const [autostart, setAutostart] = useAutostart();

  const nowHour = hourOfDay(now);
  const earned = configEarned(cfg, now);
  const progress = configProgress(cfg, now);
  const perSecond = cfg.workdays > 0 && cfg.end > cfg.start && cfg.annual > 0
    ? cfg.annual / (cfg.workdays * (cfg.end - cfg.start) * 3600)
    : 0;

  const caption = (() => {
    const pct = `${Math.round(progress * 100)}%`;
    if (cfg.scope !== "day") {
      const w = workdays(cfg.scope, now);
      return `${pct}  ·  근무일 ${Math.round(w.total - w.done)}일 남음`;
    }
    if (nowHour < cfg.start) return `출근까지 ${hm(cfg.start - nowHour)}`;
    if (nowHour >= cfg.end) return "오늘 근무 완료";
    return `${pct}  ·  ${hm(cfg.end - nowHour)} 남음`;
  })();

  const bounds = (() => {
    switch (cfg.scope) {
      case "day":
        return [clock24(cfg.start), clock24(cfg.end)];
      case "month": {
        const n = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
        return ["1일", `${n}일`];
      }
      case "year":
        return ["1월", "12월"];
    }
  })();

  return (
    <div className="panel" data-tauri-drag-region>
      <div className="panel-header" data-tauri-drag-region>
        <span className="panel-title">SalaryTick</span>
        <span className="panel-subtitle">수입 현황</span>
      </div>

      <div className="scope-picker">
        {SCOPES.map((s) => (
          <button
            key={s}
            className={`scope-btn ${s === cfg.scope ? "active" : ""}`}
            onClick={() => setCfg((c) => ({ ...c, scope: s }))}
          >
            {scopeLabel[s]}
          </button>
        ))}
      </div>

      <div className="gauge-wrap">
        <Gauge
          size={220}
          title={`${scopeLabel[cfg.scope]} 번 돈`}
          progress={progress}
          amount={money(earned)}
          caption={caption}
          from={bounds[0]}
          to={bounds[1]}
        />
      </div>

      <div className="chips">
        <div className="chip">
          <span className="chip-label">초당 수입</span>
          <span className="chip-value">{money(perSecond, 1)}</span>
        </div>
        <div className="chip-divider" />
        <div className="chip">
          <span className="chip-label">{scopeLabel[cfg.scope]} 총액</span>
          <span className="chip-value">{money(total(cfg))}</span>
        </div>
      </div>

      <div className="hr" />

      <div className="settings-row">
        <button className="settings-toggle" onClick={() => setShowSettings((v) => !v)}>
          <span>설정</span>
          <span className="settings-hint">세전 기준</span>
        </button>

        {showSettings && (
          <div className="settings-body">
            <label className="field">
              <span>연봉 (세전)</span>
              <input
                type="number"
                value={cfg.annual}
                onChange={(e) => setCfg((c) => ({ ...c, annual: Number(e.target.value) }))}
              />
            </label>
            <label className="field">
              <span>출근</span>
              <input
                type="time"
                value={hourToTimeInput(cfg.start)}
                onChange={(e) => setCfg((c) => ({ ...c, start: timeInputToHour(e.target.value) }))}
              />
            </label>
            <label className="field">
              <span>퇴근</span>
              <input
                type="time"
                value={hourToTimeInput(cfg.end)}
                onChange={(e) => setCfg((c) => ({ ...c, end: timeInputToHour(e.target.value) }))}
              />
            </label>
            <label className="field">
              <span>연간 근무일</span>
              <input
                type="number"
                value={cfg.workdays}
                onChange={(e) => setCfg((c) => ({ ...c, workdays: Number(e.target.value) }))}
              />
            </label>
            <label className="field">
              <span>로그인 시 자동 실행</span>
              <input
                type="checkbox"
                checked={autostart}
                onChange={(e) => setAutostart(e.target.checked)}
              />
            </label>
          </div>
        )}

        <button className="quit-btn" onClick={() => exit(0)}>
          종료
        </button>
      </div>
    </div>
  );
}
