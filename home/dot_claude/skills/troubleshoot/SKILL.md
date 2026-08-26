---
name: troubleshoot
description: Systematic root-cause troubleshooting — frame the failing flow, bisect it against observable landmarks, and test each hypothesis with a designed experiment instead of guessing. Use this whenever something is broken, failing, erroring, crashing, hanging, flaky, slow, or "used to work and now doesn't" — build and CI failures, runtime errors, integration and dependency problems, environment or configuration drift, performance regressions, and mystery behaviour in someone else's system. Especially important when the cause is not obvious, when a first fix didn't work, when investigation is going in circles, or when you catch yourself about to try another plausible-sounding change.
---

# Troubleshooting

## The core idea

Troubleshooting is a **search problem**. Somewhere there is a first point where reality
diverges from what the system was supposed to do. Your job is to find it, and your budget is:

```
total cost  ≈  (number of probes)  ×  (cost per probe)
```

Every technique below exists to shrink one of those two factors. Guessing feels fast because
each individual guess is cheap, but it does not shrink the search space — a guess that fails
tells you almost nothing, so the probe count grows without bound. A bisection halves the space
every time.

The failure mode this skill is built to prevent: producing a *plausible mechanism*, declaring
it the cause, changing something, and finding the symptom unchanged — repeatedly. A mechanism
that could explain the symptom is a hypothesis. It becomes a cause only when an experiment
says so.

## The trifecta it sits in

Troubleshooting is one of three linked disciplines, and an investigation is bounded by the other
two whether or not you name them:

- **Observability** — how well you can determine the system's current state relative to its
  intended one. This sets which landmarks you can actually see, and therefore the resolution
  your bisection can reach.
- **Troubleshooting** — deciding what to do to get back to a healthy state. This skill.
- **Operability** — how safely you can change the system's state. This sets which experiments
  and fixes are available to you, and how reversible each one is.

Naming them is practically useful. When you cannot observe a landmark, that is an
**observability gap** — a first-class finding worth reporting, not just an inconvenience to work
around, because it will slow every future investigation through this path. When you can see the
problem but daren't touch anything, that is an **operability gap**, and it changes your strategy
towards read-only probes and offline reproduction. Both belong in the write-up alongside the
fix, because they are usually the difference between a ten-minute diagnosis and a six-hour one
next time.

## The visible protocol

The method below only works if the operator can watch it happening — the trail is the
interface through which they correct you, and their corrections are the highest-value events
in an investigation. Five artifacts are therefore mandatory, in user-visible output, not in
private reasoning. Producing the right conclusion without them is still a failure, because
nobody could have caught you being wrong along the way:

1. **Frame first, visibly.** The first message of an investigation contains the flow sketch
   with its landmarks, the explicit list of what you are assuming works, and your harvest
   questions for the operator — before or alongside the first probes, never after them.
2. **Commit before you probe.** Every probe, or batch of parallel probes, is preceded in
   visible text by the probe-commitment template below: observed, hypotheses (with any killed
   for free by evidence already held), what runs now, and what each outcome will mean.
   Written before the results exist — batching probes is fine, one block covers the batch;
   reconstructing the block after seeing results is not.
3. **Claim narrowly after.** After each result, one line stating what was cleared, in the
   narrowest terms the evidence supports.
4. **Keep the map current.** When any landmark's mark changes (✓/✗/?), show the updated
   sketch with the evidence for each mark.
5. **Gate the verdict.** Before declaring a root cause: re-walk *every* observation collected
   so far and check the story predicts each one — a story contradicted by evidence you
   already hold is dead, however well it fits the evidence that suggested it. State what
   would falsify it. And if any load-bearing link is a guess about what a person did, it is
   not a verdict yet (see traps: "Operator behaviour invented, not asked").

If you notice you are about to present a conclusion whose supporting chain never appeared in
visible text, stop and back-fill the trail first — the omission is usually hiding the weak
link.

### Templates

Use these skeletons for the protocol artifacts. They are deliberately terse: the trail is
breadcrumbs the operator follows to form their *own* understanding, not an essay — quote raw
signal rather than paraphrasing it, skip explanations of anything the operator already knows,
and let the structure carry the reasoning. An artifact growing past ~10 lines means you are
narrating instead of investigating.

**Opening frame** — first message, before or alongside the first probes:

```
## Frame
[flow sketch with landmarks marked ✓/✗/?]
Assuming works:  <list — each entry is an unexamined region>
Known-good ref:  <what worked, when, in which domain — or "none">
Questions:       <operator harvest questions from §2>
```

**Probe commitment** — before each probe or parallel batch:

```
Observed:   <raw signal, quoted; interpretation kept out>
Hypotheses: H1 <...>   H2 <...>   H3 <...>
Killed free: H_n — contradicted by <observation already held>
Probing:    <what runs now>
Expect:     H1 → <outcome>;  H2 → <outcome>;  ...
```

**Result** — one line per probe outcome:

```
Cleared: <narrowest claim the evidence supports>.  Map: <mark changes, or "unchanged">
```

**Verdict** — only after passing the gate:

```
Cause:        <mechanism, from trigger to symptom>
Proven:       <observed directly, evidence named>
Inferred:     <follows from proven, reasoning stated>
Suspected:    <plausible, untested — including any human-action links>
Survives:     re-walked all <N> observations; <any that needed explaining, or "all predicted">
Falsified by: <the result that would overturn this>
```

## 1. Frame the problem

You cannot bisect a space you have not bounded. Spend real effort here; it is almost always
repaid.

**Draw the boundary.** What is inside the system under test, and what are you treating as
environment? Write down explicitly what you are *assuming works*. Those assumptions are not
free — they are unexamined regions of the search space, and when the bisection fails to
converge, the bug is usually hiding in one of them.

**Describe the failing flow.** Not "the app is broken" — the specific execution path, in order,
from trigger to observed failure.

**You do not need to understand the internals to start.** Black-box systems are entirely
troubleshootable, and a coarse conceptual model is enough to begin: request arrives → auth →
business logic → database → response. Landmarks at this stage are *conceptual*, and that is
correct — you refine and enrich them as the search space narrows and you learn which stage
matters. Reading code and documentation is expensive and unfocused before you have a hypothesis;
it becomes valuable once bisection has told you *where* to read. Start from behaviour, not from
source. If your model of the flow turns out to be wrong, probing will tell you quickly and
cheaply — which is itself a useful result.

**Place landmarks on the flow.** A landmark is a checkpoint a healthy execution demonstrably
passes: a log line, a metric, a file appearing, a syscall, a network request, a state
transition. Good landmarks are *observable* — if you cannot currently observe it, it is not yet
a landmark; it is either a gap to instrument or a hint that you should pick a nearby checkpoint
you *can* see.

**Sketch the system and its landmarks before you probe.** A few lines of ASCII are enough. The
diagram is not decoration — it is your search space made visible, and it is what stops you
losing track of which regions are actually cleared:

```
[client] → [ lb ] → [ api ] → [ worker ] → [  db  ] → [ cache ]
    ✓         ✓        ✓          ✗           ?          ?
  200s     access   request    no job      unknown    unknown
           logged   accepted   picked up
                              ↑
                    divergence is in here
```

Mark each landmark cleared (✓), failing (✗), or unknown (?), and note *what evidence* produced
each mark. Update it after every probe and show the updated version to the operator — it makes
your reasoning inspectable at a glance and invites the correction that saves you an hour.

**Find the known-good reference.** When did it last work? What is different now? A working
comparison — an earlier version, a different machine, a passing sibling test, an adjacent
feature exercising the same path — is the single highest-value asset in an investigation,
because a difference between two systems is enormously cheaper to search than the whole
system. If one exists, get it in front of you before probing anything.

Trust it, but verify it. "It worked last week" is a strong prior about *where* to search; it is
not established fact about the system's internal state. The user is reporting their experience,
and they may have been exercising a **different operational domain** — a different input,
profile, configuration, or code path — while the path that fails now was broken all along.
Establish *what specifically* worked and *in which domain* before letting it steer the search,
and be ready for the answer to be "something adjacent to this".

State the frame back to the user before you start probing. It is fast, and if your model of the
flow is wrong they will usually correct it immediately, saving you the entire investigation.

## 2. Harvest before you probe

Order candidate probes by value, where:

```
value of a probe  ≈  (probability mass of the search space it can eliminate)  ÷  cost
```

Note that it is *probability mass*, not raw span. A cheap check of a region that is very
unlikely to contain the fault is still usually a poor probe — unless it happens to eliminate a
large region, in which case the low prior is irrelevant and it is an excellent one. This is why
priors matter: they decide which cheap checks are worth doing at all.

**Ask the operator — their knowledge is the cheapest way to move your priors.** They have been
watching this system and hold observations no telemetry captured. Ask directly and specifically:

- What changed recently — deploys, upgrades, config, hardware, *anything*, including things they
  are confident are unrelated?
- What other symptoms have you noticed, even ones that seem separate?
- Has anything felt *off* lately, even if you cannot pin it down?
- When did it last definitely work, and what exactly were you doing then?
- Has anyone worked around something recently to keep things running?

These answers rarely name the fault, but they reweight the whole search — which is worth far
more than any single probe. Keep asking as the investigation narrows; a question that meant
nothing at the start ("does it happen for all users or just some?") can become decisive once you
know which stage is involved.

Before building any new instrumentation, also spend a few minutes on evidence that already
exists:

- **The system's own error reports.** Application logs, crash dumps, fault files, `journalctl`,
  event logs, CI output. These frequently name the failing component in plain language.
- **Existing telemetry.** Metrics, traces, profiles, dashboards — designed to answer exactly
  the "which stage is misbehaving" question you are asking.
- **History.** `git log`/`git bisect`, deploy and package logs, config change history. If it
  worked on Tuesday, the diff since Tuesday is your search space.
- **Other people's copies of this bug.** Issue trackers, release notes, changelogs, forums. A
  known upstream bug converts hours of bisection into a version number.

This step is boring, which is exactly why it gets skipped. A five-second read of an error log
that names the failing component beats an hour of clever tracing, and the tracing will often
lead you to the same place by a much worse road. If a component has a log you have not read,
read it before you build anything.

## 3. Bisect the landmark space

Pick a landmark near the **middle** of the flow and determine whether it was reached and
whether it was reached *correctly*. Then recurse into the half that contains the divergence.

**Bisect along whichever axis is cheapest.** Position in the flow is only the most obvious
dimension. The same halving logic applies to any axis where you have a working case and a
failing one:

| Axis | Bisect between | Typical tool |
|---|---|---|
| **Structural** | stages of the flow | logs, traces, probes at each stage |
| **Temporal** | last known-good and now | `git bisect`, version pinning, deploy/package history |
| **Configuration** | working config and broken config | halve the diff, toggle feature flags |
| **Input** | an input that works and one that fails | shrink the failing input to a minimal case |
| **Environment** | a host/container that works and one that doesn't | compare images, versions, env vars |
| **Population** | affected users/tenants/regions vs unaffected | segment the metrics |
| **Load / concurrency** | a level that works and one that fails | vary parallelism, rate, data volume |

The most valuable axis is usually whichever one gives you a **working reference** to compare
against, because a diff is dramatically cheaper to search than a whole system. If you have two
axes available, take the one that is cheaper to sample: temporal bisection is nearly free in a
repo with good history, and often absurdly expensive in a system with no versioned state.

You can also switch axes mid-investigation. Structural bisection localising the fault to one
stage often makes a temporal bisection tractable, because now you only need to search that
stage's history.

**Weight by measurement cost, not just position.** A landmark 40% along that you can check in
one command beats a perfectly centred one that needs an hour of setup. You are minimising
`probes × cost-per-probe`, and an off-centre cheap probe usually wins that trade.

**"Reached" is not the same as "correct".** Soft failures upstream produce hard failures
downstream: a stage that returns success but with a truncated buffer, a stale value, a default
that silently replaced a real config, an empty result set. When you check a landmark, check the
*content* of what passed through it, not merely that it happened. Most bisections that converge
on the wrong stage do so because a soft failure was scored as a pass.

**A failing probe is a result, not a dead end.** When a probe reports failure, it has already
done its job: the divergence is now bounded between the last landmark you saw pass and the one
that just failed. The next move is to observe some landmark *inside that span*. Sometimes the
cheapest way to do that is a sharper instrument aimed at the same place — a debug channel,
exception tracing, a symbol-resolving backtrace. Sometimes it is cheaper to go and check a
different landmark. Choose on cost, not reflex: the goal is to halve the remaining span, and a
better instrument is only one of several ways to buy that.

**Record precisely what each probe cleared.** "The dependency loaded" clears *loading*; it does
not clear that dependency being the wrong build. Over-claiming what a result established
silently deletes regions from the search space — the same failure as skipping them by
assumption, but harder to notice because it feels like progress. Under-claiming wastes probes
re-checking cleared ground. Write down the span each result actually clears, in the narrowest
terms the evidence supports.

**Never skip a region because it "can't be the problem".** That is the one move guaranteed to
prevent convergence — if the fault is in the region you excluded by assumption, no amount of
further searching elsewhere will find it. If you want to exclude a region, exclude it with a
cheap probe, not with confidence.

When the bisection stalls, that record of cleared spans is what you re-examine: something you
marked "clear" was cleared by assumption, or was cleared more narrowly than you remembered.

## 4. Test each landmark with a designed experiment

At every landmark, run the loop deliberately. Writing the four steps out is not ceremony — it
is what stops you from sliding into "try a thing and see".

**Observe.** State what you actually saw, quoting the raw signal. Keep the observation separate
from your interpretation of it; conflating them is how a guess gets promoted to a fact.

**Orient.** Generate *several* hypotheses that would explain the observation. If you have only
one, you are not investigating, you are confirming. Deliberately include:
- the **null hypothesis** — nothing is wrong here, the signal is expected or a measurement
  artefact;
- at least one alternative that a different person would favour;
- the possibility that the system is misreporting its own state (see §5).

Then, before designing any experiment, run every hypothesis against the evidence you already
hold. A hypothesis contradicted by an observation already in hand is dead at zero cost —
killing it with an experiment instead is paying probe budget for information you already own.
This free pass is itself a bisection step: only the survivors earn experiments, and if exactly
one survives, your next move may be a verdict-gate re-walk rather than a probe at all.

**Decide.** Design the experiment that best *discriminates* between the live hypotheses — ideally
one that can falsify your favourite cheaply. Prefer experiments whose two outcomes point in
different directions; an experiment that "confirms" under several hypotheses at once has taught
you nothing. Before running it, say what each result will mean. That commitment prevents the
after-the-fact rationalisation that makes any result look supportive.

**Act.** Run it. Record the result — including boring ones, which are what shrink the space.

### Narrate the loop out loud

Say each step as you go, briefly. Prefer spending effort on *stating* your observation,
hypothesis and experiment over doing that reasoning silently:

```
Observed:   worker logs show no job picked up; queue depth is climbing
Hypothesis: worker isn't consuming — either it's not connected, or the job is
            being filtered out before it reaches the handler
Experiment: check the worker's broker connection state, then enqueue a job with
            known-good attributes and watch whether it's acknowledged
Expect:     if connected, the synthetic job is consumed → filtering; if not
            connected, we've localised it to the broker link
```

Four lines, and they earn their keep several ways. The operator can interject — *"oh, we
changed the queue name last week"* — which is the single highest-value event in an
investigation. Committing to what each outcome will mean *before* running it prevents
after-the-fact rationalisation. And when you are wrong, the trail shows exactly which step was
wrong instead of forcing a restart from scratch.

A long silence followed by a confident conclusion is the worst possible interaction pattern: the
operator cannot help, cannot correct you, and cannot calibrate how much to trust the result.

### Perturb when observation is uninformative

A system at rest may simply not emit the signal you need. Change something on purpose and watch
the response: raise log verbosity, feed a known-good or known-bad input, force the error path,
constrain a resource, remove a component. A system's response to a deliberate change carries
far more information than its quiescent state.

**Stay inside the blast radius that already exists.** A diagnostic step must not create impact
beyond what the failure is already causing. Restarting a component that is already dead is free;
restarting a healthy one that is currently carrying load is not. Be especially careful with
anything that destroys evidence, mutates persistent state, affects users who are currently fine,
or cannot be undone.

Prefer, in order: read-only observation → reversible change in an isolated copy → reversible
change in the live system → irreversible change. If you have exhausted the safer options and
genuinely need a perturbation that could cause harm, **stop and ask the operator first**,
stating what you want to do, what you expect to learn, and what the worst case is. They know the
business context you do not — what is load-bearing right now, what is mid-migration, what has no
backup.

### Change things only through their real mechanism

Every change you make becomes part of the system's state, and therefore part of the space you
are searching. Make changes the way the system expects them: run the installer, call the API,
use the package manager, apply config through whatever owns that config. Ad-hoc low-level
touches — copying files into place by hand, editing state that a tool owns, poking directly at
internals — are untested, unreproducible, and inject hidden state into the very space you are
trying to narrow.

This bites hardest when you are assembling a comparison environment, because a hand-built
"clean" system is not clean, it is *differently dirty* — and undocumented, since nothing
recorded what you did. It bites again when applying a fix: a fix applied through the proper
mechanism is one you can verify, repeat, and hand to somebody else, whereas a hand-placed one
leaves behind a system nobody can reconstruct, including you next week.

If you genuinely cannot use the real mechanism, write down exactly what you did by hand and
treat every one of those touches as an uncontrolled variable for the rest of the investigation.

## 5. Assume the system is an unreliable narrator

Complex systems run permanently in degraded mode — latent faults are always present, and normal
operation is a set of compensations that usually work (see <https://how.complexsystems.fail/>).
Three consequences that change how you read evidence:

**Finding *a* fault is not finding *the* fault.** There is always something broken nearby. A
genuine defect you discover on the way is not automatically the one causing this symptom. Ask
"does this actually produce the observed behaviour?" before acting on it.

**Error messages describe the reporter's model, not reality.** A message says what some author
guessed the most likely cause was, in a code path that may itself be a fallback. Treat message
text as a pointer to the *code that emitted it*, not as a diagnosis. "Check your microphone is
plugged in" is a real message from a real system whose microphone was fine — the recogniser
had failed for unrelated reasons and that was the nearest handler.

**Self-reported state travels through possibly-broken machinery.** Health checks, status
endpoints, and admin UIs can report success while the thing they describe is broken.
Corroborate important observations from an independent path before building on them.

## 6. Hidden and ambient state

Behaviour depends on state you did not think about: caches, temp files, environment variables,
open handles, in-memory state from before a config change, leftover artefacts from a previous
run, another process holding a resource.

Where it is non-destructive, **resetting that state is a high-value probe**: restart the
process, clear the cache, use a fresh container or prefix, roll back to a known-good version,
reboot. It cheaply splits the space into "depends on accumulated state" versus "reproduces from
clean" — which are very different investigations.

Two cautions. A reset **destroys evidence**, so capture what you need first — this is usually
the single most irreversible thing you will do. And a reset that fixes the symptom has not told
you the cause; it has told you the cause was state-dependent, which is a lead, not an answer.

## 7. Parallel experiments

When several independent questions are open, running them concurrently cuts wall-clock time.
Dispatching subagents is appropriate for experiments that are **read-only, hermetic, or
research** — searching for prior reports, reading unrelated subsystems, running isolated tests
in separate sandboxes.

Guard against the ways parallelism corrupts results:
- **Noisy neighbours.** Concurrent runs contending for CPU, disk, network, or a shared service
  will distort anything timing- or load-sensitive. Run performance experiments alone.
- **Shared mutable state.** Two agents touching one prefix, database, or working tree produce
  results that describe neither experiment. Isolate, or serialise.
- **Leading questions.** Give an agent the raw observation and ask what explains it. Handing
  over your hypothesis and asking for confirmation will get you confirmation.

## 8. After recovery, keep going

Restoring service ends the incident, not the investigation. The fix itself is now your best
piece of evidence:

- **Why did that work?** Trace the mechanism from the change you made to the symptom that
  disappeared. If you cannot, you may have moved the fault rather than fixed it.
- **How did the system reach that state?** The proximate cause has a cause. A missing
  dependency, a drifted version, an unrepeatable manual step — each points at a different
  structural weakness.
- **Why was it not caught?** Absent monitoring, an untested path, a silent fallback that turned
  a loud failure into a quiet one.
- **What makes this class of failure structurally less likely?** A check in CI, a version pin,
  a startup assertion, a script replacing manual steps, an alert on the landmark that would
  have localised it in minutes. Propose specific changes, not "be more careful".

Also record the *method* that worked: the diagnostic that finally localised it, and the dead
ends, so the next person does not re-walk them.

## Reporting

Keep three categories visibly separate, in your own notes and to the user:

- **Proven** — observed directly, with the evidence attached.
- **Inferred** — follows from proven facts, with the reasoning stated.
- **Suspected** — plausible, untested.

Before promoting anything to Proven or declaring a cause, re-walk the complete list of
observations — the conclusion must survive all of them, not merely the ones that inspired it.
The observation most likely to kill your story is one you collected early, for another
purpose, and stopped thinking about.

State what would falsify your current conclusion. When a result contradicts something you said
earlier, correct it plainly and move on. Confidence should track evidence: "the trace shows X"
and "I think X" are different claims and the user needs to know which one they are getting,
because they will make decisions based on it.

## Reference material

- `references/traps.md` — the specific ways investigations go wrong (ad-hoc manual changes,
  over-claiming what a probe cleared, treating a failing probe as a dead end, inventing
  operator behaviour instead of asking, and others), each
  written as a *signature you can recognise mid-investigation*. Read this when you are stuck,
  when a fix didn't work, or before declaring a root cause.
- `references/complex-systems.md` — how the nature of complex systems should change your reading
  of evidence: degraded baselines, failure as conjunction, defences that hide faults, hindsight
  bias. Read this when assessing whether a defect you found is *the* one, and again when writing
  the prevention plan.
- `references/worked-example.md` — a full investigation using this method, including the wrong
  turns and what corrected them. Read this for a concrete model of the method under way.
