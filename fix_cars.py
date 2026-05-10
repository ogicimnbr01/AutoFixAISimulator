import re, json

with open('backend/lambdas/shared/scenarios.py', 'r', encoding='utf-8') as f:
    scenarios = f.read()

replacements = {
    '2002 Japon Sedan 1.6': '2002 Japon Sedan 1.6',
    '2006 Amerikan Hatchback 1.6': '2006 Amerikan Hatchback 1.6',
    '2010 Alman Hatchback 1.4': '2008 Alman Hatchback 1.4',
    '2008 Kore Sedan 1.5': '2010 Fransız Sedan 1.5',
    '2010 Fransız Sedan 1.5': '2010 Fransız Sedan 1.5',
    '2012 Fransız Hatchback 1.5': '2004 Alman Hatchback 1.6',
    '2005 Alman Kompakt 1.6': '2015 Kore Hatchback 1.4',
    '1998 İtalyan Hatchback 1.6': '1998 İtalyan Hatchback 1.6',
    '2011 Japon Sedan 1.8': '2012 Japon Sedan 1.6',
    '2014 Kore Kompakt 1.6': '2009 Fransız Hatchback 1.4',
    '2009 Fransız Kompakt 1.6': '2007 Japon Hatchback 1.5',
    '2015 Premium Alman Sedan 2.0': '2005 Premium Alman Sedan 2.0',
    '2017 Premium Alman Hatchback 1.6': '2011 Premium Alman Sedan 2.1',
    '2013 Japon SUV 1.5': '2003 Premium Alman Sedan 1.8',
    '2016 Premium Alman Sedan 1.6': '2014 Premium İsveç Sedan 2.0',
    '2018 Premium İsveç SUV 2.0': '2016 Çek Sedan 1.6',
}

for old, new_val in replacements.items():
    scenarios = scenarios.replace(old, new_val)

with open('backend/lambdas/shared/scenarios.py', 'w', encoding='utf-8') as f:
    f.write(scenarios)

with open('app/lib/screens/scenario/scenario_select_screen.dart', 'r', encoding='utf-8') as f:
    dart = f.read()

for old, new_val in replacements.items():
    dart = dart.replace(old, new_val)

with open('app/lib/screens/scenario/scenario_select_screen.dart', 'w', encoding='utf-8') as f:
    f.write(dart)
