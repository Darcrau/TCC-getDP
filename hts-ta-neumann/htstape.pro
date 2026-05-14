Include "tape_data.pro";
Include "commonInformation.pro";


Group {
    // Output choice
    DefineConstant[onelabInterface = {0, Choices{0,1}, Name "Input/3Problem/2Show solution during simulation?"}]; // Set to 0 for launching in terminal (faster)
    realTimeInfo = onelabInterface;
    realTimeSolution = onelabInterface;
    // ------- PROBLEM DEFINITION -------
    // Test name - for output files
    name = "tape";
    // (directory name for .txt files, not .pos files)
    DefineConstant [testname = "test"];
    // Dimension of the problem
    Dim = 2;

    Flag_cohomology = 1;
    // Source:
    //      0 -> applied current only
    //      1 -> applied field only
    //      2 -> applied current + applied field (most realistic)
    SourceType = 0;

// ------- WEAK FORMULATION -------
    // Choice of the formulation
    formulation = ta_formulation;

    alt_formulation = 0;
    // ------- Definition of the physical regions -------
    // Material type of region MATERIAL, 0: air, 1: super, 2: copper, 3: soft ferro
    MaterialType = 1;
    
    // Filling the regions
    Air = Region[ AIR ];
    Air += Region[ AIR_OUT ];
    
    If(MaterialType == 0)
        Air += Region[ {MATERIAL_1, MATERIAL_2} ];
    ElseIf(MaterialType == 1 || MaterialType == 2)
        
        // 1. Definimos as fitas independentes primeiro
        Super1 = Region[ MATERIAL_1 ];
        Super2 = Region[ MATERIAL_2 ];
        Super3 = Region[ MATERIAL_3 ];
        Super = Region[ {Super1, Super2, Super3} ];
        
        // 2. Agora o Condutor geral recebe as fitas
        Cond = Region[ {Super1, Super2, Super3} ];
        
        BndOmegaC += Region[ BND_MATERIAL ];
        BndOmegaC_side += Region[ BND_MATERIAL_SIDE ];
        
        If (Flag_cohomology == 0)
            Cuts = Region[ {CUT} ];
        Else
            Cuts = Region[ {THICK_CUT} ]; // Cohomology basis representatives = thick cuts
        EndIf
        
        If(MaterialType == 1)
            // Super já foi montado acima, apenas ativamos a flag
            IsThereSuper = 1;
        ElseIf(MaterialType == 2)
            Copper += Region[ {MATERIAL_1, MATERIAL_2} ];
        EndIf
        
    ElseIf(MaterialType == 3)
        Ferro += Region[ {MATERIAL_1, MATERIAL_2} ];
        IsThereFerro = 1;
    EndIf

    // Edges of the tape: Separando fisicamente para permitir correntes diferentes
    Edge1_1 = Region[ EDGE_1_1 ]; // Borda + da fita 1
    Edge1_2 = Region[ EDGE_1_2 ]; // Borda + da fita 2
    Edge1_3 = Region[ EDGE_1_3 ]; // Borda + da fita 3
    
    Edge2_1 = Region[ EDGE_2_1 ]; // Borda - da fita 1
    Edge2_2 = Region[ EDGE_2_2 ]; // Borda - da fita 2
    Edge2_3 = Region[ EDGE_2_3 ]; // Borda - da fita 3
    
    // Agrupamentos lógicos para as equações gerais
    Edge1 = Region[ {Edge1_1, Edge1_2, Edge1_3} ];
    Edge2 = Region[ {Edge2_1, Edge2_2, Edge2_3} ];
    
    LateralEdges = Region[ {Edge1, Edge2} ];
    PositiveEdges = Region[ {Edge1_1, Edge1_2, Edge1_3} ];

    // Fill the regions for formulation
    MagnAnhyDomain = Region[ {Ferro} ];
    MagnLinDomain = Region[ {Air, Super, Copper} ];
        NonLinOmegaC = Region[ {Super} ];
    LinOmegaC = Region[ {Copper} ];
    OmegaC = Region[ {LinOmegaC, NonLinOmegaC} ];
    OmegaCC = Region[ {Air, Ferro} ];
    Omega = Region[ {OmegaC, OmegaCC} ];
    ArbitraryPoint = Region[ ARBITRARY_POINT ]; // To fix the potential

    // Boundaries for BC
    SurfOut = Region[ SURF_OUT ];
    SurfSym = Region[ SURF_SYM ];
    Gamma_h = Region[{SurfOut}];
    Gamma_e = Region[{SurfSym}];
    GammaAll = Region[ {Gamma_h, Gamma_e} ];



}



Function{
    // ------- PARAMETERS -------
    // Superconductor parameters
    Flag_jcb = 1;
    b0 = 0.1;
    DefineConstant [jc = {2.5e10, Name "Input/3Material Properties/2jc (Am⁻²)"}]; // Critical current density [A/m2]
    DefineConstant [n = {25, Name "Input/3Material Properties/1n (-)"}]; // Superconductor exponent (n) value [-]
    // Ferromagnetic material parameters
    DefineConstant [mur0 = 1700.0]; // Relative permeability at low fields [-]
    DefineConstant [m0 = 1.04e6]; // Magnetic field at saturation [A/m]

    // Excitation
    DefineConstant [IFraction = {0.9, Name "Input/4Source/0Fraction of max. current intensity (-)"}];
    DefineConstant [Imax = IFraction*jc*W_tape*H_tape]; // Maximum imposed current intensity [A]
    DefineConstant [bmax = 2e2*1e-4];
    DefineConstant [f = 50]; // Frequency of imposed current intensity [Hz]
    DefineConstant [timeStart = 0]; // Initial time [s]
    DefineConstant [timeFinal = 1.25/f]; // Final time for source definition [s]
    DefineConstant [timeFinalSimu = 1.25/f]; // Final time of simulation [s]

    // Numerical parameters
    DefineConstant [nbStepsPerPeriod = {240/meshMult, Name "Input/5Method/Number of time step per period (-)"}]; // Number of time steps over one period [-]
    DefineConstant [dt = 1/(nbStepsPerPeriod*f)]; // Time step (initial if adaptive)[s]
    DefineConstant [writeInterval = dt]; // Time interval between two successive output file saves [s]
    DefineConstant [dt_max = dt]; // Maximum allowed time step [s]
    DefineConstant [iter_max = {400, Name "Input/5Method/Max number of iteration (-)"}]; // Maximum number of nonlinear iterations
    DefineConstant [extrapolationOrder = 2]; // Extrapolation order
    DefineConstant [tol_energy = {1e-6, Name "Input/5Method/Relative tolerance (-)"}]; // Relative tolerance on the energy estimates
    // Control points
    controlPoint1 = {-W_tape/2+1e-5,0, 0}; // CP1
    controlPoint2 = {W_tape/2-1e-5, 0, 0}; // CP2
    controlPoint3 = {0, H_tape/2+2e-3, 0}; // CP3
    controlPoint4 = {W_tape, H_tape/2+2e-3, 0}; // CP4
    DefineConstant [savedPoints = 500]; // Resolution of the line saving postprocessing
}


Include "lawsAndFunctions.pro";


Function{
    // Sine source field
    controlTimeInstants = {timeFinalSimu, 1/(2*f), 1/f, 3/(2*f), 2*timeFinal};
    I[] = Imax * Sin[2.0 * Pi * f * $Time];
    hsVal[] = 1/mu0 * bmax * Sin[2.0 * Pi * f * $Time];
    // For the t-a-formulation
    thickness[Cond] = H_tape;
    thickness[Edge1] = H_tape;
    thickness[Air] = H_tape; // Fix me, doesn't make sense to define it here...

    directionApplied[] = Vector[0., 1., 0.];
}



Constraint {
    { Name a ;
        Case {
            If(SourceType == 0)
                {Region SurfOut ; Value 0.0;}
                {Region SurfSym ; Value 0.0;}
            ElseIf(SourceType == 1)
                {Region SurfOut ; Value -X[] * mu0 ; TimeFunction hsVal[] ;}
            ElseIf(SourceType == 2)
                {Region SurfOut ; Value -X[] * mu0 ; TimeFunction hsVal[] ;}
            EndIf
        }
    }
    { Name a2 ;
        Case {
        }
    }
    { Name h ;
        Case {
        }
    }
    { Name j ;
        Case {
        }
    }
    { Name phi ;
        Case {
            If(SourceType == 0)
                {Region ArbitraryPoint ; Value 0.0;} // If no surf sym (we could have put one here), fix it at one point
            ElseIf(SourceType == 1)
                {Region SurfOut ; Value XYZ[]*directionApplied[] ; TimeFunction hsVal[] ;}
            ElseIf(SourceType == 2)
                {Region SurfOut ; Value XYZ[]*directionApplied[] ; TimeFunction hsVal[] ;}
            EndIf
        }
    }
    // { Name Current ; Type Assign;
    //     Case {
    //             If(SourceType == 0)
    //                 { Region Edge1; Value 1.0; TimeFunction I[]; } // Applied current for I_total
    //             ElseIf(SourceType == 1)
    //                 { Region Edge1; Value 0.0; }
    //             ElseIf(SourceType == 2)
    //                 { Region Edge1; Value 1.0; TimeFunction I[]; } // Current + field (I_total)
    //             EndIf
    //     }
    // }
    // { Name Voltage ; Case { } } // Nothing


}


Include "jac_int.pro";
Include "formulations.pro";
Include "resolution.pro";



PostOperation {
    // Runtime output for graph plot
    { Name Info;
            NameOfPostProcessing MagDyn_ta ;
        Operation{
            Print[ time[OmegaC], OnRegion OmegaC, LastTimeStepOnly, Format Table, SendToServer "Output/0Time [s]"] ;
                Print[ I1, OnRegion Edge1_1, LastTimeStepOnly, Format Table, SendToServer "Output/1Current Tape 1 [A]"] ;
                Print[ I2, OnRegion Edge1_2, LastTimeStepOnly, Format Table, SendToServer "Output/1Current Tape 2 [A]"] ;
                Print[ V, OnRegion PositiveEdges, LastTimeStepOnly, Format Table, SendToServer "Output/2Tension [Vm^-1]"] ;
                Print[ dissPower[OmegaC], OnGlobal, LastTimeStepOnly, Format Table, SendToServer "Output/3Joule loss [W]"] ;
        }
    }
    { Name MagDyn;LastTimeStepOnly realTimeSolution ;
            NameOfPostProcessing MagDyn_ta ;
        Operation {
            If(economPos == 0)
                    Print[ a, OnElementsOf Omega , File "res/a.pos", Name "a [Tm]" ];
                    Print[ t, OnElementsOf OmegaC , File "res/t.pos", Name "t [Am]" ];
                    Print[ t, OnLine{{List[controlPoint1]}{List[controlPoint2]}} {savedPoints},
                        Format TimeTable, File "res/tLine.txt"];
                    Print[ j, OnElementsOf OmegaC , File "res/j.pos", Name "j [A/m2]" ];
                    Print[ e, OnElementsOf OmegaC , File "res/e.pos", Name "e [V/m]" ];

                Print[ h, OnElementsOf Omega , File "res/h.pos", Name "h [A/m]" ];
                    Print[ b, OnElementsOf OmegaCC , File "res/b.pos", Name "b [T]" ];
            EndIf
                Print[ j, OnElementsOf OmegaC, Format TimeTable, File outputCurrent];
                Print[ I1, OnRegion Edge1_1, Format TimeTable, File StrCat[outputDirectory,"/current1.txt"] ];
                Print[ I2, OnRegion Edge1_2, Format TimeTable, File StrCat[outputDirectory,"/current2.txt"] ];
                Print[ I3, OnRegion Edge1_3, Format TimeTable, File StrCat[outputDirectory,"/current3.txt"] ];
            Print[ b, OnLine{{List[controlPoint1]}{List[controlPoint2]}} {savedPoints},
                Format TimeTable, File outputMagInduction1];
            Print[ b, OnLine{{List[controlPoint3]}{List[controlPoint4]}} {savedPoints},
                Format TimeTable, File outputMagInduction2];
            //Print[ hsVal[Omega], OnRegion Omega, Format TimeTable, File outputAppliedField];
        }
    }
}
