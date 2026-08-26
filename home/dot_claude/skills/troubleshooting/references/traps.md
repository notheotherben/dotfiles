# Investigation traps

Each entry gives the **signature** — how it feels from the inside, while it is happening — and
the correction. Most of these are cheap to check and expensive to miss, so when an
investigation stalls, read the signatures and ask which one describes your last hour.

## Ad-hoc manual changes to the system

**Signature.** To set something up, test something, or apply a fix, you made a low-level change
by hand: copied a file into place, edited state that some tool owns, tweaked an internal
directly. Later the system behaves in ways nobody can explain.

**What went wrong.** The system's real mechanisms — installers, APIs, package managers, config
management — do more than move bytes. They write version records, registry entries, manifests,
side-by-side metadata, checksums, and dependency links. Reproducing "the important part" by
hand omits all of that invisibly. Worse, the change is untested and unreproducible, so it is now
hidden state inside the search space you are trying to shrink. You have made the problem bigger
while trying to solve it.

**Correction.** Use the real mechanism: run the installer, call the API, use the package
manager. If you truly cannot, write down every manual touch and carry each as a known
uncontrolled variable for the rest of the investigation.

**The classic consequence — a contaminated control.** You build a "clean" comparison environment
by copying pieces out of the suspect system. Whatever is faulty comes along with them, the
control reproduces the bug faithfully, and you conclude the environment is innocent and the
fault is fundamental ("X is simply incompatible with Y"). That conclusion is the exact opposite
of the truth, and it is unusually hard to dislodge because the control appears to have *proved*
it. Build controls from authoritative sources — an official installer, a package manager, a
pristine image — never from parts of the patient. A control that reproduces the bug perfectly on
the first attempt deserves suspicion, not celebration.

## Known-good history treated as proof — or dismissed

**Signature.** Either (a) you have concluded "this configuration cannot work" while the user
says it worked last week, and you set that contradiction aside as a curiosity; or (b) you took
"it worked last week" as established fact and built a search around it.

**What went wrong.** Both directions. A user report is evidence about *their experience*, not
about the system's internal state — they cannot see inside it. The system may have been
exercising a **different operational domain**: a different input, profile, config, or code path.
It may have been failing in the current domain all along, or succeeding by way of a fallback
that has since been removed. But a credible report of prior success is also a strong prior that
should shape where you search, and shrugging it off wastes it.

**Correction.** Trust but verify. Establish *what specifically* worked and *in which domain*,
then use it to weight the search rather than to terminate reasoning. If you cannot reconcile a
credible "it worked" with your conclusion, your conclusion is probably too broad — most often
you have generalised a domain-specific failure into a universal one.

## Treating a failing probe as a dead end

**Signature.** A probe reported failure without explaining why, and you started theorising about
causes from surrounding context — or went looking for something else to try.

**What went wrong.** A failing probe is a successful bisection step. It has bounded the
divergence to the span between the last landmark that passed and the one that just failed. The
mistake is to read "failed, reason unknown" as the end of the trail rather than as a *new,
narrower interval*.

**Correction.** Name the two landmarks the failure now sits between, then pick something to
observe inside that span. Sometimes the cheapest observation is a sharper instrument on the same
spot — a debug channel, exception tracing, a symbol-resolving backtrace. Sometimes it is cheaper
to check a different landmark. Choose on measurement cost, not on reflex; both are just means to
halve the interval. Speculation is what happens when you stop bisecting, and it is unbounded
where a probe is not.

## Over-claiming what a probe cleared

**Signature.** You verified something and mentally cleared a whole region — "dependencies
resolve", "the file is there", "the service is up", "the config is correct" — and the fault
later turns out to live inside that region.

**What went wrong.** The property you established is narrower than the region you retired. A
dependency *loading* does not establish that it is the right build. A file *existing* says
nothing about its version or contents. A port *accepting connections* does not mean the service
behind it is healthy. Over-claiming deletes search space by assumption while feeling like
progress, which makes it much harder to spot than an obvious skipped region.

**Correction.** *Presence*, *identity*, and *behaviour* are three different checks, and
dependency and environment faults usually live in identity ("which build is this, really?") and
behaviour. After each probe, state the clearing in the narrowest terms the evidence supports —
"this loads" rather than "this layer is fine" — and search the remainder.

## Plausible mechanism promoted to cause

**Signature.** You found something genuinely wrong — a stale ID, a missing file, a deprecated
call — that *would* produce this symptom, and announced it as the root cause.

**What went wrong.** Complex systems always contain nearby faults (see
<https://how.complexsystems.fail/>). Finding one is weak evidence that it is *this* one. Where
several latent defects exist, the first plausible mechanism you find is more likely coincidence
than cause.

**Correction.** Before declaring cause, ask what experiment distinguishes "this is the cause"
from "this is a real but unrelated defect" — usually: fix or disable it and see whether the
symptom moves. Until then it is a candidate, and should be described as one.

## Operator behaviour invented, not asked

**Signature.** Your causal story contains a step performed by a human — something they typed,
clicked, configured, or intended — that no log records and nobody told you. It usually enters
the story late, as the only filler that makes an otherwise-solid mechanism work ("they must
have typed the password into the PIN prompt"), and it feels like an inference because
everything around it was measured.

**What went wrong.** Every other link in the chain was observed; this one was authored. Human
actions are collectable evidence — the operator is right there — and they are also where
plausible guesses are most often wrong, because people's actual habits are far less guessable
than system behaviour. A story whose load-bearing link is an invented human action is a
hypothesis wearing a conclusion's clothes, and it fails in the most expensive way: the operator
trusts it precisely because the rest of the chain is rigorous.

**Correction.** Before building on any human-performed step, ask: "what exactly did you
type/do there?" — it is among the cheapest probes available and can eliminate more probability
mass than any log read. If the answer is unavailable, mark that link Suspected and prefer an
experiment that takes the human out of the loop. When the operator later contradicts an
invented link, treat the whole story as a falsified hypothesis to be re-derived — not as a
detail to patch.

**Signature.** You applied the fix implied by your root-cause claim, the symptom was unchanged,
and you immediately reached for another hypothesis without revisiting the first.

**What went wrong.** A failed fix is a high-information result — it falsified a specific model.
Discarding it silently converts a bisection into a random walk.

**Correction.** Explicitly retract the claim it rested on and state what the failure rules out.
Then check whether the fix was actually applied and actually reached the relevant code path:
"the fix didn't work" and "the fix was never in effect" look identical from outside and demand
different responses.

## Excluded a region by assumption

**Signature.** The bisection is not converging, and some part of the flow was never probed
because it "obviously isn't the problem" — it is standard, well-tested, someone else's code, or
you only just replaced it.

**Correction.** Keep an explicit list of cleared spans and how each was cleared. Anything
cleared by reasoning rather than measurement goes back into the search space when you stall.
Recently-changed components deserve suspicion — but so do stable ones the change interacted
with.

## Soft failure scored as a pass

**Signature.** You confirmed a stage "ran" or "returned success", searched downstream, and the
real divergence was at that stage — in the *content* of what it produced.

**Correction.** Check the payload, not just the transition: is the value right, the list
non-empty, the version what you expect, did a default silently replace real config? Silent
fallbacks are the usual culprit, converting a loud upstream failure into a quiet wrong answer
that only becomes visible much later.

## Measurement artefacts from your own tooling

**Signature.** A result is confusing, self-contradictory, or changes when nothing should have
changed.

**What went wrong.** Your instrument perturbed the system, or measured itself. Common cases: a
process query whose pattern matches the command line of the query itself; a grep matching its
own arguments; a log tail including entries generated by your previous probe; timestamps from a
run you forgot was still going; a debug flag that changes timing enough to hide a race.

**Correction.** When a measurement looks impossible, suspect the measurement before the system.
Verify the instrument against a known input. Match processes by name rather than command line,
scope searches to timestamps after your action, and confirm "before" and "after" came from the
same instrument.

## Differential signal left unused

**Signature.** You know path A works while path B fails — two engines, two machines, two users,
two inputs — and you are still investigating B in isolation.

**Correction.** Enumerate what A and B share and where they diverge. The fault is almost
certainly in the divergence, and the shared parts are cleared for free. Even when it does not
localise the fault, it tells you which subsystems to stop looking at — and it is usually the
cheapest search space available.

## Correlation with a recent change

**Signature.** Something changed — a migration, an upgrade, a deploy — and the symptom appeared,
so the change is assumed to be the cause. Or, having found the change innocent in one respect,
it is dismissed entirely.

**Correction.** Both are errors. A temporally-correlated change is a strong prior deserving
first search, but it is not proof, and changes frequently *expose* a latent fault rather than
introduce one — trigger and cause are different things and both matter. Use the change to order
your search, not to end it. When you clear a change, be precise about what you cleared: "the
migration did not corrupt these files" is not "the migration is unrelated".
