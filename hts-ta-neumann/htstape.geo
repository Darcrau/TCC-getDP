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


tapeSpacing = 0.15e-3;
numTapes = 2; // Número total de tapes (inclui a original)

// Array para armazenar os IDs das linhas das tapes
linhasTapes[] = {};
offset = 200; // Offset para os IDs das linhas das tapes (para evitar conflitos com outras linhas)

// Arrays para armazenar os pontos das extremidades das tapes
pontosEsquerda[] = {};
pontosDireita[] = {};



For i In {0:numTapes-1}
  yOffset = i * tapeSpacing;
  p1 = offset + i*2;
  p2 = offset+1 + i*2;
  l = 10 + i;
  Point(p1) = {-R, yOffset, 0, LcTape};
  Point(p2) = { R, yOffset, 0, LcTape};
  Line(l) = {p1, p2};
  Transfinite Line(l) = numElementsTape Using Progression 1;
  linhasTapes[] += {l}; // Adiciona o ID da linha ao array
  pontosEsquerda[] += {p1};
  pontosDireita[] += {p2};
EndFor




Line Loop(30) = {2, 4, 6, 8}; // Outer boundary
Plane Surface(2) = {30};
Curve{linhasTapes[]} In Surface{2};
Physical Surface("Air", AIR) = {2};
Physical Line("Exterior boundary", SURF_OUT) = {2, 4, 6, 8};

Physical Line("Conducting domain 1", MATERIAL_1) = {linhasTapes[0]};
Physical Line("Conducting domain 2", MATERIAL_2) = {linhasTapes[1]};


Physical Line("Conducting domain boundary", BND_MATERIAL) = {linhasTapes[]};



Physical Point("Left edge 1", EDGE_1_1) = {pontosEsquerda[0]};
Physical Point("Left edge 2", EDGE_1_2) = {pontosEsquerda[1]};

Physical Point("Right edge 1", EDGE_2_1) = {pontosDireita[0]};
Physical Point("Right edge 2", EDGE_2_2) = {pontosDireita[1]};




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

