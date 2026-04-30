// ============================================================================
// racetrack.pro
// GetDP problem file for a 4-turn racetrack HTS coil with traveling-wave
// (phase-shifted) current excitation.
//
// Physics:  T-A formulation (2-D, ta_formulation)
// Geometry: 4 right-side tapes + 4 left-side tapes in a circular air domain.
//           Each turn n carries  I_n(t) = Imax·sin(2πft + (n-1)·π/2).
//           The return path (left-side tape of turn n) carries -I_n(t).
//
// Dependencies:
//   racetrack_data.pro          (geometry constants and region IDs)
//   ../hts-ta/commonInformation.pro
//   ../hts-ta/lawsAndFunctions.pro
//   ../hts-ta/jac_int.pro
//   ../hts-ta/formulations.pro
//   ../hts-ta/resolution.pro
// ============================================================================

Include "racetrack_data.pro";
Include "../hts-ta/commonInformation.pro";


// ============================================================================
// Groups
// ============================================================================
Group {
    // --- Output / interface ---
    DefineConstant[onelabInterface = {0, Choices{0,1},
        Name "Input/3Problem/2Show solution during simulation?"}];
    realTimeInfo    = onelabInterface;
    realTimeSolution = onelabInterface;

    // Name used to build the output directory path in resolution.pro:
    //   resDirectory = "../" + name + "/res/"   → resolves to "./res/"
    name     = "racetrack-ta";
    DefineConstant [testname = "test"];

    Dim             = 2;
    Flag_cohomology = 1;
    SourceType      = 0; // Applied current only (no external field)
    formulation     = ta_formulation;
    alt_formulation = 0;
    MaterialType    = 1; // 1 = superconductor

    // --- Domain regions ---
    Air  = Region[ AIR ];
    Air += Region[ AIR_OUT ];

    Cond = Region[ MATERIAL ]; // all 8 HTS tapes
    BndOmegaC     += Region[ BND_MATERIAL ];
    BndOmegaC_side += Region[ BND_MATERIAL_SIDE ];

    If (Flag_cohomology == 0)
        Cuts = Region[ {CUT} ];
    Else
        Cuts = Region[ {THICK_CUT} ];
    EndIf

    Super       += Region[ MATERIAL ];
    IsThereSuper = 1;

    // --- Per-turn edge regions (right side — positive current) ---
    Edge1_R1 = Region[ EDGE_1_R1 ]; Edge2_R1 = Region[ EDGE_2_R1 ];
    Edge1_R2 = Region[ EDGE_1_R2 ]; Edge2_R2 = Region[ EDGE_2_R2 ];
    Edge1_R3 = Region[ EDGE_1_R3 ]; Edge2_R3 = Region[ EDGE_2_R3 ];
    Edge1_R4 = Region[ EDGE_1_R4 ]; Edge2_R4 = Region[ EDGE_2_R4 ];

    // --- Per-turn edge regions (left side — return current) ---
    Edge1_L1 = Region[ EDGE_1_L1 ]; Edge2_L1 = Region[ EDGE_2_L1 ];
    Edge1_L2 = Region[ EDGE_1_L2 ]; Edge2_L2 = Region[ EDGE_2_L2 ];
    Edge1_L3 = Region[ EDGE_1_L3 ]; Edge2_L3 = Region[ EDGE_2_L3 ];
    Edge1_L4 = Region[ EDGE_1_L4 ]; Edge2_L4 = Region[ EDGE_2_L4 ];

    // LateralEdges: all edge points → t = 0 by default (overridden by Current constraint)
    LateralEdges = Region[ {Edge1_R1, Edge2_R1, Edge1_R2, Edge2_R2,
                             Edge1_R3, Edge2_R3, Edge1_R4, Edge2_R4,
                             Edge1_L1, Edge2_L1, Edge1_L2, Edge2_L2,
                             Edge1_L3, Edge2_L3, Edge1_L4, Edge2_L4} ];

    // PositiveEdges: left-edge points of ALL tapes that carry an imposed current.
    // Each physical group here gets its own global DOF (T, V) in the t_space.
    PositiveEdges = Region[ {Edge1_R1, Edge1_R2, Edge1_R3, Edge1_R4,
                              Edge1_L1, Edge1_L2, Edge1_L3, Edge1_L4} ];

    // Convenience aliases used by formulations.pro and post-operations
    Edge1 = Region[ {Edge1_R1, Edge1_R2, Edge1_R3, Edge1_R4,
                     Edge1_L1, Edge1_L2, Edge1_L3, Edge1_L4} ];
    Edge2 = Region[ {Edge2_R1, Edge2_R2, Edge2_R3, Edge2_R4,
                     Edge2_L1, Edge2_L2, Edge2_L3, Edge2_L4} ];

    // --- Formulation domain classification ---
    MagnAnhyDomain = Region[ {} ];
    MagnLinDomain  = Region[ {Air, Super} ];
    NonLinOmegaC   = Region[ {Super} ];
    LinOmegaC      = Region[ {} ];
    OmegaC         = Region[ {LinOmegaC, NonLinOmegaC} ];
    OmegaCC        = Region[ {Air} ];
    Omega          = Region[ {OmegaC, OmegaCC} ];

    ArbitraryPoint = Region[ ARBITRARY_POINT ];

    // --- Boundary conditions ---
    SurfOut  = Region[ SURF_OUT ];
    SurfSym  = Region[ SURF_SYM ];
    Gamma_h  = Region[ {SurfOut} ];
    Gamma_e  = Region[ {SurfSym} ];
    GammaAll = Region[ {Gamma_h, Gamma_e} ];
}


// ============================================================================
// Functions — material parameters and excitation
// ============================================================================
Function {
    // --- Superconductor parameters ---
    Flag_jcb = 1;
    b0 = 0.1; // Kim-model field scale [T]
    DefineConstant [jc = {2.5e10, Name "Input/3Material Properties/2jc (Am⁻²)"}];
    DefineConstant [n  = {25,     Name "Input/3Material Properties/1n (-)"}];

    // --- Ferromagnetic parameters (not used here but required by lawsAndFunctions.pro) ---
    DefineConstant [mur0 = 1700.0];
    DefineConstant [m0   = 1.04e6];

    // --- Excitation ---
    DefineConstant [IFraction = {0.9, Name "Input/4Source/0Fraction of Ic (-)"}];
    DefineConstant [Imax = IFraction * jc * W_tape * H_tape]; // Peak current [A]
    DefineConstant [bmax = 0.0];
    DefineConstant [f    = 50]; // Frequency [Hz]

    DefineConstant [timeStart    = 0];
    DefineConstant [timeFinal    = 1.25 / f];
    DefineConstant [timeFinalSimu = 1.25 / f];

    // --- Traveling-wave phase shifts ---
    // phaseShift = 2π / numTurns = π/2 for 4 turns
    phaseShift = 2 * Pi / 4;

    // Per-turn current functions (right-side tapes, positive current)
    I_1[] = Imax * Sin[2 * Pi * f * $Time + 0 * phaseShift];
    I_2[] = Imax * Sin[2 * Pi * f * $Time + 1 * phaseShift];
    I_3[] = Imax * Sin[2 * Pi * f * $Time + 2 * phaseShift];
    I_4[] = Imax * Sin[2 * Pi * f * $Time + 3 * phaseShift];

    // Generic I[] (for compatibility with resolution.pro output macros)
    I[]    = Imax * Sin[2 * Pi * f * $Time];
    hsVal[] = 0.0;

    // --- Time-stepping ---
    DefineConstant [nbStepsPerPeriod = {240 / meshMult,
        Name "Input/5Method/Number of time step per period (-)"}];
    DefineConstant [dt          = 1 / (nbStepsPerPeriod * f)];
    DefineConstant [writeInterval = dt];
    DefineConstant [dt_max      = dt];
    DefineConstant [iter_max    = {400, Name "Input/5Method/Max number of iterations (-)"}];
    DefineConstant [extrapolationOrder = 2];
    DefineConstant [tol_energy  = {1e-6, Name "Input/5Method/Relative tolerance (-)"}];

    // Control points for line-output post-processing
    // CP1/CP2: horizontal scan across right-side turn 1
    controlPoint1 = {separation - W_tape/2 + 1e-5,  0, 0};
    controlPoint2 = {separation + W_tape/2 - 1e-5,  0, 0};
    // CP3/CP4: vertical scan between the two bundles at mid-height
    controlPoint3 = {0,  1.5 * tapeSpacing, 0};
    controlPoint4 = {separation - W_tape/2, 1.5 * tapeSpacing, 0};
    DefineConstant [savedPoints = 500];
}

Include "../hts-ta/lawsAndFunctions.pro";

Function {
    controlTimeInstants = {timeFinalSimu, 1/(2*f), 1/f, 3/(2*f), 2*timeFinal};

    // Tape thickness for T-A formulation
    thickness[Cond]  = H_tape;
    thickness[Edge1] = H_tape;
    thickness[Air]   = H_tape;

    directionApplied[] = Vector[0., 1., 0.];
}


// ============================================================================
// Constraints
// ============================================================================
Constraint {
    { Name a;
        Case {
            // Zero vector potential on outer boundary (no applied field)
            {Region SurfOut; Value 0.0;}
            {Region SurfSym; Value 0.0;}
        }
    }
    { Name a2; Case {} }
    { Name h;  Case {} }
    { Name j;  Case {} }
    { Name phi;
        Case {
            // Fix scalar potential at one arbitrary point
            {Region ArbitraryPoint; Value 0.0;}
        }
    }

    // Current constraint — T-A formulation
    // Right-side tapes: t(left edge) = +I_n(t)   → j into the page
    // Left-side  tapes: t(left edge) = -I_n(t)   → j out of the page (return)
    { Name Current; Type Assign;
        Case {
            { Region Edge1_R1; Value  1.0; TimeFunction I_1[]; }
            { Region Edge1_R2; Value  1.0; TimeFunction I_2[]; }
            { Region Edge1_R3; Value  1.0; TimeFunction I_3[]; }
            { Region Edge1_R4; Value  1.0; TimeFunction I_4[]; }
            { Region Edge1_L1; Value -1.0; TimeFunction I_1[]; }
            { Region Edge1_L2; Value -1.0; TimeFunction I_2[]; }
            { Region Edge1_L3; Value -1.0; TimeFunction I_3[]; }
            { Region Edge1_L4; Value -1.0; TimeFunction I_4[]; }
        }
    }
    { Name Voltage; Case {} }
}


Include "../hts-ta/jac_int.pro";
Include "../hts-ta/formulations.pro";
Include "../hts-ta/resolution.pro";


// ============================================================================
// Post-operations
// ============================================================================
PostOperation {
    // Runtime monitoring (Onelab graph)
    { Name Info;
        NameOfPostProcessing MagDyn_ta;
        Operation {
            Print[ time[OmegaC], OnRegion OmegaC,
                LastTimeStepOnly, Format Table, SendToServer "Output/0Time [s]"];
            Print[ I_1, OnRegion Edge1_R1,
                LastTimeStepOnly, Format Table, SendToServer "Output/1Current turn 1 [A]"];
            Print[ I_2, OnRegion Edge1_R2,
                LastTimeStepOnly, Format Table, SendToServer "Output/2Current turn 2 [A]"];
            Print[ I_3, OnRegion Edge1_R3,
                LastTimeStepOnly, Format Table, SendToServer "Output/3Current turn 3 [A]"];
            Print[ I_4, OnRegion Edge1_R4,
                LastTimeStepOnly, Format Table, SendToServer "Output/4Current turn 4 [A]"];
        }
    }

    // Field output
    { Name MagDyn; LastTimeStepOnly realTimeSolution;
        NameOfPostProcessing MagDyn_ta;
        Operation {
            If(economPos == 0)
                Print[ a, OnElementsOf Omega,  File "res/a.pos", Name "a [Tm]"];
                Print[ t, OnElementsOf OmegaC, File "res/t.pos", Name "t [Am]"];
                Print[ j, OnElementsOf OmegaC, File "res/j.pos", Name "j [A/m²]"];
                Print[ e, OnElementsOf OmegaC, File "res/e.pos", Name "e [V/m]"];
                Print[ h, OnElementsOf Omega,  File "res/h.pos", Name "h [A/m]"];
                Print[ b, OnElementsOf OmegaCC, File "res/b.pos", Name "b [T]"];
            EndIf
            // Current density along all tapes (time-table for animation)
            Print[ j, OnElementsOf OmegaC, Format TimeTable, File outputCurrent];
            // Magnetic induction scan across right-side bundle (turn 1)
            Print[ b, OnLine{{List[controlPoint1]}{List[controlPoint2]}} {savedPoints},
                Format TimeTable, File outputMagInduction1];
            // Magnetic induction scan between the two bundles (vertical)
            Print[ b, OnLine{{List[controlPoint3]}{List[controlPoint4]}} {savedPoints},
                Format TimeTable, File outputMagInduction2];
        }
    }
}
