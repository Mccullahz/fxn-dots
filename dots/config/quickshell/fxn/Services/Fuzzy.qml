pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    function score(needle: string, haystack: string): int {
        if (!needle) return 0;
        if (!haystack) return -1;

        const n = needle.toLowerCase();
        const h = haystack.toLowerCase();

        if (h === n) return 1000;
        if (h.startsWith(n)) return 900 - h.length;

        const wordStart = h.indexOf(" " + n);
        if (wordStart >= 0) return 800 - wordStart;

        const sub = h.indexOf(n);
        if (sub >= 0) return 700 - sub;

        let hi = 0, points = 0, run = 0;
        for (let ni = 0; ni < n.length; ni++) {
            const c = n[ni];
            let found = -1;
            while (hi < h.length) {
                if (h[hi] === c) { found = hi; hi++; break; }
                hi++;
            }
            if (found < 0) return -1;

            points += 10;
            if (found === 0 || h[found - 1] === " " || h[found - 1] === "-" || h[found - 1] === "_")
                points += 15;                       // word boundary
            run = (ni > 0 && found === hi - 1) ? run + 1 : 0;
            points += run * 5;                      // consecutive run
            points -= Math.min(found, 20) * 0.2;    // prefer early matches
        }
        return Math.max(0, Math.round(points));
    }

    function scoreFields(needle: string, fields: var): int {
        let best = -1;
        for (let i = 0; i < fields.length; i++) {
            const s = root.score(needle, fields[i] ?? "");
            if (s < 0) continue;
            const weighted = s - i * 30;           // later fields count for less
            if (weighted > best) best = weighted;
        }
        return best;
    }

    function rank(needle: string, items: var, fieldsOf: var, limit: int): var {
        const out = [];
        for (const item of items) {
            const s = root.scoreFields(needle, fieldsOf(item));
            if (s >= 0) out.push({ item, score: s });
        }
        out.sort((a, b) => b.score - a.score);
        const capped = limit > 0 ? out.slice(0, limit) : out;
        return capped.map(e => e.item);
    }
}
