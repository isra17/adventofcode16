data = open("1.txt", "rb").read()

transition = {
        "R": {"N":"E", "E":"S", "S":"W", "W":"N"},
        "L": {"N":"W", "W":"S", "S":"E", "E":"N"}
}

dir_vecs = {"N":[0,1], "E":[1,0], "S":[0,-1], "W":[-1,0]}

def visit(vmap, p1, p2):
    skip_first = False
    dir_x = 1 if p1[0] < p2[0] else -1
    dir_y = 1 if p1[1] < p2[1] else -1
    for x in range(p1[0], p2[0]+dir_x, dir_x):
        for y in range(p1[1], p2[1]+dir_y, dir_y):
            if skip_first and (x,y) in vmap:
                return (x,y)
            skip_first = True
            vmap.add((x,y))

state = [0,0,"N"]
vmap = set()
pf = None
for cmd in data.split(", "):
    cur = state[:2]
    state[2] = transition[cmd[0]][state[2]]
    for i in [0,1]:
        state[i] += dir_vecs[state[2]][i] * int(cmd[1:])
    pf = visit(vmap, cur, state)
    if pf is not None:
        break


pf = pf or state


print abs(pf[0]) + abs(pf[1])

