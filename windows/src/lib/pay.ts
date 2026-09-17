// 계산 (순수 함수). mac/App.swift의 Pay enum 포팅. 검증: pay.test.ts

export type Scope = "day" | "month" | "year";

export const scopeLabel: Record<Scope, string> = {
  day: "오늘",
  month: "이번 달",
  year: "올해",
};

/** 초당 수입. 하루근무초 = (퇴근-출근)*3600 */
export function perSecond(annual: number, start: number, end: number, workdays: number): number {
  const daySeconds = (end - start) * 3600;
  if (daySeconds <= 0 || workdays <= 0 || annual <= 0) return 0;
  return annual / (workdays * daySeconds);
}

/** 출근~현재 경과초 (출근 전 0, 퇴근 후 하루치로 고정) */
export function elapsed(now: number, start: number, end: number): number {
  return Math.min(Math.max(now - start, 0), Math.max(end - start, 0));
}

export function earned(
  annual: number,
  start: number,
  end: number,
  workdays: number,
  nowHour: number,
): number {
  return (
    perSecond(annual, start, end, workdays) *
    elapsed(nowHour * 3600, start * 3600, end * 3600)
  );
}

export function progress(start: number, end: number, nowHour: number): number {
  const span = (end - start) * 3600;
  if (span <= 0) return 0;
  return elapsed(nowHour * 3600, start * 3600, end * 3600) / span;
}

function startOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function isWeekend(d: Date): boolean {
  const day = d.getDay();
  return day === 0 || day === 6;
}

function monthInterval(now: Date): { start: Date; end: Date } {
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return { start, end };
}

function yearInterval(now: Date): { start: Date; end: Date } {
  const start = new Date(now.getFullYear(), 0, 1);
  const end = new Date(now.getFullYear() + 1, 0, 1);
  return { start, end };
}

/** 이번 달/올해의 근무일 수. done은 오늘 이전까지(오늘 제외). */
export function workdays(scope: Scope, now: Date): { done: number; total: number } {
  const { start, end } = scope === "month" ? monthInterval(now) : yearInterval(now);
  const today = startOfDay(now);
  let done = 0;
  let total = 0;
  const d = new Date(start);
  while (d < end) {
    if (!isWeekend(d)) {
      total += 1;
      if (d < today) done += 1;
    }
    d.setDate(d.getDate() + 1);
  }
  return { done, total };
}

/** 기간 진행률 = (지난 근무일 + 오늘 몫) / 전체 근무일 */
export function periodProgress(scope: Scope, now: Date, dayProgress: number): number {
  const w = workdays(scope, now);
  if (w.total <= 0) return 0;
  const todayShare = isWeekend(now) ? 0 : dayProgress;
  return Math.min((w.done + todayShare) / w.total, 1);
}

/** 자정 기준 경과 시간(시 단위). 9시 30분 -> 9.5 */
export function hourOfDay(d: Date): number {
  return d.getHours() + d.getMinutes() / 60 + d.getSeconds() / 3600;
}

export interface Config {
  annual: number;
  start: number;
  end: number;
  workdays: number;
  scope: Scope;
}

/** 선택한 기간을 꽉 채웠을 때의 금액 */
export function total(cfg: Config): number {
  switch (cfg.scope) {
    case "day":
      return perSecond(cfg.annual, cfg.start, cfg.end, cfg.workdays) * (cfg.end - cfg.start) * 3600;
    case "month":
      return cfg.annual / 12;
    case "year":
      return cfg.annual;
  }
}

export function configProgress(cfg: Config, now: Date): number {
  const day = progress(cfg.start, cfg.end, hourOfDay(now));
  return cfg.scope === "day" ? day : periodProgress(cfg.scope, now, day);
}

export function configEarned(cfg: Config, now: Date): number {
  return total(cfg) * configProgress(cfg, now);
}
