import sys
import platform
import glob
import os

matlab = 'matlab'


model = ''
algorithm = [] 
optimization = []
phi_str = []
controlpoints = []
input_name = []
input_range = []
parameters = []
timespan = ''
loadfile = ''

status = 0
arg = ''
linenum = 0

algopath = ''
trials = ''
timeout = ''
max_sim = ''
addpath = []

epsilon = []
threshold = []
locBudget = ''
time_budget = ''

with open(sys.argv[1],'r') as conf:
	for line in conf.readlines():
		argu = line.strip().split()
		if status == 0:
			status = 1
			arg = argu[0]
			linenum = int(argu[1])
		elif status == 1:
			linenum = linenum - 1
			if arg == 'model':
				model = argu[0]

			elif arg == 'optimization':
				optimization.append(argu[0])
			elif arg == 'phi':
				complete_phi = argu[0]+';'+argu[1]
				for a in argu[2:]:
					complete_phi = complete_phi + ' '+ a
				phi_str.append(complete_phi)
			elif arg == 'controlpoints':
				controlpoints.append(int(argu[0]))
			elif arg == 'input_name':
				input_name.append(argu[0])
			elif arg == 'input_range':
				input_range.append([float(argu[0]),float(argu[1])])
			elif arg == 'parameters':
				parameters.append(argu[0])	
			elif arg == 'timespan':
				timespan = argu[0]
			elif arg == 'trials':
				trials = argu[0]
			elif arg == 'timeout':
				timeout = argu[0]
			elif arg == 'max_sim':
				max_sim  = argu[0]
			elif arg == 'addpath':
				addpath.append(argu[0])
			elif arg == 'loadfile':
				loadfile = argu[0]
			elif arg == 'algorithm':
				algorithm.append(argu[0])
			elif arg == 'epsilon':
				epsilon.append(argu[0])
			elif arg == 'threshold':
				threshold.append(argu[0])
			elif arg == 'locBudget':
				locBudget = argu[0]
			elif arg == 'time_budget':
				time_budget = argu[0]
			else:
				continue
			if linenum == 0:
				status = 0

print(parameters)
for ph in phi_str:
	for cp in controlpoints:
		for opt in optimization:
			for alg in algorithm:
				for eps_i in range(len(epsilon)):
					property = ph.split(';')
					filename = 'bound_' + model+ '_' + alg + '_' + property[0] + '_' + epsilon[eps_i] + '_' + threshold[eps_i]
					param = '\n'.join(parameters)
					with open('benchmarks/'+filename,'w') as bm:
						bm.write('#!/bin/sh\n')
						bm.write('csv=$1\n')
						bm.write(matlab + ' -nodesktop -nosplash <<EOF\n')
						bm.write('clear;\n')
						for ap in addpath:
							bm.write('addpath(genpath(\'' + ap + '\'));\n')
						if loadfile!= '':
							bm.write('load ' + loadfile + '\n')
						bm.write('InitBreach;\n\n')
						bm.write(param + '\n')
						bm.write('mdl = \''+ model + '\';\n')
						bm.write('Br = BreachSimulinkSystem(mdl);\n')
						bm.write('Br.Sys.tspan ='+ timespan +';\n')
						bm.write('input_gen.type = \'UniStep\';\n') 				
						bm.write('input_gen.cp = '+ str(cp) + ';\n')
						bm.write('Br.SetInputGen(input_gen);\n')
						bm.write('for cpi = 0:input_gen.cp -1\n')
						for i in range(len(input_name)):
							bm.write('\t' + input_name[i] + '_sig = strcat(\''+input_name[i]+'_u\',num2str(cpi));\n')
							bm.write('\tBr.SetParamRanges({'+input_name[i] + '_sig},[' +str(input_range[i][0])+' '+str(input_range[i][1]) + ']);\n')
			
						bm.write('end\n')
						bm.write('spec = \''+ property[1]+'\';\n')
						bm.write('phi = STL_Formula(\'phi\',spec);\n')
		
						bm.write('trials = ' + trials + ';\n')	
						bm.write('filename = \'bound_' + filename+'\';\n')

						bm.write('epsilonL = 0;\n')
						bm.write('epsilonU =' + epsilon[eps_i] + ';\n')
						bm.write('Ls = [0];\n')
						bm.write('Us = [' + epsilon[eps_i] + '];\n')
						bm.write('Times = [0];\n')

						if alg == 'Random':
							bm.write('locBudget = '+ locBudget + ';\n')
		
						bm.write('threshold = ' + threshold[eps_i] + ';\n')
						bm.write('time_budget = ' + time_budget + ';\n')
						bm.write('end_flag = false;\n')
						bm.write('tic\n')
						bm.write('while true\n')
						bm.write('\tfalsif_flag = false;\n')
						bm.write('\tepsilon = (epsilonL + epsilonU)/2;\n')


						bm.write('\tfor n = 1:trials\n')
						if alg == 'Random':
							bm.write('\t\tfalsif_pb = RandomProblem(Br,phi,epsilon,threshold,locBudget);\n')
						elif alg == 'TwoInput':
							bm.write('\t\tfalsif_pb = TwoInputProblem(Br, phi,epsilon,threshold);\n')
						elif alg == 'InputEpsilon1':
							bm.write('\t\tfalsif_pb = InputEpsilonProblem(Br, phi,epsilon,threshold, 1);\n')
						elif alg == 'InputEpsilon2':
							bm.write('\t\tfalsif_pb = InputEpsilonProblem(Br, phi,epsilon,threshold, 2);\n')
						elif alg == 'DPTwoInput':
							bm.write('\t\tfalsif_pb = DPTwoInputProblem(Br, phi, epsilon, threshold);\n')
						elif alg == 'DPInputEpsilon':
							bm.write('\t\tfalsif_pb = DPInputEpsilonProblem(Br, phi, epsilon, threshold);\n')
						else:
							print("algorithm is wrong!")

						if timeout!='':
							bm.write('\t\tfalsif_pb.max_time = '+ timeout + ';\n')
						if max_sim!='':
							bm.write('\t\tfalsif_pb.max_obj_eval = ' + max_sim + ';\n')
						bm.write('\t\tfalsif_pb.setup_solver(\''+ opt  +'\');\n')
						bm.write('\t\tfalsif_pb.solve();\n')
						bm.write('\t\ttime = toc;\n')
						bm.write('\t\tTimes = [Times;time];\n')
						bm.write('\t\tif time > time_budget\n')
						bm.write('\t\t\tend_flag = true;\n')
						bm.write('\t\t\tbreak;\n')
						bm.write('\t\tend\n')


						bm.write('\t\tif falsif_pb.falsified == true\n')
						bm.write('\t\t\tfalsif_flag = true;\n')
						bm.write('\t\t\tepsilonU = epsilon;\n')
						bm.write('\t\t\tLs = [Ls; epsilonL];\n')
						bm.write('\t\t\tUs = [Us; epsilonU];\n')
						bm.write('\t\t\tbreak;\n')
						bm.write('\t\tend\n')
						bm.write('\tend\n')
						bm.write('\tif end_flag\n')
						bm.write('\t\tbreak;\n')
						bm.write('\tend\n')
						bm.write('\tif ~falsif_flag\n')
						bm.write('\t\tepsilonL = epsilon;\n')
						bm.write('\t\tLs = [Ls; epsilonL];\n')
						bm.write('\t\tUs = [Us; epsilonU];\n')
						bm.write('\tend\n')
						bm.write('end\n')

	


						bm.write('result = table(Times, Ls, Us);\n')
				
						bm.write('writetable(result,\'$csv\',\'Delimiter\',\';\');\n')
						bm.write('quit force\n')
						bm.write('EOF\n')
						os.chmod('benchmarks/' + filename, 0o777)
