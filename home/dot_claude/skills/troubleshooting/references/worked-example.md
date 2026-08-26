# Worked example

A real investigation, including the wrong turns and what corrected them. The value is in the
shape of the search, not the specific technology.

## The report

> "VoiceAttack 2 isn't working anymore. It shows *Unable to enable speech recognition. Make
> sure your mic is plugged in, enabled and allowed through sound properties*, and no mic input."

A Windows app running under Wine/Proton on Linux. Days earlier the user's Steam install had been
migrated from Flatpak to a native package, which rewrote ~8,000 symlinks inside Proton prefixes.
Natural prior: the migration broke it.

## Framing

**Boundary.** Microphone hardware → PipeWire → Steam Linux Runtime container → Wine audio driver
→ .NET application → speech engine. Explicitly assumed working: the mic hardware and desktop
audio stack — *and that assumption was written down*, so it could be revisited.

**Landmarks on the failing flow.** Sketched before probing anything. Note these are *conceptual*
— no source code had been read, and none needed to be:

```
[mic] → [PipeWire] → [container] → [Wine audio] → [app opens capture] → [engine] → [recognition]
  ?          ?            ?             ?                  ?               ?            ✗
                                                                                    reported
```

Everything upstream of the symptom is unknown. That is the correct starting state, and the whole
job is turning question marks into ✓ and ✗ as cheaply as possible.

**Known-good reference.** The user reported it working two days earlier. Treated as a prior for
where to search — not as proof, since it later turned out they had been running a *different
engine*, i.e. a different operational domain.

## Bisecting to the failing stage

The midpoint landmark — *does the app open a capture stream?* — was observable from outside the
app with one command plus a Wine debug channel:

```
render_GetBuffer  : 91      (audio output — working)
capture_GetBuffer : 0       (audio input — never attempted)
```

One probe cleared the whole downstream half. The app never asked for a microphone, so no device,
driver or permission issue could be responsible — and the error message's claim about the mic was
disproved outright.

A free differential narrowed it further: switching the app's speech engine made the mic work. Two
engines, one machine, one working. Everything they share — the entire audio stack — was cleared,
and the fault had to live in what differed:

```
[mic] → [PipeWire] → [container] → [Wine audio] → [app opens capture] → [engine] → [recognition]
  ✓          ✓            ✓             ✓                  ✗               ?            ✗
        cleared by the working engine (shared path)       never       ↑
                                                        attempted    divergence in here
```

Two probes, and the search space went from the entire stack to one component. Neither probe
required reading a line of source.

## Three wrong turns

**A plausible mechanism promoted to cause.** A stale audio-device ID pointing at a NOTPRESENT
endpoint was found and declared the root cause. Purging it changed nothing. A real defect, but
not this one.

**A conclusion that outran its evidence.** After a "clean prefix" test reproduced the failure,
the conclusion was "this library is fundamentally incompatible with Wine" — a universal claim
built from one domain-specific observation. The user's "it worked Tuesday" contradicted it and
was set aside as a curiosity. The right reading was not "the user must be right" but "this
conclusion is too broad, go and reconcile them".

**A manual touch that contaminated the control.** The "pristine prefix" was assembled by
hand-copying runtime DLLs *out of the broken prefix* instead of running the installer. The faulty
component came along. The control reproduced the bug faithfully and was read as proof the
environment was innocent — the precise opposite of the truth. It nearly cost a full environment
rebuild that would have fixed nothing.

The user's corrections — *"things don't just stop working without a cause"* and *"did you copy
the DLLs in or run the installer?"* — are what reopened the search.

## Continuing the bisection

**Read the primary source.** The application wrote its own fault log, which said in plain text:

```
Recognition failed to start. Error: The type initializer for
'Microsoft.ML.OnnxRuntime.NativeMethods' threw an exception.
```

That named the failing component outright and had been available from the first minute. Hours of
inference from third-party traces had gone into reconstructing what it stated directly. New span:
**app start → ONNX Runtime initialises**.

**Next landmark: does the library load at all?** A loader trace on an isolated `LoadLibrary` of
the DLL returned:

```
Initialization of "onnxruntime.dll" failed
```

*That* it failed, not why. This is not a dead end — it is a bisection result. It bounded the
divergence to the span between **"dependencies resolve and load"** (which the same trace showed
succeeding) and **"the library finishes initialising"**. That is a short span, and the question
became: what is the cheapest landmark to observe inside it?

**Choosing the next probe by cost.** Two options: check a different landmark, or aim a sharper
instrument at the same one. Here the sharper instrument was one flag — an exception-tracing
channel — and it produced a named faulting frame:

```
Exception 0xc0000005 (ACCESS_VIOLATION)  info[0]=0 info[1]=0   ← null dereference
  MSVCP140.dll + 0x12EB0        ← faulting frame
  onnxruntime.dll + 0xA5107C
  ucrtbase.dll + 0x2BECA        ← C++ static initialisers
```

The instrument upgrade was not a reflex, it was landmark selection: the interval was small and
this was the cheapest thing that could subdivide it.

The landmarks had by now been refined several times — the coarse conceptual chain from the start
had been replaced, in the region that mattered, by much finer ones:

```
[app start] → [engine loads] → [deps resolve] → [deps load] → [ORT init] → [recognition]
     ✓              ✓                ✓               ✓             ✗            ✗
                                                            ↑
                                          MSVCP140 executing, faults here
```

This is the normal shape of an investigation: coarse landmarks everywhere at the start, and fine
landmarks only in the span you have narrowed to. Enriching them everywhere up front would have
been wasted work, since most of them get cleared wholesale by a single probe.

## Closing the last interval

The trace cleared one more landmark precisely: the C++ runtime **loaded and was executing**.
Combined with the earlier result, the divergence was now pinned between "MSVCP140 loads" and
"onnxruntime initialises successfully" — which is to say: *this runtime build cannot service this
library*.

Note what an earlier probe had established, and what it had not. "All imports resolve" was true,
and it had been used to clear the entire dependency layer. It only ever established **presence**.
The fault was in **identity** — which build. That over-claim is what kept the dependency layer
out of the search for hours.

With a one-interval hypothesis, the OODA loop closes quickly:

- **Hypothesis.** The library was built against a newer C++ runtime than the one installed; symbol
  names match so the loader is satisfied, but the ABI does not.
- **Experiment.** Install the newer runtime *through its installer* — the real mechanism, not a
  file copy — and re-run the isolated load.
- **Prediction, stated first.** If the hypothesis holds, initialisation completes. If it fails
  identically, the hypothesis is dead and the span must be subdivided differently.
- **Result.** The environment had **14.28**; the library needed **14.4x**. After installing it,
  initialisation completed and the app opened a live capture stream.

## What the method would have done differently

1. **Read the app's own fault log first.** Minutes, not hours. It named the component.
2. **Use the differential immediately.** Engine A works, engine B doesn't → search only the
   difference. The shared audio stack was cleared for free, and was searched anyway.
3. **State clearings narrowly.** "Imports resolve" clears loading, not versions.
4. **Never hand-assemble a control.** Use the installer; a hand-built environment is differently
   dirty, not clean.
5. **Keep conclusions inside the evidence.** "Fails in this configuration" was supportable;
   "fundamentally incompatible" was not, and the contradiction with prior success was the signal
   that it had overreached.

## Afterwards

The fix is evidence: the environment's C++ runtime had drifted below what the application
required. Structural follow-ups — a version assertion at startup, adding the runtime to the
environment's bootstrap script so a rebuild cannot silently omit it, and recording that the
application's fault log is the first thing to read next time.

The **observability gaps** are findings in their own right, and arguably worth more than the
fix. The loader reported "initialisation failed" with no reason at default verbosity, so the one
signal that mattered needed a flag nobody would think to set. The application's own fault log
was written to a file with no indication anywhere in the UI that it existed. Both turned a
five-minute diagnosis into a multi-hour one, and both will do so again to the next person unless
they are written down.
