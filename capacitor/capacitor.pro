Group {
  Domain = Region[1]; // Regiao de ar
  Ground = Region[10]; // Chao
  Electrode = Region[20]; // Placa 1V

}

Function {
  eps[] = 8.854187817e-12; // Permissividade do vácuo
}

Constraint {
  { Name DirichletBoundary; Type Assign;
    Case {
      { Region Ground; Value 0; }
      { Region Electrode; Value 1; }   
    }
  }
}

Jacobian {
  { Name Vol;
    Case {
      { Region All; Jacobian Vol; }
    }
  }
}


Integration {
  { Name IntGauss;
    Case {
      { Type Gauss;
        Case {
          { GeoElement Triangle; NumberOfPoints 3; }
          { GeoElement Quadrangle; NumberOfPoints 4; }
        }
      }
    }
  }
}


FunctionSpace {
  { Name Hgrad_v; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef vn; Function BF_Node; Support Domain; Entity NodesOf[All]; }
    }
    Constraint {
     { NameOfCoef vn; EntityType NodesOf; NameOfConstraint DirichletBoundary; } 
    }
  }
}


Formulation {
  { Name Electrostatics_v; Type FemEquation;
    Quantity {
      { Name v; Type Local; NameOfSpace Hgrad_v; }
    }
    Equation {
      Integral {
        [ eps[]* Dof{d v}, {d v}];
          In Domain; Jacobian Vol; Integration IntGauss;
      }
    }
  }
} 

Resolution {
  { Name SolveElectrostatics;
    System {
      { Name Sys; NameOfFormulation Electrostatics_v; }
    }
    Operation {
      Generate[Sys];
      Solve[Sys];
      SaveSolution[Sys];
    }
  }
}

PostProcessing {
  { Name EleSta_v ;
    NameOfFormulation Electrostatics_v;
    Quantity {
      { Name v; Value { Local {[{v}]; In Domain; Jacobian Vol;}} }
      { Name e; Value { Local {[-{d v}]; In Domain; Jacobian Vol;}} }
    }
  }
}

PostOperation {
  { Name Map_v_e;
    NameOfPostProcessing EleSta_v;
    Operation {
      Print[v, OnElementsOf Domain, File "potential_v.pos"];
      Print[e, OnElementsOf Domain, File "field_e.pos"];
    }
  }
}


