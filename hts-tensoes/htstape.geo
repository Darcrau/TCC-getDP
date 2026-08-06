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
R_inf = R_max * 2; 

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
  p_b1 = newp; Point(p_b1) = {X_c - W_block/2, Y_c - H_block/2, 0, LcTape*3};
  p_b2 = newp; Point(p_b2) = {X_c + W_block/2, Y_c - H_block/2, 0, LcTape*3};
  p_b3 = newp; Point(p_b3) = {X_c + W_block/2, Y_c + H_block/2, 0, LcTape*3};
  p_b4 = newp; Point(p_b4) = {X_c - W_block/2, Y_c + H_block/2, 0, LcTape*3};
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
// GEOMETRIA GLOBAL E FÍSICA AUTOMATIZADA (144 FITAS INDEPENDENTES)
// ====================================================================
l_sx = newl; Line(l_sx) = {100, 8};
l_sy = newl; Line(l_sy) = {100, 6};
Line Loop(30) = {l_sy, 6, -l_sx};
Physical Line("SYMM_X", 13001) = {l_sx};
Physical Line("SYMM_Y", 13002) = {l_sy};
Physical Line("Symmetry", SURF_SYM) = {l_sx, l_sy};

Plane Surface(2) = {30};
Curve{linhasTapes[]} In Surface{2};

Physical Surface("Air", AIR) = {2};
Physical Line("Exterior boundary", SURF_OUT) = {6};

// Cria uma região física numerada exclusiva para cada uma das 144 linhas
For k In {0 : #linhasTapes[]-1}
  id = k + 1;
  Physical Line(Sprintf("Conducting domain %g", id), 10000 + id) = {linhasTapes[k]};
  Physical Point(Sprintf("Left edge %g", id), 20000 + id) = {pontosEsquerda[k]};
  Physical Point(Sprintf("Right edge %g", id), 30000 + id) = {pontosDireita[k]};
EndFor

Physical Line("Conducting domain boundary", BND_MATERIAL) = {linhasTapes[]};
Cohomology(1) {{AIR}, {}};


// ====================================================================
// CONTROLE DE MALHA — CRESCIMENTO PROGRESSIVO (growth rate)
// ====================================================================
Mesh.Algorithm = 6;
Mesh.CharacteristicLengthFromPoints = 0;
Mesh.CharacteristicLengthExtendFromBoundary = 0;
Mesh.CharacteristicLengthMin = LcTape * 0.5;
Mesh.CharacteristicLengthMax = LcInf;
Mesh.Smoothing = 20;

// --- Distância até as fitas (fonte do crescimento) ---
Field[1] = Distance;
Field[1].CurvesList = {linhasTapes[]};
Field[1].NumPointsPerCurve = 30;

// --- Crescimento LINEAR controlado: Lc = LcTape + taxa * distancia ---
// growthRate ~ 0.15 a 0.30 = malha cresce 15-30% do tamanho por unidade
// de distancia percorrida. Valores menores = crescimento mais suave/lento.
growthRate = 0.2;
Field[2] = MathEval;
Field[2].F = Sprintf("%g + %g*F1", LcTape, growthRate);

// --- Trava o crescimento no valor maximo global (LcInf) ---
Field[3] = Min;
Field[3].FieldsList = {2};

Background Field = 3;