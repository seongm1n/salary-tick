import { useEffect, useRef, useState } from "react";
import { Store } from "@tauri-apps/plugin-store";
import type { Config } from "../lib/pay";

const STORE_FILE = "config.json";
const KEY = "config";

export const defaultConfig: Config = {
  annual: 50_000_000,
  start: 9,
  end: 18,
  workdays: 250,
  scope: "day",
};

/** 설정값 영속화. mac의 @AppStorage 대응 — 창 닫아도 유지. */
export function useConfigStore(): [Config, (updater: (c: Config) => Config) => void] {
  const [cfg, setCfgState] = useState<Config>(defaultConfig);
  const storeRef = useRef<Store | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const store = await Store.load(STORE_FILE);
      if (cancelled) return;
      storeRef.current = store;
      const saved = await store.get<Config>(KEY);
      if (saved) setCfgState(saved);
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  function setCfg(updater: (c: Config) => Config) {
    setCfgState((prev) => {
      const next = updater(prev);
      void storeRef.current?.set(KEY, next);
      return next;
    });
  }

  return [cfg, setCfg];
}
