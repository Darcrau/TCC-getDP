Include "tape_data.pro";

R = W_tape/2; // Radius

DefineConstant [LcTape = 2*R/numElementsTape]; // Mesh size in cylinder [m]
DefineConstant [LcLayer = LcTape*2]; // Mesh size in the region close to the cylinder [m]
DefineConstant [LcAir = meshMult*0.001*3]; // Mesh size in air shell [m]
DefineConstant [LcInf = meshMult*0.001*3]; // Mesh size in external air shell [m]

// Shells definition
Point(100) = {0, 0, 0, LcTape};
Point(2) = {0, -R_inf, 0, LcInf};
Point(4) = {R_inf, 0, 0, LcInf};
Point(6) = {0, R_inf, 0, LcInf};
Point(8) = {-R_inf, 0, 0, LcInf};
Circle(2) = {2, 100, 4};
Circle(4) = {4, 100, 6};
Circle(6) = {6, 100, 8};
Circle(8) = {8, 100, 2};

numTapes = 4; 

// Array para armazenar os IDs das linhas das tapes
linhasTapes[] = {};
offset = 200; // Offset para evitar conflitos

// Arrays para armazenar os pontos das extremidades das tapes
pontosEsquerda[] = {};
pontosDireita[] = {};

// ====================================================================
// GEOMETRIA DO BLOCO VISUAL (NÃO FÍSICO)
// ====================================================================
// Largura: 4 mm (4e-3 m)
// Altura total: 600 um + 450 um = 1050 um (1050e-6 m)
W_block = 4e-3;
H_block = 1050e-6;

// Para posicionar o bloco pelo baricentro em (0,0), deslocamos
// os pontos para baixo pela metade da altura (525 um).
p_b1 = newp; Point(p_b1) = {-W_block/2, -H_block/2, 0, LcInf};
p_b2 = newp; Point(p_b2) = { W_block/2, -H_block/2, 0, LcInf};
p_b3 = newp; Point(p_b3) = { W_block/2,  H_block/2, 0, LcInf};
p_b4 = newp; Point(p_b4) = {-W_block/2,  H_block/2, 0, LcInf};

l_b1 = newl; Line(l_b1) = {p_b1, p_b2};
l_b2 = newl; Line(l_b2) = {p_b2, p_b3};
l_b3 = newl; Line(l_b3) = {p_b3, p_b4};
l_b4 = newl; Line(l_b4) = {p_b4, p_b1};
linhasBloco[] = {l_b1, l_b2, l_b3, l_b4};
// Obs: As linhas do bloco não entram em nenhum Physical Line

// ====================================================================
// POSICIONAMENTO DAS FITAS (RELATIVO AO BARICENTRO)
// ====================================================================
// Alturas originais (relativas à base do bloco em Y=0):
// Fita 1: 150 + 75 = 225 um
// Fita 2: 225 + 150 = 375 um
// Fita 3: 375 + 300 = 675 um
// Fita 4: 675 + 150 = 825 um
//
// Subtraindo o centro geométrico do bloco (525 um):
yOffsets[] = {
  (225e-6 - 525e-6), // Fita 1 (-300 um)
  (375e-6 - 525e-6), // Fita 2 (-150 um)
  (675e-6 - 525e-6), // Fita 3 ( 150 um)
  (825e-6 - 525e-6)  // Fita 4 ( 300 um)
};

For i In {0:numTapes-1}
  yOffset = yOffsets[i]; 
  
  p1 = offset + i*2;
  p2 = offset+1 + i*2;
  l = newl;
  
  Point(p1) = {-R, yOffset, 0, LcTape};
  Point(p2) = { R, yOffset, 0, LcTape};
  Line(l) = {p1, p2};
  
  Transfinite Line(l) = numElementsTape Using Progression 1;
  linhasTapes[] += {l}; 
  pontosEsquerda[] += {p1};
  pontosDireita[] += {p2};
EndFor

Line Loop(30) = {2, 4, 6, 8}; // Outer boundary
Plane Surface(2) = {30};

// Incrusta apenas as fitas condutoras na malha de ar
Curve{linhasTapes[]} In Surface{2};

Physical Surface("Air", AIR) = {2};
Physical Line("Exterior boundary", SURF_OUT) = {2, 4, 6, 8};

// --- DEFINIÇÃO DOS DOMÍNIOS CONDUTORES ---
Physical Line("Conducting domain 1", MATERIAL_1) = {linhasTapes[0]};
Physical Line("Conducting domain 2", MATERIAL_2) = {linhasTapes[1]};
Physical Line("Conducting domain 3", MATERIAL_3) = {linhasTapes[2]};
Physical Line("Conducting domain 4", MATERIAL_4) = {linhasTapes[3]};

Physical Line("Conducting domain boundary", BND_MATERIAL) = {linhasTapes[]};

Physical Point("Left edge 1", EDGE_1_1) = {pontosEsquerda[0]};
Physical Point("Left edge 2", EDGE_1_2) = {pontosEsquerda[1]};
Physical Point("Left edge 3", EDGE_1_3) = {pontosEsquerda[2]};
Physical Point("Left edge 4", EDGE_1_4) = {pontosEsquerda[3]};

Physical Point("Right edge 1", EDGE_2_1) = {pontosDireita[0]};
Physical Point("Right edge 2", EDGE_2_2) = {pontosDireita[1]};
Physical Point("Right edge 3", EDGE_2_3) = {pontosDireita[2]};
Physical Point("Right edge 4", EDGE_2_4) = {pontosDireita[3]};

Physical Point("Arbitrary Point", ARBITRARY_POINT) = {2};

// Empty regions
Physical Surface("Spherical shell", AIR_OUT) = {};
Physical Line("Symmetry line", SURF_SYM) = {};
Physical Line("Shells common line", SURF_SHELL) = {};
Physical Line("Symmetry line material", SURF_SYM_MAT) = {};
Physical Line("Cut", CUT) = {};
Physical Line("Positive side of bnds", BND_MATERIAL_SIDE) = {};

Color Blue {Surface{2};}
Hide { Point{ Point '*' }; }

Cohomology(1) {{AIR}, {}};