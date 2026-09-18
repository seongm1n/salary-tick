import { describe, expect, test } from "vitest";
import { earned, perSecond, periodProgress, progress, workdays } from "./pay";

// mac/App.swift selfTest() 이식. 같은 숫자로 검증.

const a = 50_000_000;
const wd = 250;
const s = 9.0;
const e = 18.0;

test("초당 수입", () => {
  expect(perSecond(a, s, e, wd)).toBeCloseTo(a / (250 * 9 * 3600), 9);
});

test("출근 전엔 0원", () => {
  expect(earned(a, s, e, wd, 8.0)).toBe(0);
});

test("퇴근 시각 = 하루치", () => {
  const full = a / wd;
  expect(earned(a, s, e, wd, 18.0)).toBeCloseTo(full, 6);
});

test("퇴근 후 고정", () => {
  const full = a / wd;
  expect(earned(a, s, e, wd, 23.0)).toBeCloseTo(full, 6);
});

test("절반", () => {
  const full = a / wd;
  expect(earned(a, s, e, wd, 13.5)).toBeCloseTo(full / 2, 6);
});

test("진행률 하한/상한", () => {
  expect(progress(s, e, 8.0)).toBe(0);
  expect(progress(s, e, 18.0)).toBe(1);
});

test("역전 구간 (야간 근무)은 0원", () => {
  expect(perSecond(a, 22, 6, wd)).toBe(0);
});

test("연봉 0", () => {
  expect(perSecond(0, s, e, wd)).toBe(0);
});

describe("기간 집계 (2026-09-14 월요일 기준)", () => {
  const day = new Date(2026, 8, 14, 13, 30);

  test("9월 근무일: 22일 중 9일 지남", () => {
    const m = workdays("month", day);
    expect(m).toEqual({ done: 9, total: 22 });
  });

  test("2026년 평일: 261일", () => {
    const y = workdays("year", day);
    expect(y.total).toBe(261);
  });

  test("하루 절반 지났으면 9.5/22", () => {
    expect(periodProgress("month", day, 0.5)).toBeCloseTo(9.5 / 22, 9);
  });

  test("주말엔 오늘 몫을 안 더한다", () => {
    const sat = new Date(2026, 8, 12, 13);
    expect(periodProgress("month", sat, 0.5)).toBe(9 / 22);
  });
});
