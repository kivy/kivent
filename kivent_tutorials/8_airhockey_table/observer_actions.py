__author__ = 'chozabu'

actioncosts={
    "puck_storm":10000,
    "wall":5000,
    "vortex":1000,
    "speedup":0,
}

def points_to_powerup(points):
    if points>=10000.:
        action="Puck Storm"
        command="puck_storm"
    elif points>=5000.:
        action="Make Wall"
        command="wall"
    elif points>=1000.:
        action="Make Vortex"
        command="vortex"
    else:
        action="Boost Puck"
        command="speedup"
    return action, command