// ============================================================================
// racetrack_data.pro
// Geometry and mesh parameters for the 4-turn racetrack coil model.
// Each turn has a right-side tape (current into page) and a left-side tape
// (return current, out of page), forming a traveling-wave flux pump geometry.
// ============================================================================

// ---- Geometry parameters ----
DefineConstant[
    R_inf             = {0.06,  Name "Input/1Geometry/Outer radius (m)",    Closed 1}, // Outer air domain radius [m]
    W_tape            = {4e-3,  Name "Input/1Geometry/Tape width (m)"},                // Width of each HTS tape [m]
    H_tape            = {1e-6,  Name "Input/1Geometry/Tape thickness (m)"}, // Effective thickness for T-A formulation [m]
                                                                              // (T-A models tapes as 1D lines; H_tape enters only as a scaling factor
                                                                              //  in the current-density calculation: j = t/H_tape)
    separation        = {0.020, Name "Input/1Geometry/Bundle separation (m)"}, // Distance from origin to tape-bundle centre [m]
    tapeSpacing       = {8e-3,  Name "Input/1Geometry/Tape spacing (m)"},  // Vertical pitch between consecutive turns [m]
    meshLayerWidthTape = {0.001}
];

numTurns = 4; // Number of turns (= number of phase-shifted circuits)

// ---- Mesh parameters ----
DefineConstant [meshMult    = {4,  Name "Input/2Mesh/1Mesh size multiplier (-)"}];
DefineConstant [elementMult = 10];

numElementsTape = Floor[elementMult * 0.1 * 200 / meshMult];
N_ele  = 1;
Delta  = H_tape / N_ele;

// ============================================================================
// Region IDs — must be consistent between .geo and .pro
// ============================================================================
AIR              = 1000;
AIR_OUT          = 2000;
SURF_SHELL       = 3000;
SHELL            = 4000;
SHELL_DOWN       = 5000;
SHELL_UP         = 6000;
CUT              = 9000;
ARBITRARY_POINT  = 11000;
SURF_SYM         = 13000;
SURF_SYM_MAT     = 13500;
SURF_OUT         = 14000000;
MATERIAL         = 23000; // All HTS tapes share one material group
BND_MATERIAL     = 25000;
BND_MATERIAL_SIDE = 26000;
THICK_CUT        = SURF_OUT + 1; // Cohomology-generated thick cut

// --- Right-side tapes (current into page, +z direction) ---
// Turn 1
EDGE_1_R1 = 11010; EDGE_2_R1 = 11011;
// Turn 2
EDGE_1_R2 = 11012; EDGE_2_R2 = 11013;
// Turn 3
EDGE_1_R3 = 11014; EDGE_2_R3 = 11015;
// Turn 4
EDGE_1_R4 = 11016; EDGE_2_R4 = 11017;

// --- Left-side tapes (return current, -z direction) ---
// Turn 1
EDGE_1_L1 = 11020; EDGE_2_L1 = 11021;
// Turn 2
EDGE_1_L2 = 11022; EDGE_2_L2 = 11023;
// Turn 3
EDGE_1_L3 = 11024; EDGE_2_L3 = 11025;
// Turn 4
EDGE_1_L4 = 11026; EDGE_2_L4 = 11027;
