/**
 * Diagnose: hvilken retning bommer prisspennet? (learning-1, 2026-10-19). Ren kode, read-only, ingen API.
 * Bygger radene med prods toAwardRow og spennet med prods priceSpan (samme som scripts/eval-pris-spenn.ts),
 * og teller vinnerpriser under/inne/over spennet + forholdet vinnerpris/spennets median.
 * Legg i crm/scripts/ og kjør: node --import tsx scripts/diag-pris-skjevhet.ts <eksport.jsonl.txt>
 */
import { readFileSync } from 'node:fs'
import { toAwardRow } from '../src/lib/agents/tools/get_awards'
import { isFinalPrice, nokOf, priceSpan, tenderKeyOf } from '../src/lib/pris/spenn'
const input = readFileSync(process.argv[2], 'utf8').split('\n').filter((l) => l.startsWith('{')).map((l) => JSON.parse(l))
const roots = new Map(input.filter((l: any) => l.kind === 'root').map((l: any) => [l.id, l]))
const rows = input.filter((l: any) => l.kind === 'award').map((d: any) => toAwardRow(d, roots as never))
let lo = 0, hi = 0, inn = 0; const ratios: number[] = []; const sameBuyer: number[] = []
for (const r of rows.filter(isFinalPrice)) {
  const k = tenderKeyOf(r)
  const s = priceSpan(rows, { cpvCodes: r.cpvCodes, estimateNok: null, asOf: r.awardedAt, excludeAwardIds: [r.awardId], excludeTenderIds: k != null ? [k] : [] })
  if (s.basis !== 'FACT') continue
  const v = nokOf(r)!
  if (v < s.low) lo++; else if (v > s.high) hi++; else inn++
  ratios.push(v / s.mid)
}
ratios.sort((a, b) => a - b)
const q = (p: number) => ratios[Math.floor((ratios.length - 1) * p)]
console.log(`under spennet ${lo}, inne ${inn}, over ${hi}; vinnerpris/median-forhold p10 ${q(0.1).toFixed(2)} p50 ${q(0.5).toFixed(2)} p90 ${q(0.9).toFixed(2)}`)
const dates = rows.filter(isFinalPrice).map((r) => r.awardedAt!.slice(0, 7)); const c: Record<string, number> = {}; for (const d of dates) c[d] = (c[d] ?? 0) + 1
console.log('endelige vinnerpriser per måned:', JSON.stringify(c))
