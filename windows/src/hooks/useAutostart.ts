import { useEffect, useState } from "react";
import { disable, enable, isEnabled } from "@tauri-apps/plugin-autostart";

/** 로그인 시 자동 실행 토글. mac의 SMAppService 대응. */
export function useAutostart(): [boolean, (on: boolean) => void] {
  const [enabled, setEnabled] = useState(false);

  useEffect(() => {
    isEnabled().then(setEnabled).catch(() => {});
  }, []);

  function toggle(on: boolean) {
    setEnabled(on);
    void (on ? enable() : disable()).catch(() => setEnabled(!on));
  }

  return [enabled, toggle];
}
