// ============================================================================
// racetrack.geo
// Gmsh geometry for a 4-turn racetrack coil cross-section.
//
// Layout (2-D cross-section, x-y plane):
//
//   Left bundle (-separation)    Right bundle (+separation)
//   L4 ──────────────            ──────────────  R4   y = 3*tapeSpacing
//   L3 ──────────────            ──────────────  R3   y = 2*tapeSpacing
//   L2 ──────────────            ──────────────  R2   y =   tapeSpacing
//   L1 ──────────────            ──────────────  R1   y = 0
//
// Each tape is a 1D line in the T-A formulation.
// Right-side tapes carry +In(t); left-side tapes carry -In(t) (return path).
// Currents are phase-shifted by 2π/4 = π/2 between turns → traveling wave.
// ============================================================================

Include "racetrack_data.pro";

R = W_tape / 2; // Half-width of one tape [m]

DefineConstant [LcTape = 2*R / numElementsTape]; // Fine mesh on the tape lines
DefineConstant [LcAir  = meshMult * 0.001 * 3];  // Coarser mesh in air
DefineConstant [LcInf  = meshMult * 0.001 * 3];  // Mesh at outer boundary

// ============================================================================
// Circular air domain
// ============================================================================
Point(100) = {0,      0,      0, LcTape};
Point(2)   = {0,      -R_inf, 0, LcInf};
Point(4)   = {R_inf,  0,      0, LcInf};
Point(6)   = {0,      R_inf,  0, LcInf};
Point(8)   = {-R_inf, 0,      0, LcInf};

Circle(2) = {2, 100, 4};
Circle(4) = {4, 100, 6};
Circle(6) = {6, 100, 8};
Circle(8) = {8, 100, 2};

// ============================================================================
// Right-side tapes  (x-centre = +separation)
// Point numbering: 200-207 (2 points per turn)
// Line numbering:  10-13
// ============================================================================

// Turn 1  (y = 0)
Point(200) = {separation - R,  0,               0, LcTape};
Point(201) = {separation + R,  0,               0, LcTape};
Line(10) = {200, 201};
Transfinite Line(10) = numElementsTape Using Progression 1;

// Turn 2  (y = tapeSpacing)
Point(202) = {separation - R,  tapeSpacing,     0, LcTape};
Point(203) = {separation + R,  tapeSpacing,     0, LcTape};
Line(11) = {202, 203};
Transfinite Line(11) = numElementsTape Using Progression 1;

// Turn 3  (y = 2*tapeSpacing)
Point(204) = {separation - R,  2*tapeSpacing,   0, LcTape};
Point(205) = {separation + R,  2*tapeSpacing,   0, LcTape};
Line(12) = {204, 205};
Transfinite Line(12) = numElementsTape Using Progression 1;

// Turn 4  (y = 3*tapeSpacing)
Point(206) = {separation - R,  3*tapeSpacing,   0, LcTape};
Point(207) = {separation + R,  3*tapeSpacing,   0, LcTape};
Line(13) = {206, 207};
Transfinite Line(13) = numElementsTape Using Progression 1;

// ============================================================================
// Left-side tapes  (x-centre = -separation)
// Point numbering: 210-217
// Line numbering:  14-17
// ============================================================================

// Turn 1  (y = 0)
Point(210) = {-separation - R, 0,               0, LcTape};
Point(211) = {-separation + R, 0,               0, LcTape};
Line(14) = {210, 211};
Transfinite Line(14) = numElementsTape Using Progression 1;

// Turn 2  (y = tapeSpacing)
Point(212) = {-separation - R, tapeSpacing,     0, LcTape};
Point(213) = {-separation + R, tapeSpacing,     0, LcTape};
Line(15) = {212, 213};
Transfinite Line(15) = numElementsTape Using Progression 1;

// Turn 3  (y = 2*tapeSpacing)
Point(214) = {-separation - R, 2*tapeSpacing,   0, LcTape};
Point(215) = {-separation + R, 2*tapeSpacing,   0, LcTape};
Line(16) = {214, 215};
Transfinite Line(16) = numElementsTape Using Progression 1;

// Turn 4  (y = 3*tapeSpacing)
Point(216) = {-separation - R, 3*tapeSpacing,   0, LcTape};
Point(217) = {-separation + R, 3*tapeSpacing,   0, LcTape};
Line(17) = {216, 217};
Transfinite Line(17) = numElementsTape Using Progression 1;

// ============================================================================
// Surface and Physical groups
// ============================================================================
allTapeLines[] = {10, 11, 12, 13, 14, 15, 16, 17};

Line Loop(30) = {2, 4, 6, 8};
Plane Surface(2) = {30};
Curve{allTapeLines[]} In Surface{2};

Physical Surface("Air",                  AIR)          = {2};
Physical Line("Exterior boundary",       SURF_OUT)     = {2, 4, 6, 8};
Physical Line("Conducting domain",       MATERIAL)     = {allTapeLines[]};
Physical Line("Conducting domain bnd",   BND_MATERIAL) = {allTapeLines[]};

// --- Right-side tape edge points ---
Physical Point("Right tape 1 – left edge",  EDGE_1_R1) = {200};
Physical Point("Right tape 1 – right edge", EDGE_2_R1) = {201};
Physical Point("Right tape 2 – left edge",  EDGE_1_R2) = {202};
Physical Point("Right tape 2 – right edge", EDGE_2_R2) = {203};
Physical Point("Right tape 3 – left edge",  EDGE_1_R3) = {204};
Physical Point("Right tape 3 – right edge", EDGE_2_R3) = {205};
Physical Point("Right tape 4 – left edge",  EDGE_1_R4) = {206};
Physical Point("Right tape 4 – right edge", EDGE_2_R4) = {207};

// --- Left-side tape edge points ---
Physical Point("Left tape 1 – left edge",  EDGE_1_L1) = {210};
Physical Point("Left tape 1 – right edge", EDGE_2_L1) = {211};
Physical Point("Left tape 2 – left edge",  EDGE_1_L2) = {212};
Physical Point("Left tape 2 – right edge", EDGE_2_L2) = {213};
Physical Point("Left tape 3 – left edge",  EDGE_1_L3) = {214};
Physical Point("Left tape 3 – right edge", EDGE_2_L3) = {215};
Physical Point("Left tape 4 – left edge",  EDGE_1_L4) = {216};
Physical Point("Left tape 4 – right edge", EDGE_2_L4) = {217};

Physical Point("Arbitrary Point", ARBITRARY_POINT) = {2};

// Empty regions required by the formulation
Physical Surface("Spherical shell",          AIR_OUT)          = {};
Physical Line("Symmetry line",               SURF_SYM)         = {};
Physical Line("Shells common line",          SURF_SHELL)        = {};
Physical Line("Symmetry line material",      SURF_SYM_MAT)     = {};
Physical Line("Cut",                         CUT)               = {};
Physical Line("Positive side of bnds",       BND_MATERIAL_SIDE) = {};

Color Blue {Surface{2};}
Hide { Point{ Point '*' }; }

// Cohomology solver generates the thick-cut basis representative (id = THICK_CUT)
Cohomology(1) {{AIR}, {}};
