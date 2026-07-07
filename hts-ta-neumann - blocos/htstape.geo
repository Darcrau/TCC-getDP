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

numTapes = 8; // Atualizando o número total de fitas
tapeSpacing = 0.15e-3; // ESPAÇAMENTO FIXO RESTAURADO

// Array para armazenar os IDs das linhas das tapes
linhasTapes[] = {};
offset = 200; // Offset para os IDs das linhas das tapes (para evitar conflitos com outras linhas)

// Arrays para armazenar os pontos das extremidades das tapes
pontosEsquerda[] = {};
pontosDireita[] = {};

/* ====================================================================
   MODELO DE DISTÂNCIAS VARIÁVEIS (COMENTADO PARA USO FUTURO)
   Para usar, remova os comentários e comente o "yOffset" dentro do For.
yOffsets[] = {
  0.0,        // Tape 1: 0
  20e-6,      // Tape 2: 20 um
  60e-6,      // Tape 3: 60 um
  80e-6,      // Tape 4: 80 um
  270e-6,     // Tape 5: 80 um + (40 um + 0.15 mm)
  290e-6,     // Tape 6: Tape 5 + 20 um
  330e-6,     // Tape 7: Tape 6 + 40 um
  350e-6      // Tape 8: Tape 7 + 20 um
};
==================================================================== */

For i In {0:numTapes-1}
  
  // Utiliza o espaçamento fixo entre as fitas
  yOffset = i * tapeSpacing; 
  
  // yOffset = yOffsets[i]; // (Comentado: puxava da lista)
  
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

Physical Line("Conducting domain 4", MATERIAL_4) = {linhasTapes[3]};
Physical Point("Left edge 4", EDGE_1_4) = {pontosEsquerda[3]};
Physical Point("Right edge 4", EDGE_2_4) = {pontosDireita[3]};

Line Loop(30) = {2, 4, 6, 8}; // Outer boundary
Plane Surface(2) = {30};
Curve{linhasTapes[]} In Surface{2};
Physical Surface("Air", AIR) = {2};
Physical Line("Exterior boundary", SURF_OUT) = {2, 4, 6, 8};

Physical Line("Conducting domain 1", MATERIAL_1) = {linhasTapes[0]};
Physical Line("Conducting domain 2", MATERIAL_2) = {linhasTapes[1]};
Physical Line("Conducting domain 3", MATERIAL_3) = {linhasTapes[2]};
Physical Line("Conducting domain 5", MATERIAL_5) = {linhasTapes[4]};
Physical Line("Conducting domain 6", MATERIAL_6) = {linhasTapes[5]};
Physical Line("Conducting domain 7", MATERIAL_7) = {linhasTapes[6]};
Physical Line("Conducting domain 8", MATERIAL_8) = {linhasTapes[7]};

Physical Line("Conducting domain boundary", BND_MATERIAL) = {linhasTapes[]};

Physical Point("Left edge 1", EDGE_1_1) = {pontosEsquerda[0]};
Physical Point("Left edge 2", EDGE_1_2) = {pontosEsquerda[1]};
Physical Point("Left edge 3", EDGE_1_3) = {pontosEsquerda[2]};
Physical Point("Left edge 5", EDGE_1_5) = {pontosEsquerda[4]};
Physical Point("Left edge 6", EDGE_1_6) = {pontosEsquerda[5]};
Physical Point("Left edge 7", EDGE_1_7) = {pontosEsquerda[6]};
Physical Point("Left edge 8", EDGE_1_8) = {pontosEsquerda[7]};

Physical Point("Right edge 1", EDGE_2_1) = {pontosDireita[0]};
Physical Point("Right edge 2", EDGE_2_2) = {pontosDireita[1]};
Physical Point("Right edge 3", EDGE_2_3) = {pontosDireita[2]};
Physical Point("Right edge 5", EDGE_2_5) = {pontosDireita[4]};
Physical Point("Right edge 6", EDGE_2_6) = {pontosDireita[5]};
Physical Point("Right edge 7", EDGE_2_7) = {pontosDireita[6]};
Physical Point("Right edge 8", EDGE_2_8) = {pontosDireita[7]};

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

// ====================================================================
// CONTROLE DE MALHA AVANÇADO (FIELDS) - CORRIGIDO PARA O AR
// ====================================================================

DefineConstant [LcGap = LcTape * 4]; 

// 1. Campo de Distância único (mede a distância até qualquer fita)
Field[1] = Distance;
Field[1].CurvesList = {linhasTapes[]};
Field[1].NumPointsPerCurve = 100; 

// 2. Regra da Microescala (Fitas -> Vão interno)
Field[2] = Threshold;
Field[2].InField = 1; 
Field[2].SizeMin = LcTape; 
Field[2].SizeMax = LcGap;  
Field[2].DistMin = 10e-6; 
Field[2].DistMax = 80e-6; 

// 3. Regra da Macroescala (Entorno -> Ar infinito)
Field[3] = Threshold;
Field[3].InField = 1; 
Field[3].SizeMin = 0;      // Zero perto das fitas para não anular a Regra 2
Field[3].SizeMax = LcInf;  // Cresce até o tamanho máximo da borda
Field[3].DistMin = 200e-6; // Só começa a crescer a 200 um de distância das fitas
Field[3].DistMax = R_inf * 0.5; // Atinge LcInf na metade do caminho para a fronteira

// 4. Combinação (Pega sempre o maior tamanho permitido entre as duas regras)
Field[4] = Max;
Field[4].FieldsList = {2, 3};

// 5. Aplica a regra final
Background Field = 4;
Mesh.CharacteristicLengthExtendFromBoundary = 0;