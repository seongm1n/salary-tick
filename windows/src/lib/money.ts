const won = new Intl.NumberFormat("ko-KR", {
  style: "currency",
  currency: "KRW",
  maximumFractionDigits: 0,
});

export function money(v: number, digits = 0): string {
  if (digits === 0) return won.format(v);
  return new Intl.NumberFormat("ko-KR", {
    style: "currency",
    currency: "KRW",
    maximumFractionDigits: digits,
    minimumFractionDigits: digits,
  }).format(v);
}
