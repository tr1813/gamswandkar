import subprocess

CAVES = ['marco_polo_schacht','hraeswelgr','gurgeltest_hoehle','gurgeltest_hoehle_III',
'rampage_halle','gamswandkluft', 'halbmond_schacht', 'abflussrohr', 'hohes_delta_hoehle']

for cave in CAVES:
    subprocess.check_output('''python3 A4_mapper.py {} --cadastral_number="NEU"'''.format(cave), shell = True)
