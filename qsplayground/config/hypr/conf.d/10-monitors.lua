-- ─── Monitors ────────────────────────────────────────────────
-- hl.monitor({ output, mode = "RES@HZ", position, scale[, transform] })
--
-- Verified against `hyprctl monitors` on 2026-09-19. The catch-all
-- (output = "") stays LAST so unknown outputs (and the QA sandbox's
-- nested window) still light up — it matches anything without its own
-- entry, which is exactly how HDMI-A-2 ended up unrotated and parked at
-- x=8315 before this.
--
-- Keep this file to plain hl.monitor / hl.workspace_rule calls with
-- literal values: fxn-greeter-sync copies it whole for the login
-- screen's Hyprland, where nothing else from this config exists.

-- HDMI-A-2 — MSI G27C4, rotated 90° into portrait.
-- transform 1 = 90° CCW. Once rotated the output occupies 1080x1920,
-- NOT 1920x1080, so every position below is computed with that size.
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@60.0", position = "0x0", scale = 1.0, transform = 1 })

-- DP-3 — ASUS VG27A, landscape, sitting to the right of the portrait
-- panel. x = 1080 (the rotated width of HDMI-A-2), y = 240 to centre
-- it vertically: (1920 - 1440) / 2.
hl.monitor({ output = "DP-3", mode = "2560x1440@59.951", position = "1080x240", scale = 1.0 })

-- Not present on this machine as of 2026-09-19. Left here, commented,
-- so the positions are not lost if the hardware comes back. Uncomment
-- and recompute positions against the layout above before using.
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "4693x2381", scale = 1.0 })
-- hl.monitor({ output = "DP-4",  mode = "preferred", position = "3667x1186", scale = 1.0 })

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- ─── Workspace → monitor assignment ─────────────────────────
-- See https://wiki.hypr.land/configuring/core/rules/workspace-rules/
-- Left blank by default so workspaces follow focus. Uncomment and
-- adapt if you want workspaces pinned to particular outputs.

-- hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-2", default = true })
-- hl.workspace_rule({ workspace = "2", monitor = "DP-3", default = true })
