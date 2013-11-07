all : silly0 silly1 checke0 checke1 MST_blind silly_MSF Prob_Gen

silly0:
	g++ code/silly.cpp -o bin/Original.out -O2 -Wall
checke0 :
	g++ code/checker.cpp -o bin/checker.out -O2 -Wall
silly1 :
	g++ code/silly1.cpp -o bin/RandTree.out -O2 -Wall
checke1 :
	g++ code/checker1.cpp -o bin/checker1.out -O2 -Wall
MST_blind :
	g++ code/MST_blind.cpp -o bin/MST_blind.out -O2 -Wall
silly_MSF :
	g++ code/silly_MSF.cpp -o bin/MSF.out -O2 -Wall
Prob_Gen :
	g++ code/code-probability/prob_data_generator.cpp -o bin/Prob_Gen.out -O2 -Wall
