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
            { Name psin; NameOfCoef tn; Function BF_Node;
                Support Omega_h; Entity NodesOf[All, Not LateralEdges]; } // = 0 on lateral edges
            // { Name psin2; NameOfCoef tn2; Function BF_Node_2E;
            //    Support Omega_h; Entity EdgesOf[All, Not LateralEdges]; } // Leads to issues with Newton-Raphson -> Why?
            { Name psii; NameOfCoef Ti; Function BF_GroupOfNodes;
                Support Omega_h_OmegaC_AndBnd; Entity GroupsOfNodesOf[PositiveEdges]; }

        }
        GlobalQuantity {
            { Name T ; Type AliasOf        ; NameOfCoef Ti ; }
            { Name V ; Type AssociatedWith ; NameOfCoef Ti ; }
        }
        Constraint {
            { NameOfCoef V;
                EntityType GroupsOfNodesOf; NameOfConstraint Voltage; }
            { NameOfCoef T;
                EntityType GroupsOfNodesOf; NameOfConstraint Current; }
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
            { Name T; Type Global; NameOfSpace t_space[T]; }
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
            // Neumann BC: Global coupling through voltage-current relationship (Wang et al. 2022, Eq. 9-12)
            // This term enables E-field coupling across the tape boundary, providing Neumann-type BC
            GlobalTerm { [ - $DTime * Dof{V} , {T} ] ; In PositiveEdges ; }
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
            // ------------------------- OPTIONAL Neumann BC -------------------------
            // Enable the weak-form Neumann boundary term representing (E x delta(T))·dA
            // per Wang et al. 2022, Appendix A. This follows existing rho(...) usage.
            Galerkin { [ - 1./thickness[] * rho[1./thickness[] * {d t} /\ Normal[], Norm[{d a}] ] * ({d t} /\ Normal[]) , {a} ];
                In BndOmega_ha; Integration Int; Jacobian Sur; }
            // Notes:
            // - If GetDP errors about function arguments, ensure `lawsAndFunctions.pro` defines rho[...] as in this repo.
            // - If the integral domain is incorrect, check `BndOmega_ha` mapping in `jac_int.pro`.
            // ----------------------------------------------------------------------
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
                Value{
                    Term{ [ {V} ] ; In PositiveEdges;}
                }
            }
            { Name I;
                Value{
                    Term{ [ {T} ] ; In PositiveEdges;}
                }
            }
            { Name dissPowerGlobal;
                Value{
                    Term{ [ thickness[] * {V}*{T} ] ; In PositiveEdges;}
                }
            }
        }
    }
}
