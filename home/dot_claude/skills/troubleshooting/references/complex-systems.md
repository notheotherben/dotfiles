# How complex systems fail — working notes for an investigator

These are notes on Richard I. Cook's essay *How Complex Systems Fail* (Copyright © 1998, 1999,
2000 by R.I. Cook, MD, for CtL), read specifically through the lens of "what should I do
differently while troubleshooting". The original is two pages and worth reading in full at
<https://how.complexsystems.fail/> — this file paraphrases its ideas and reorganises them around
investigative practice rather than reproducing it. Point numbers below refer to the original's
numbering so you can cross-reference.

## The baseline is already degraded (points 4, 5, 6)

Any system large enough to be interesting is carrying latent faults at all times, and is running
in a partially-broken state right now. Normal operation is not a state of correctness; it is a
state where the compensations are still winning.

**What this changes.** Finding *a* fault is very weak evidence that you have found *the* fault —
in a system full of latent defects, the first plausible mechanism you turn up is more likely to
be ambient breakage than the cause of today's symptom. Before acting on a discovery, ask whether
it actually produces the observed behaviour, and design a test that distinguishes "this is the
cause" from "this is one of the many things quietly wrong here".

It also means "I found something broken" is not a stopping condition, and a clean-looking
component is not exonerated — it may simply be one whose degradation you cannot currently see.

## Failure is a conjunction, not a link in a chain (points 3, 7, 15)

Serious failures require several contributing conditions to line up. Single-point failures are
usually absorbed by defences; what gets through is a combination. Consequently the notion of
*the* root cause is partly a story people construct after the fact, chosen from a set of
necessary conditions none of which is individually sufficient.

**What this changes.** Bisection is still the right search strategy — it finds where behaviour
diverges — but do not assume the divergence point is a lone villain. When you find it, ask what
else had to be true for it to matter: what defence was absent, what fallback was silent, what
config made this path reachable. Each of those is a separate lever for prevention, and often a
better one than the proximate trigger.

Be wary of stopping at the first *sufficient* explanation. It will feel like an answer, and it
will usually be one of several conditions.

## Defences convert loud failures into quiet ones (points 2, 3)

Systems are heavily defended: retries, fallbacks, defaults, caches, redundancy. These are what
keep the system alive, and they are also what make debugging hard, because a defence that
half-works turns an obvious upstream failure into a subtle downstream wrongness.

**What this changes.** This is the mechanism behind soft failures. When checking a landmark, ask
not only "did it succeed?" but "did it succeed *on the intended path*, or did something catch a
failure and substitute a default?" A silently-applied default is the single most common way a
divergence hides from a bisection. Log lines like "falling back to…" deserve much more attention
than their severity level suggests.

## Change creates novel failure modes (point 14)

New capability and new configurations introduce failure modes with no operational history. They
are also the modes least likely to be covered by existing monitoring, runbooks or intuition.

**What this changes.** Two things. A recent change is a legitimately strong prior, so search it
early. But a change can also *expose* a pre-existing fault rather than introduce one — the
trigger and the cause are different things and both need naming. And expect your instrumentation
to be worst exactly where the change is newest, so plan to build probes there rather than
assuming absence of evidence is evidence of health.

## Hindsight will distort your reading of the evidence (points 8, 10)

Once you know the outcome, the path to it looks obvious and prior decisions look negligent. Cook
is writing about accident review, but the same bias operates on you mid-investigation and on
whoever built the system.

**What this changes.** Every action anyone took — including the ones that look foolish now — was
a gamble made under uncertainty with the information available then. When you catch yourself
thinking "obviously they should have checked X", that is hindsight, and it is usually a sign you
have already assumed the conclusion. Keep it out of your reasoning about *what is true*, and out
of your write-up, where it poisons the useful parts.

The same discipline applies to your own earlier steps in the investigation. Retract them when
they are wrong; do not narrate them as though the answer was visible all along.

## The operators are part of the system (points 9, 11, 12, 13, 17)

Humans in the loop are not external to the system — they are its adaptive element, continuously
compensating, and much of the system's apparent reliability is those compensations. They also
hold the operational history that no telemetry captured.

**What this changes.** Ask them. What have they been working around? What has felt strange
lately? What did they change, even if "it can't be related"? These reports are not noise, they
are observations from the only sensors that cover certain parts of the system, and they are
frequently the cheapest way to shift your priors about where to search.

It also means *you* are now part of the system. Every probe, restart and hand-edit you perform
becomes part of its state and its history. Act accordingly.

## Safety and correctness are properties of the whole (points 1, 16, 18)

Hazard is intrinsic to systems that do useful work, and reliability is emergent — it is not
located in any component, so it cannot be fixed by hardening one.

**What this changes.** It sets the standard for your prevention plan. "Fix the component that
broke" is rarely enough, because the same conjunction will recur through a different component.
Better follow-ups target the system: make the failure detectable earlier (the landmark that would
have localised it in minutes), make the silent fallback loud, assert the invariant at startup,
remove the manual step. Also worth noting: experience with failure is what maintains competence,
so an investigation that ends without anyone learning the shape of the failure has left value on
the table.
