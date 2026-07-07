Include "tape_data.pro";

// ====================================================================
// 1. CÁLCULO DINÂMICO DO RAIO DE AR
// ====================================================================
Include "coordenadas.geo"; 
W_block = 4e-3; H_block = 1050e-6;
dist_canto = Sqrt((W_block/2)^2 + (H_block/2)^2);

R_max = 0;
For b In {0 : #Lista_X[]-1}
  dist_bloco = Sqrt(Lista_X[b]^2 + Lista_Y[b]^2) + dist_canto;
  If(dist_bloco > R_max) R_max = dist_bloco; EndIf
EndFor
R_inf = R_max * 1.2; 

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
// MACRO
// ====================================================================
Macro CriarBloco
  p_b1 = newp; Point(p_b1) = {X_c - W_block/2, Y_c - H_block/2, 0, LcInf};
  p_b2 = newp; Point(p_b2) = {X_c + W_block/2, Y_c - H_block/2, 0, LcInf};
  p_b3 = newp; Point(p_b3) = {X_c + W_block/2, Y_c + H_block/2, 0, LcInf};
  p_b4 = newp; Point(p_b4) = {X_c - W_block/2, Y_c + H_block/2, 0, LcInf};
  Line(newl) = {p_b1, p_b2}; Line(newl) = {p_b2, p_b3};
  Line(newl) = {p_b3, p_b4}; Line(newl) = {p_b4, p_b1};

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

// Geração
For b In {0 : #Lista_X[]-1}
  X_c = Lista_X[b];
  Y_c = Lista_Y[b];
  Call CriarBloco;
EndFor

// ====================================================================
// ORGANIZAÇÃO DOS GRUPOS (Substitui o slicing inválido)
// ====================================================================
Mat1[] = {}; Mat2[] = {}; Mat3[] = {}; Mat4[] = {};
E1_1[] = {}; E1_2[] = {}; E1_3[] = {}; E1_4[] = {};
E2_1[] = {}; E2_2[] = {}; E2_3[] = {}; E2_4[] = {};

For k In {0 : #linhasTapes[]-1}
  mod = k % 4;
  If(mod == 0) Mat1[] += {linhasTapes[k]}; E1_1[] += {pontosEsquerda[k]}; E2_1[] += {pontosDireita[k]}; EndIf
  If(mod == 1) Mat2[] += {linhasTapes[k]}; E1_2[] += {pontosEsquerda[k]}; E2_2[] += {pontosDireita[k]}; EndIf
  If(mod == 2) Mat3[] += {linhasTapes[k]}; E1_3[] += {pontosEsquerda[k]}; E2_3[] += {pontosDireita[k]}; EndIf
  If(mod == 3) Mat4[] += {linhasTapes[k]}; E1_4[] += {pontosEsquerda[k]}; E2_4[] += {pontosDireita[k]}; EndIf
EndFor

// ====================================================================
// GEOMETRIA GLOBAL E FÍSICA
// ====================================================================
Line Loop(30) = {2, 4, 6, 8};
// Linhas Dirichlet (use newl para evitar erro de tag)
l_sx = newl; Line(l_sx) = {100, 8}; // Eixo X positivo
l_sy = newl; Line(l_sy) = {100, 6}; // Eixo Y positivo
// Nota: Defina SYMM_X e SYMM_Y em tape_data.pro se ainda não estiverem lá
Physical Line("SYMM_X", 13001) = {l_sx};
Physical Line("SYMM_Y", 13002) = {l_sy};

Plane Surface(2) = {30};
Curve{linhasTapes[]} In Surface{2};

Physical Surface("Air", AIR) = {2};
Physical Line("Exterior boundary", SURF_OUT) = {2, 4, 6, 8};

Physical Line("Conducting domain 1", MATERIAL_1) = {Mat1[]};
Physical Line("Conducting domain 2", MATERIAL_2) = {Mat2[]};
Physical Line("Conducting domain 3", MATERIAL_3) = {Mat3[]};
Physical Line("Conducting domain 4", MATERIAL_4) = {Mat4[]};
Physical Line("Conducting domain boundary", BND_MATERIAL) = {linhasTapes[]};

Physical Point("Left edge 1", EDGE_1_1) = {E1_1[]};
Physical Point("Left edge 2", EDGE_1_2) = {E1_2[]};
Physical Point("Left edge 3", EDGE_1_3) = {E1_3[]};
Physical Point("Left edge 4", EDGE_1_4) = {E1_4[]};

Physical Point("Right edge 1", EDGE_2_1) = {E2_1[]};
Physical Point("Right edge 2", EDGE_2_2) = {E2_2[]};
Physical Point("Right edge 3", EDGE_2_3) = {E2_3[]};
Physical Point("Right edge 4", EDGE_2_4) = {E2_4[]};

Hide { Point{ Point '*' }; }
Cohomology(1) {{AIR}, {}};