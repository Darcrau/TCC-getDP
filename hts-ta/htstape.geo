Include "tape_data.pro";

R = W_tape/2; // Radius

DefineConstant [LcTape = 2*R/numElementsTape]; // Mesh size in cylinder [m]
DefineConstant [LcLayer = LcTape*2]; // Mesh size in the region close to the cylinder [m]
DefineConstant [LcAir = meshMult*0.001*3]; // Mesh size in air shell [m]
DefineConstant [LcInf = meshMult*0.001*3]; // Mesh size in external air shell [m]

// Shells definition
Point(100) = {0, 0, 0, LcTape};
Point(2) = {0, -R_inf, 0, LcInf};
Point(4) = {R_inf, 0, 0, LcInf};
Point(6) = {0, R_inf, 0, LcInf};
Point(8) = {-R_inf, 0, 0, LcInf};
Circle(2) = {2, 100, 4};
Circle(4) = {4, 100, 6};
Circle(6) = {6, 100, 8};
Circle(8) = {8, 100, 2};

Point(10) = {-R, 0, 0, LcTape};
Point(11) = {R, 0, 0, LcTape};
Line(10) = {10,11};
Transfinite Line(10) = numElementsTape Using Progression 1;
Line Loop(30) = {2, 4, 6, 8}; // Outer boundary
Plane Surface(2) = {30};
Curve{10} In Surface{2};
Physical Surface("Air", AIR) = {2};
Physical Line("Exterior boundary", SURF_OUT) = {2, 4, 6, 8};
Physical Line("Conducting domain", MATERIAL) = {10};
Physical Line("Conducting domain boundary", BND_MATERIAL) = {10};
Physical Point("Left edge", EDGE_1) = {10};
Physical Point("Right edge", EDGE_2) = {11};
Physical Point("Arbitrary Point", ARBITRARY_POINT) = {2};
// Empty regions
Physical Surface("Spherical shell", AIR_OUT) = {};
Physical Line("Symmetry line", SURF_SYM) = {};
Physical Line("Shells common line", SURF_SHELL) = {};
Physical Line("Symmetry line material", SURF_SYM_MAT) = {};
Physical Line("Cut", CUT) = {};
Physical Line("Positive side of bnds", BND_MATERIAL_SIDE) = {};
Color Blue {Surface{2};}


Hide { Point{ Point '*' }; }

Cohomology(1) {{AIR}, {}};


