// Centros dos 12 blocos (X, Y em metros) - Lado Esquerdo
// Valores de X invertidos para negativo
// Lista_X[] = {-15.80e-3, -15.80e-3, -15.80e-3, -15.80e-3, -15.80e-3, -15.80e-3, 
//             -21.70e-3, -21.70e-3, -21.70e-3, -21.70e-3, -21.70e-3, -21.70e-3};

// Valores de Y mantidos (primeiro quadrante/lado esquerdo)
//Lista_Y[] = {45.80e-3, 53.30e-3, 58.10e-3, 63.00e-3, 68.00e-3, 76.30e-3, 
//             45.80e-3, 53.30e-3, 58.10e-3, 63.00e-3, 68.00e-3, 76.30e-3};



// Lista_X[] = {-15.80e-3, -15.80e-3, -15.80e-3, -15.80e-3,
//              -21.70e-3, -21.70e-3, -21.70e-3, -21.70e-3};

// Lista_Y[] = {53.30e-3, 58.10e-3, 63.00e-3, 68.00e-3,
//              53.30e-3, 58.10e-3, 63.00e-3, 68.00e-3};


// Array com 36 coordenadas X (18 condutores na coluna esquerda, 18 na coluna direita)
Lista_X[] = {
    // Blocos 1 a 6 (X = -15.80 mm)
    -15.80e-3, -15.80e-3, -15.80e-3, -15.80e-3, -15.80e-3, // Bloco 1
    -15.80e-3, -15.80e-3,                                  // Bloco 2
    -15.80e-3, -15.80e-3,                                  // Bloco 3
    -15.80e-3, -15.80e-3,                                  // Bloco 4
    -15.80e-3, -15.80e-3,                                  // Bloco 5
    -15.80e-3, -15.80e-3, -15.80e-3, -15.80e-3, -15.80e-3, // Bloco 6
    // Blocos 7 a 12 (X = -21.70 mm)
    -21.70e-3, -21.70e-3, -21.70e-3, -21.70e-3, -21.70e-3, // Bloco 7
    -21.70e-3, -21.70e-3,                                  // Bloco 8
    -21.70e-3, -21.70e-3,                                  // Bloco 9
    -21.70e-3, -21.70e-3,                                  // Bloco 10
    -21.70e-3, -21.70e-3,                                  // Bloco 11
    -21.70e-3, -21.70e-3, -21.70e-3, -21.70e-3, -21.70e-3  // Bloco 12
};

// Array com 36 coordenadas Y correspondentes
Lista_Y[] = {
    // Blocos 1 a 6
    42.60e-3, 44.20e-3, 45.80e-3, 47.40e-3, 49.00e-3, // Bloco 1
    52.50e-3, 54.10e-3,                               // Bloco 2
    57.30e-3, 58.90e-3,                               // Bloco 3
    62.20e-3, 63.80e-3,                               // Bloco 4
    67.20e-3, 68.80e-3,                               // Bloco 5
    73.10e-3, 74.70e-3, 76.30e-3, 77.90e-3, 79.50e-3, // Bloco 6
    // Blocos 7 a 12 (Simétricos em Y aos da coluna anterior)
    42.60e-3, 44.20e-3, 45.80e-3, 47.40e-3, 49.00e-3, // Bloco 7
    52.50e-3, 54.10e-3,                               // Bloco 8
    57.30e-3, 58.90e-3,                               // Bloco 9
    62.20e-3, 63.80e-3,                               // Bloco 10
    67.20e-3, 68.80e-3,                               // Bloco 11
    73.10e-3, 74.70e-3, 76.30e-3, 77.90e-3, 79.50e-3  // Bloco 12
};