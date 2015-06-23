######
# log_filename is generated by super_report_nonocc.py's stdout. 
# To get the running time for algo, run
# python get_time_from_log.py log_filename algo [show_testcase]
# the output is of the format
# [dataset/testcase\t]time
# e.g.,
# [halfsize/Aloe ]1.232
# [halfsize/Baby1 ] 0.649
# the first column is shown if show_testcase
######

import subprocess
import sys

log_filename = sys.argv[1]
algo = sys.argv[2]
show_testcase = bool(int(sys.argv[3])) if len(sys.argv) > 3 else False

blocks = subprocess.check_output(['grep', '-A', '4', '~~~ ' + algo + '@',
  log_filename]).split('--\n')

for block in blocks:
  lines = block.split('\n')
  testcase = lines[0].split('@')[1][:-4]
  time = lines[2].split('all: ')[1][:-1]
  if show_testcase:
    print testcase + '\t' + time
  else :
    print time