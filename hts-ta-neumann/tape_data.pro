// ---- Geometry parameters ----
DefineConstant[
R_inf = {0.06, Name "Input/1Geometry/Outer radius (m)", Closed 1}, // Outer shell radius [m]
R_air = {0.04, Max R_inf, Name "Input/1Geometry/Inner radius (m)"}, // Inner shell radius [m]
W_tape = {12e-3, Max R_air/2, Name "Input/1Geometry/Cylinder diameter (m)"}, // Width of the tape [m]
H_tape = {1e-6, Max R_air/2, Name "Input/1Geometry/Bottom cylinder height (m)"}, // Height of the tape [m]
meshLayerWidthTape = {0.001} // Width of the control mesh layer around the cylinder
];

// ---- Mesh parameters ----
DefineConstant [meshMult = {4, Name "Input/2Mesh/1Mesh size multiplier (-)"}]; // Multiplier [-] of a default mesh size distribution
DefineConstant [elementMult = 10];

numElementsTape = Floor[elementMult*0.1*200/meshMult];
N_ele = 1; // Number of virtual elemnets in the h_phi_ts_formulation
Delta = H_tape/(N_ele); // Virtual elements size

// ---- Constant definition for regions ----
AIR = 1000;
AIR_OUT = 2000;
SURF_SHELL = 3000;
SHELL = 4000;
SHELL_DOWN = 5000;
SHELL_UP = 6000;
CUT = 9000;
ARBITRARY_POINT = 11000;
EDGE_1 = 11001;
EDGE_2 = 11002;
SURF_SYM = 13000;
SURF_SYM_MAT = 13500;
SURF_OUT = 14000000;
MATERIAL = 23000;
BND_MATERIAL = 25000;
BND_MATERIAL_SIDE = 26000;
THICK_CUT = SURF_OUT+1; // Fix me! It will be different depending on the other physical IDs
// Número de fitas no stack (usa tags MATERIAL_/EDGE_ até 10)
DefineConstant[
numTapes = {3, Min 1, Max 10, Step 1, Name "Input/1Geometry/Number of tapes"}
];
// Tags para fitas independentes (buffer até 10 fitas)
MATERIAL_1 = 3001; 
MATERIAL_2 = 3002;
MATERIAL_3 = 3003;
MATERIAL_4 = 3004;
MATERIAL_5 = 3005;
MATERIAL_6 = 3006;
MATERIAL_7 = 3007;
MATERIAL_8 = 3008;
MATERIAL_9 = 3009;
MATERIAL_10 = 3010;
EDGE_1_1 = 3101; 
EDGE_1_2 = 3102;
EDGE_1_3 = 3103;
EDGE_1_4 = 3104;
EDGE_1_5 = 3105;
EDGE_1_6 = 3106;
EDGE_1_7 = 3107;
EDGE_1_8 = 3108;
EDGE_1_9 = 3109;
EDGE_1_10 = 3110;
EDGE_2_1 = 3201; 
EDGE_2_2 = 3202;
EDGE_2_3 = 3203;
EDGE_2_4 = 3204;
EDGE_2_5 = 3205;
EDGE_2_6 = 3206;
EDGE_2_7 = 3207;
EDGE_2_8 = 3208;
EDGE_2_9 = 3209;
EDGE_2_10 = 3210;
