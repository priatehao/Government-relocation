import os
from pathlib import Path

dir_path = os.path.dirname(os.path.realpath(__file__))
dofilepath = Path(dir_path).joinpath('projectpath.do')
projectpath = Path(dir_path).parent.parent
print(dofilepath, projectpath)

with open(dofilepath, 'w') as f:
    f.write(f'cd {projectpath}')