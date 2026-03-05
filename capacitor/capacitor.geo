Point(1) = {-2 , -2 , 0, 0.2};
Point(2) = {2 , -2 , 0, 0.2};
Point(3) = {2 , 2 , 0, 0.2};
Point(4) = {-2 , 2 , 0, 0.2};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};
Curve Loop(1) = {1, 2, 3, 4};

Plane Surface(1) = {1}; //Superficie do ar

//Placas superio e inferior

Point(5) = {-0.5, -0.2 , 0, 0.02};
Point(6) = {0.5, -0.2 , 0, 0.02};
Line(5) = {5, 6};

Point(7) = {-0.5, 0.2 , 0, 0.02};
Point(8) = {0.5, 0.2 , 0, 0.02};
Line(6) = {7, 8};

Curve{5,6} In Surface{1};

Physical Surface(1) = {1};//Ar
Physical Line(10) = {5}; //Placa inferior
Physical Line(20) = {6}; //Placa superior 

