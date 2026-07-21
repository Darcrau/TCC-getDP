Include "tape_data.pro";
Include "commonInformation.pro";

Group {
    // Output choice
    DefineConstant[onelabInterface = {0, Choices{0,1}, Name "Input/3Problem/2Show solution during simulation?"}]; // Set to 0 for launching in terminal (faster)
    DefineConstant[economPos = 1];
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
        
        // 1. Inicializa os agrupamentos globais vazios
        Super = Region[ {} ];
        Cond = Region[ {} ];
        Edge1 = Region[ {} ];
        Edge2 = Region[ {} ];
        PositiveEdges = Region[ {} ];

// 2. Cria as 144 fitas e bordas dinamicamente e já as acumula
        For i In {1:144}
            Super~{i}  = Region[ 10000 + i ];
            Edge1_~{i} = Region[ 20000 + i ];
            Edge2_~{i} = Region[ 30000 + i ];

            // Adiciona as fitas individuais aos grupos gerais
            Super += Region[ Super~{i} ];
            Cond  += Region[ Super~{i} ];
            Edge1 += Region[ Edge1_~{i} ];
            Edge2 += Region[ Edge2_~{i} ];
            PositiveEdges += Region[ Edge1_~{i} ];
        EndFor

        // 3. Define as bordas laterais conjuntas usando os grupos acumulados acima
        LateralEdges = Region[ {Edge1, Edge2} ];

        
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
            // Se for simular como cobre, atribui todas as 144 fitas
            Copper += Region[ {Super} ];
        EndIf
        
    ElseIf(MaterialType == 3)
        // Se for simular como ferro
        Ferro += Region[ {Super} ]; 
        IsThereFerro = 1;
    EndIf        
    


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
    DefineConstant [Imax = 7000]; // Maximum imposed current intensity [A]
    DefineConstant [bmax = 2e2*1e-4];
    DefineConstant [f = 60]; // Frequency of imposed current intensity [Hz]
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
            {Region SurfSym ; Value 0.0;}
            If(SourceType == 0)
                {Region SurfOut ; Value 0.0;}
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



// ----------------------------------------------------------------------------
// --------------------------- FUNCTION SPACE ---------------------------------
// ----------------------------------------------------------------------------
// Gauge condition for the vector potential
Group {
    Surf_a_noGauge = Region [ {Gamma_e, BndOmegaC} ] ;
}
Constraint {
    { Name GaugeCondition ; Type Assign ;
        Case {
            If(formulation == ta_formulation)
                // Gauge in the whole domain
                {Region Omega ; SubRegion Surf_a_noGauge; Value 0.; }
            Else
                // Zero on edges of a tree in Omega_CC, containing a complete tree on Surf_a_noGauge
                {Region Omega_a_OmegaCC ; SubRegion Surf_a_noGauge; Value 0.; }
            EndIf
        }
    }
}
// Function spaces for the spatial discretization
FunctionSpace {
    
    { Name a_space_2D; Type Form1P;
        BasisFunction {
            { Name psin; NameOfCoef an; Function BF_PerpendicularEdge;
                Support Omega_a_AndBnd; Entity NodesOf[All]; }
            // { Name psin3; NameOfCoef an3; Function BF_PerpendicularEdge_2E;
            //    Support OmegaC; Entity EdgesOf[OmegaC]; }
            If(a_enrichment == 1)
                { Name psin2; NameOfCoef an2; Function BF_PerpendicularEdge_2E;
                    Support Omega_a_AndBnd; Entity EdgesOf[BndOmega_ha]; } // Second order for stability of the coupling
            EndIf
        }
        Constraint {
            { NameOfCoef an; EntityType NodesOf; NameOfConstraint a; }
            If(a_enrichment == 1)
                { NameOfCoef an2; EntityType EdgesOf; NameOfConstraint a2; }
            EndIf
        }
    }
    //  2: In 3D or 2D with perpendicular b
    //      a = sum a_e * psi_e     (edges of co-tree in Omega_a)
    { Name a_space_3D; Type Form1;
        BasisFunction {
            { Name psie ; NameOfCoef ae ; Function BF_Edge ;
                Support Omega_a_AndBnd ; Entity EdgesOf[ All, Not BndOmegaC ] ; }
            { Name psie2 ; NameOfCoef ae2 ; Function BF_Edge ;
                Support Omega_a_AndBnd ; Entity EdgesOf[ BndOmegaC ] ; } // To keep all dofs of BndOmegaC where a is unique (because e is known)
            If(a_enrichment == 1)
                { Name psie3a ; NameOfCoef ae3a ; Function BF_Edge_3F_a ;
                    Support Omega_a_AndBnd ; Entity FacetsOf[ BndOmega_ha ] ; }
                { Name psie3b ; NameOfCoef ae3b ; Function BF_Edge_3F_b ;
                    Support Omega_a_AndBnd ; Entity FacetsOf[ BndOmega_ha ] ; }
                // { Name psie3c ; NameOfCoef ae3c ; Function BF_Edge_3F_c ;
                //    Support Omega_a_AndBnd ; Entity FacetsOf[ BndOmega_ha ] ; }
            EndIf
        }
        Constraint {
            { NameOfCoef ae; EntityType EdgesOf; NameOfConstraint a; }
            { NameOfCoef ae2; EntityType EdgesOf; NameOfConstraint a; }
            // Gauge condition
            { NameOfCoef ae; EntityType EdgesOfTreeIn; EntitySubType StartingOn;
                NameOfConstraint GaugeCondition; }
        }
    }
    // Function space for the curent vector potential in t-a-formulation
    // The function here is the normal component of the vector t. The normal direction is
    // introduced explicitly in the formulation, where the "true t" is Dof{t} * Normal[]
    //
    //  t = sum phi_n * psi_n     (nodes inside the tape)
    //      + sum T_i * psi_i     (global shape function linked to current intensity)
    //
    // NB: psi_i makes sense as a "global function" only in 3D. In 2D, this is simply one nodal function
    //      at the positive edge of the tape, but with the syntax below, all situations are treated the same way.
{ Name t_space; Type Form0;
        BasisFunction {
            { Name psin; NameOfCoef tn; Function BF_Node; Support Super; Entity NodesOf[All, Not LateralEdges]; }
            
            // Declaração automática das 144 funções de base modais
            For i In {1:144}
                { Name psii~{i}; NameOfCoef Ti~{i}; Function BF_GroupOfNodes; Support Super~{i}; Entity GroupsOfNodesOf[Edge1_~{i}]; }
            EndFor
        }
        GlobalQuantity {
            For i In {1:144}
                { Name T~{i} ; Type AliasOf ; NameOfCoef Ti~{i} ; }
            EndFor
            { Name V  ; Type AssociatedWith ; NameOfCoef Ti1 ; }
        }
    }
    }

// ----------------------------------------------------------------------------
// --------------------------- FORMULATION ------------------------------------
// ----------------------------------------------------------------------------
mult_aj = mu0^(8);

Formulation {
    // t-a-formulation.
    // We actually solve for t_tilde = w * t
    // (so the thickness is already inside t, such that BC are directly the current intensity)
    { Name MagDyn_ta; Type FemEquation;
        Quantity {
            { Name t; Type Local; NameOfSpace t_space; }
            
            // Mapeia os 144 potenciais globais de corrente como incógnitas
            For i In {1:144}
                { Name T~{i}; Type Global; NameOfSpace t_space[T~{i}]; }
            EndFor

            { Name V; Type Global; NameOfSpace t_space[V]; }

            If(Dim == 3)
                { Name a; Type Local; NameOfSpace a_space_3D; }
            Else
                { Name a; Type Local; NameOfSpace a_space_2D; }
            EndIf
        }
        Equation {
            // Time derivative - current solution
            Galerkin { [ - Normal[] /\ Dof{a} , {d t} ];
                In OmegaC; Integration Int; Jacobian Sur;  }
            // Time derivative - previous solution
            Galerkin { [ Normal[] /\ {a}[1] , {d t} ];
                In OmegaC; Integration Int; Jacobian Sur;  }
            // ---- SUPER ----
            // Induced currents
            // Non-linear OmegaC
            If(Flag_h_NR_Rho)
                Galerkin { [ - $DTime * 1./thickness[] * rho[1./thickness[] *{d t} /\ Normal[], Norm[{d a}] ] * Normal[] /\ ({d t} /\ Normal[]) , {d t} ];
                    In NonLinOmegaC; Integration Int; Jacobian Sur;  }
                Galerkin { [ - $DTime * 1./thickness[] * Normal[] /\ (dedj[1./thickness[] *{d t} /\ Normal[], Norm[{d a}] ] * (Dof{d t} /\ Normal[])) , {d t} ];
                    In NonLinOmegaC; Integration Int; Jacobian Sur;  }
                Galerkin { [ $DTime * 1./thickness[] * Normal[] /\ (dedj[1./thickness[] *{d t} /\ Normal[], Norm[{d a}] ] * ({d t} /\ Normal[])) , {d t} ];
                    In NonLinOmegaC ; Integration Int; Jacobian Sur;  }
            Else
                Galerkin { [ - $DTime * 1./thickness[] * rho[1./thickness[] *{d t} /\ Normal[], Norm[{d a}] ] * Normal[] /\ (Dof{d t} /\ Normal[]) , {d t} ];
                    In NonLinOmegaC; Integration Int; Jacobian Sur;  }
            EndIf
            // Linear OmegaC
            Galerkin { [ - $DTime * 1./thickness[] * rho[] * Normal[] /\ (Dof{d t} /\ Normal[]) , {d t} ];
                In LinOmegaC; Integration Int; Jacobian Sur;  }
                
            // ---- FERRO ----
            // Curl h term - NonMagnDomain
            Galerkin { [ nu[] * Dof{d a} , {d a} ];
                In Omega_a; Integration Int; Jacobian Vol; }
            // Curl h term - MagnAnhyDomain (only Newton-Raphson)
            Galerkin { [ nu[{d a}] * {d a} , {d a} ];
                In MagnAnhyDomain; Integration Int; Jacobian Vol; }
            Galerkin { [ dhdb[{d a}] * Dof{d a} , {d a} ];
                In MagnAnhyDomain; Integration Int; Jacobian Vol; }
            Galerkin { [ - dhdb[{d a}] * {d a} , {d a} ];
                In MagnAnhyDomain; Integration Int; Jacobian Vol; }
            // Surface term
            Galerkin { [ - Dof{d t} /\ Normal[] , {a}]; // Dof{d t} /\ Normal[] is the current density!
                In BndOmega_ha; Integration Int; Jacobian Sur; }

// ====================================================================
            // MODELO DE CIRCUITO ACOPLADO (144 FITAS EM PARALELO GLOBAL)
            // ====================================================================
            // 1. Acoplamento de Faraday: A queda de tensão V governa o avanço temporal de cada fita
            For i In {1:144}
                GlobalTerm { [ - $DTime * Dof{V} , {T~{i}} ] ; In Edge1_~i ; }
            EndFor

            // 2. Lei de Kirchhoff das Correntes (KCL): A soma das 144 correntes é igual à fonte transiente
            For i In {1:144}
                GlobalTerm { [ Dof{T~{i}} , {V} ] ; In Edge1_~{i} ; }
            EndFor

            GlobalTerm { [ -I[] , {V} ] ; In Edge1_1 ; }    
            // ====================================================================
            // ====================================================================

            If(Dim == 3)
                Galerkin { [ - hsVal[] * (directionApplied[] /\ Normal[]), {a} ];
                    In Gamma_h ; Integration Int ; Jacobian Sur; }
            EndIf
        }
    }
 
}

// ----------------------------------------------------------------------------
// --------------------------- POST-PROCESSING --------------------------------
// ----------------------------------------------------------------------------
PostProcessing {
    // t-a-formulation -> look here to see how things have to be interpreted.
    { Name MagDyn_ta; NameOfFormulation MagDyn_ta;
        Quantity {
            { Name h; Value {
                Term { [ nu[{d a}] * {d a} ] ; In MagnAnhyDomain; Jacobian Vol; }
                Term { [ nu[] * {d a} ] ; In MagnLinDomain; Jacobian Vol; }
                }
            }
            { Name b; Value{
                Term { [ {d a} ] ; In Omega_a; Jacobian Vol;} } }
            { Name by; Value{
                Term { [ CompY[{d a}]*Vector[0,1,0] ] ; In Omega_a; Jacobian Vol;} } }
            { Name a; Value{ Local{ [ {a} ] ;
                In Omega_a_AndBnd; Jacobian Vol; } } }
            // { Name hxn; Value{ Local{ [ Normal[] /\ {h} ] ;
            //    In Bnd; Jacobian Sur; } } }
            { Name compz_a; Value{ Local{ [ CompZ[{a}] ] ;
                In OmegaCC; Jacobian Vol; } } }
            { Name normal; Value{ Local{ [ Normal[] ] ;
                In OmegaC; Jacobian Sur; } } }
            { Name mur; Value{ Local{ [ 1.0/(nu[{d a}] * mu0) ] ;
                In OmegaCC; Jacobian Vol; } } }
            // { Name j; Value{ Local{ [ 1./thickness[] * {d t} /\ Normal[] ] ;
            //    In Omega; Jacobian Sur; } } }
             { Name j; Value{ Local{ [ 1./thickness[] * {d t} /\ Normal[] ] ;
                In Omega; Jacobian Sur; } } }
            { Name t; Value{ Local{ [ 1./thickness[] * {t} * Normal[] ] ;
                In OmegaC; Jacobian Sur; } } }
            { Name tNorm; Value{ Local{ [ 1./thickness[] * {t} ] ;
                In OmegaC; Jacobian Sur; } } }
            { Name e; Value{ Local{ [ 1./thickness[] * rho[ 1./thickness[] * {d t} /\ Normal[], Norm[{d a}] ]*{d t} /\ Normal[] ] ;
                In OmegaC; Jacobian Sur; } } }
            { Name jouleLosses; Value{ Local{ [ (1./thickness[] * {d t} /\ Normal[]) * (1./thickness[] * rho[ 1./thickness[] * {d t} /\ Normal[], Norm[{d a}] ]*{d t} /\ Normal[]) ] ;
                In OmegaC; Jacobian Sur; } } }
            { Name jz; Value{ Local{ [ 1./thickness[] * CompZ[{d t} /\ Normal[]] ] ;
                In OmegaC; Jacobian Sur; } } }
            { Name norm_j; Value{ Local{ [ 1./thickness[] * Norm[{d t} /\ Normal[]] ] ;
                In OmegaC; Jacobian Sur; } } }
            { Name m_avg; Value{ Integral{ [ 0 ] ;
                In OmegaC; Integration Int; Jacobian Sur; } } } // TO DO
            { Name b_avg; Value{ Integral{ [ 0 / (SurfaceArea[]) ] ;
                In OmegaC; Integration Int; Jacobian Sur; } } } // TO DO
            { Name hsVal; Value{ Term { [ hsVal[] ]; In Omega; } } }
            { Name time; Value{ Term { [ $Time ]; In Omega; } } }
            { Name time_ms; Value{ Term { [ 1000*$Time ]; In Omega; } } }
            { Name power;
                Value{
                    Integral{ [ ({d a} - {d a}[1]) / $DTime * nu[{d a}] * ({d a}+{d a}[1])/2 ] ;
                        In MagnAnhyDomain ; Integration Int ; Jacobian Vol; }
                    Integral{ [ ({d a} - {d a}[1]) / $DTime * nu[] * ({d a}+{d a}[1])/2 ] ;
                        In Air ; Integration Int ; Jacobian Vol; }
                    Integral{ [ thickness[]*({d a} - {d a}[1]) / $DTime * nu[] * {d a} ] ;
                        In OmegaC ; Integration Int ; Jacobian Sur; }
                    //Integral{ [  1./thickness[] * (mu[{t}]*{t} - mu[{t}]*{t}[1]) / $DTime * {t} ] ;
                    //    In OmegaC ; Integration Int ; Jacobian Sur; } // Neglected.
                    Integral{ [ 1./thickness[] * rho[1./thickness[] * {d t} /\ Normal[], Norm[{d a}] ]*{d t}*{d t}] ;
                        In OmegaC ; Integration Int ; Jacobian Sur; }
                }
            }
            { Name dissPower;
                Value{
                    Integral{ [ 1./thickness[] * rho[ 1./thickness[] * {d t} /\ Normal[], Norm[{d a}] ]*{d t}*{d t}] ;
                        In OmegaC ; Integration Int ; Jacobian Sur; }
                }
            }
            { Name dissPowerCut;
                Value{
                    Integral{ [ (CompZ[XYZ[]]>0.005 && CompZ[XYZ[]]<0.023 ) * 1./thickness[] * rho[ 1./thickness[] * {d t} /\ Normal[], Norm[{d a}] ]*{d t}*{d t}] ;
                        In OmegaC ; Integration Int ; Jacobian Sur; }
                }
            }
            { Name V;
                Value{ Term{ [ {V} ] ; In PositiveEdges;} }
            }
            { Name I; // Corrente total recuperada pela fonte (I[])
                Value{ Term{ [ I[] ] ; In Edge1_1;} }
            }
            { Name dissPowerGlobal;
                Value{
                    // Potência total = V * I[] (válido para qualquer número de fitas)
                    Term{ [ thickness[] * {V} * I[] ] ; In Edge1_1;}
                }
            }

        }
    }
}





Include "resolution.pro";



PostOperation {
    // Runtime output for graph plot
    { Name Info;
            NameOfPostProcessing MagDyn_ta ;
        Operation{
            Print[ time[OmegaC], OnRegion OmegaC, LastTimeStepOnly, Format Table, SendToServer "Output/0Time [s]"] ;
             //   Print[ I1, OnRegion Edge1_1, LastTimeStepOnly, Format Table, SendToServer "Output/1Current Tape 1 [A]"] ;
                // Print[ I2, OnRegion Edge1_2, LastTimeStepOnly, Format Table, SendToServer "Output/1Current Tape 2 [A]"] ;
                // Print[ I3, OnRegion Edge1_3, LastTimeStepOnly, Format Table, SendToServer "Output/1Current Tape 3 [A]"] ;
                // Print[ I4, OnRegion Edge1_4, LastTimeStepOnly, Format Table, SendToServer "Output/1Current Tape 4 [A]"] ;

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
                Print[ I4, OnRegion Edge1_4, Format TimeTable, File StrCat[outputDirectory,"/current4.txt"] ];
            Print[ b, OnLine{{List[controlPoint1]}{List[controlPoint2]}} {savedPoints},
                Format TimeTable, File outputMagInduction1];
            Print[ b, OnLine{{List[controlPoint3]}{List[controlPoint4]}} {savedPoints},
                Format TimeTable, File outputMagInduction2];
            //Print[ hsVal[Omega], OnRegion Omega, Format TimeTable, File outputAppliedField];
        }
    }
}
