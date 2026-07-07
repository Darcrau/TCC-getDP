Include "tape_data.pro";

// ====================================================================
// 1. CÁLCULO DINÂMICO DO RAIO DE AR (R_inf)
// O círculo de ar precisa envolver todos os blocos definidos em coordenadas.geo
// ====================================================================
Include "coordenadas.geo"; 
W_block = 4e-3; H_block = 1050e-6;
dist_canto = Sqrt((W_block/2)^2 + (H_block/2)^2);

R_max = 0;
For b In {0 : #Lista_X[]-1}
  dist_bloco = Sqrt(Lista_X[b]^2 + Lista_Y[b]^2) + dist_canto;
  If(dist_bloco > R_max) R_max = dist_bloco; EndIf
EndFor
R_inf = R_max * 1.2; // Margem de segurança de 20%

// ====================================================================
// 2. GEOMETRIA BASE
// ====================================================================
R = W_tape/2;
DefineConstant [LcTape = 2*R/numElementsTape]; 
DefineConstant [LcInf = meshMult*0.001*3]; 

Point(100) = {0, 0, 0, LcTape};
Point(2) = {0, -R_inf, 0, LcInf};
Point(4) = {R_inf, 0, 0, LcInf};
Point(6) = {0, R_inf, 0, LcInf};
Point(8) = {-R_inf, 0, 0, LcInf};
Circle(2) = {2, 100, 4}; Circle(4) = {4, 100, 6};
Circle(6) = {6, 100, 8}; Circle(8) = {8, 100, 2};

yOffsets[] = { -300e-6, -150e-6, 150e-6, 300e-6 };
linhasTapes[] = {};
pontosEsquerda[] = {};
pontosDireita[] = {};

// ====================================================================
// MACRO: CRIAR BLOCO EM (X_c, Y_c)
// ====================================================================
Macro CriarBloco
  // Desenha Retângulo Visual (Sem Physical Group)
  p_b1 = newp; Point(p_b1) = {X_c - W_block/2, Y_c - H_block/2, 0, LcInf};
  p_b2 = newp; Point(p_b2) = {X_c + W_block/2, Y_c - H_block/2, 0, LcInf};
  p_b3 = newp; Point(p_b3) = {X_c + W_block/2, Y_c + H_block/2, 0, LcInf};
  p_b4 = newp; Point(p_b4) = {X_c - W_block/2, Y_c + H_block/2, 0, LcInf};
  Line(newl) = {p_b1, p_b2}; Line(newl) = {p_b2, p_b3};
  Line(newl) = {p_b3, p_b4}; Line(newl) = {p_b4, p_b1};

  // Desenha 4 Fitas
  For i In {0:3}
    yOffset = Y_c + yOffsets[i]; 
    p1 = newp; Point(p1) = {X_c - R, yOffset, 0, LcTape};
    p2 = newp; Point(p2) = {X_c + R, yOffset, 0, LcTape};
    l = newl; Line(l) = {p1, p2};
    Transfinite Line(l) = numElementsTape Using Progression 1;
    linhasTapes[] += {l}; 
    pontosEsquerda[] += {p1};
    pontosDireita[] += {p2};
  EndFor
Return

// ====================================================================
// GERAÇÃO EM MASSA
// ====================================================================
For b In {0 : #Lista_X[]-1}
  X_c = Lista_X[b];
  Y_c = Lista_Y[b];
  Call CriarBloco;
EndFor

// ====================================================================
// GEOMETRIA GLOBAL E FÍSICA
// ====================================================================
Line Loop(30) = {2, 4, 6, 8};
Plane Surface(2) = {30};
Curve{linhasTapes[]} In Surface{2};

Physical Surface("Air", AIR) = {2};
Physical Line("Exterior boundary", SURF_OUT) = {2, 4, 6, 8};

// Agrupamento Automático por tipo de fita
Physical Line("Conducting domain 1", MATERIAL_1) = {linhasTapes[0 : #linhasTapes[]-1 : 4]};
Physical Line("Conducting domain 2", MATERIAL_2) = {linhasTapes[1 : #linhasTapes[]-1 : 4]};
Physical Line("Conducting domain 3", MATERIAL_3) = {linhasTapes[2 : #linhasTapes[]-1 : 4]};
Physical Line("Conducting domain 4", MATERIAL_4) = {linhasTapes[3 : #linhasTapes[]-1 : 4]};

Physical Line("Conducting domain boundary", BND_MATERIAL) = {linhasTapes[]};

// Agrupamento das bordas para o circuito
Physical Point("Left edge 1", EDGE_1_1) = {pontosEsquerda[0 : #pontosEsquerda[]-1 : 4]};
Physical Point("Left edge 2", EDGE_1_2) = {pontosEsquerda[1 : #pontosEsquerda[]-1 : 4]};
Physical Point("Left edge 3", EDGE_1_3) = {pontosEsquerda[2 : #pontosEsquerda[]-1 : 4]};
Physical Point("Left edge 4", EDGE_1_4) = {pontosEsquerda[3 : #pontosEsquerda[]-1 : 4]};

Physical Point("Right edge 1", EDGE_2_1) = {pontosDireita[0 : #pontosDireita[]-1 : 4]};
Physical Point("Right edge 2", EDGE_2_2) = {pontosDireita[1] : #pontosDireita[]-1 : 4};
Physical Point("Right edge 3", EDGE_2_3) = {pontosDireita[2] : #pontosDireita[]-1 : 4};
Physical Point("Right edge 4", EDGE_2_4) = {pontosDireita[3] : #pontosDireita[]-1 : 4};

Hide { Point{ Point '*' }; }
Cohomology(1) {{AIR}, {}};