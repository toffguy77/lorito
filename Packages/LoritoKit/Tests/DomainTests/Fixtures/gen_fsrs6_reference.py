# Generates FSRS-6 cross-check fixtures from py-fsrs's own formula functions,
# applied with Lorito's semantics: one memory update per learning day, elapsed
# whole days, no intra-day learning steps.
import json, sys
from fsrs import Scheduler, Rating
import fsrs
sch = Scheduler()
def R(t, s): return (1 + sch._FACTOR * t / s) ** sch._DECAY
histories = [
    [(0, 3), (1, 3), (4, 3), (14, 3), (45, 3)],
    [(0, 1), (1, 3), (3, 3), (10, 1), (11, 3), (16, 4)],
    [(0, 4), (8, 4), (40, 4)],
    [(0, 2), (2, 2), (5, 3), (13, 2)],
    [(0, 3), (2, 1), (3, 1), (4, 3), (9, 3), (30, 4)],
]
out = []
for h in histories:
    s = d = None; last = None; steps = []
    for day, g in h:
        rating = Rating(g)
        if s is None:
            s = sch._initial_stability(rating=rating)
            d = sch._initial_difficulty(rating=rating, clamp=True)
        else:
            r = R(day - last, s)
            if rating == Rating.Again:
                s = sch._next_forget_stability(difficulty=d, stability=s, retrievability=r)
            else:
                s = sch._next_recall_stability(difficulty=d, stability=s, retrievability=r, rating=rating)
            d = sch._next_difficulty(difficulty=d, rating=rating)
        last = day
        steps.append({"day": day, "rating": g, "stability": s, "difficulty": d})
    out.append(steps)
json.dump({"source": f"py-fsrs {__import__('importlib.metadata').metadata.version('fsrs')} formula functions",
           "parameters": list(sch.parameters), "histories": out}, sys.stdout, indent=1)
