__author__ = 'chozabu'

import os, json

defaultSettingsDict = {
    "observer_points_per_second":200.,
    "goal_height":600,
    'goal_thickness':120,
    'airhole_xnum':14,
    'airhole_radius':80,
    'enable_particles':1,
    'volume_multi':.85,
    'puck_max':4,
    'paddle_max':2,
    'vortex_power':.6,
    'vortex_radius':140,
    'vortex_static':1

}

settingsDict = defaultSettingsDict

datadir = ""

def loadSettings():
    global settingsDict
    fileNamePath = datadir+"LightHockeySettings.jso"
    if os.path.exists(fileNamePath):
        if os.path.isfile(fileNamePath):
            with open(fileNamePath) as fo:
                settingsDict = json.load(fo)

    for a,b in defaultSettingsDict.iteritems():
        if a not in settingsDict or 1:
            settingsDict[a]=b
    saveSettings()



def saveSettings():
    fileNamePath = datadir+"LightHockeySettings.jso"
    with open(fileNamePath, 'w') as fo:
        json.dump(settingsDict, fo)

