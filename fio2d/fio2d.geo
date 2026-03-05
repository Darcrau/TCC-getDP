R_fio = 0.1 ;
R_ar = 0.5 ; 
malha_fio = 0.005;
malha_ar = 0.02 ; 

Point(1) = {0, 0, 0, malha_fio};

Point(2) = {R_fio, 0, 0, malha_fio};

Point(3) = {0, R_fio, 0, malha_fio};

Point(4) = {-R_fio, 0, 0, malha_fio};
Point(5) = {0, -R_fio, 0, malha_fio};

Circle(1) = {2, 1, 3};
Circle(2) = {3, 1, 4};
Circle(3) = {4, 1, 5};
Circle(4) = {5, 1, 2};

Curve Loop(1) = {1, 2, 3, 4};
Plane Surface(2) = {1};

Point(6) = {R_ar, 0, 0, malha_ar};

Point(7) = {0, R_ar, 0, malha_ar};

Point(8) = {-R_ar, 0, 0, malha_ar};

Point(9) = {0, -R_ar, 0, malha_ar};

Circle(5) = {6, 1, 7};
Circle(6) = {7, 1, 8};
Circle(7) = {8, 1, 9};
Circle(8) = {9, 1, 6};

Curve Loop(2) = {5, 6, 7, 8};
Plane Surface(1) = {2,1};


Physical Surface(1) = {1}; 
adhsakjhdasdsa

