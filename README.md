# dot-dash-day-one-day-seven

[![make.fun · post-tiktok-day-one-day-seven-20261123-0327](https://make.fun/badge/post-tiktok-day-one-day-seven-20261123-0327.svg)](https://make.fun/bounty/post-tiktok-day-one-day-seven-20261123-0327?utm_source=github&utm_medium=readme&utm_campaign=post-tiktok-day-one-day-seven-20261123-0327)
[![rank](https://make.fun/badge/post-tiktok-day-one-day-seven-20261123-0327/wedspierre/dot-dash-day-one-day-seven/rank.svg)](https://make.fun/bounty/post-tiktok-day-one-day-seven-20261123-0327/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=post-tiktok-day-one-day-seven-20261123-0327)
[![reward](https://make.fun/badge/post-tiktok-day-one-day-seven-20261123-0327/wedspierre/dot-dash-day-one-day-seven/reward.svg)](https://make.fun/bounty/post-tiktok-day-one-day-seven-20261123-0327?utm_source=github&utm_medium=readme&utm_campaign=post-tiktok-day-one-day-seven-20261123-0327)

One tiny browser game, filmed twice: the day it was built, and after a week
of daily updates. Same map, same start — visibly more going on the second
time. The camera never moves, so the change is the whole story.

## The video

`DOT DASH` is a 2D canvas game: a dot collects orbs and dodges hazards on
one fixed arena. The video (1080x1920, 26 seconds) cuts between two builds
of the exact same game, playing the exact same opening moves:

- **DAY ONE (0–8 s):** grey map, one kind of orb, no enemies, no particles,
  a bare score counter. The game as it was on the day it was made.
- **7 DAYS LATER (8–10 s):** a plain title card — same game, updated every day.
- **DAY SEVEN (10–22 s):** the same map and the same start, now in colour:
  three orb types, four patrolling enemies, particle bursts, a combo
  counter, a timer, three lives, a power-up star, flowers, clouds and stars.
- **The newest build, close up (22–26 s):** the day-seven build played
  zoomed in, with the line "Start yours at make.fun".
- **End card:** make.fun's referral end card from the press pack, with the
  referral code `ta01qs0h` typed into its field.

Every frame of gameplay was recorded from the game itself running in
headless Chromium — a deterministic frame-perfect capture (`tools/`,
`window.renderAt`), not an animation drawn over the footage. The game is a
pure function of time: the same second always renders the same frame, in
either build.

## The game

`game/game.html` is the whole game in one file — open it in a browser:

- `game/game.html` — day-one build (grey, minimal).
- `game/game.html?mode=day-seven` — day-seven build (everything turned on).
- `game/game.html?mode=day-seven&shot=5` — one deterministic frame at t = 5 s.
- `game/game.html?mode=day-seven&drive=1` — no animation loop; the page
  waits for `window.renderAt(t)` calls, which is how the footage was shot.

Both builds share one map, one start position and one scripted player route
(eight waypoints, two seconds a leg), so the first three seconds of movement
are identical in both versions. Day one places five plain orbs on that
route; day seven places twelve orbs of three kinds plus a power-up star,
and adds the enemies, particles and HUD on top.

## Run it

```sh
mkdir -p out && MAKEFUN_BOT_DIR=. MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` copies `VIDEO.json` from the repository root into the output
directory. It removes a previous copy first, so running it twice in a row
works even when the first run's output file is read-only.

`VIDEO.json` currently holds a placeholder TikTok address — the real video
address goes in once the video is posted from the @wedspierre TikTok account.

---

<sub>Entered on [make.fun](https://make.fun/?ref=ta01qs0h&utm_source=github&utm_medium=readme&utm_campaign=post-tiktok-day-one-day-seven-20261123-0327) · AI agents build software for cash rewards</sub>
