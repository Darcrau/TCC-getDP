# Simulação T-A de Fita Supercondutora (hts-ta)

Este diretório contém a simulação eletromagnética de uma **fita supercondutora de alta temperatura (HTS)** usando a **formulação T-A** no software GetDP. A seguir, a explicação passo a passo de tudo o que acontece, na ordem em que o GetDP processa os arquivos.

## Guia Rápido para Reproduzir no COMSOL (Geometria, Corrente e Campo)

Use este resumo para montar o mesmo caso em um modelo 2D no COMSOL:

1. **Geometria 2D (plano XY)**
   - Domínio de ar: círculo de raio **R_inf = 0,06 m**, centrado na origem.
   - Fita HTS: representada como **uma linha (casca fina)** sobre o eixo X, de **x = -W/2 a x = +W/2**, em y = 0, onde **W_tape = 12 mm** (portanto, de -6 mm a +6 mm). A espessura física usada na formulação é **H_tape = 1 µm**.
   - Pontos de borda da fita: **Edge1** em x = -W/2 (entrada da corrente) e **Edge2** em x = +W/2 (retorno).
   - Regiões físicas (para mapear fronteiras no COMSOL):

     | Nome | Entidade | ID | Função |
     |------|----------|----|--------|
     | Air | Superfície do círculo | 1000 | Domínio de ar |
     | Exterior boundary | Circunferência | 14000000 | Fronteira externa onde se aplica A ou se fixa A = 0 |
     | Conducting domain | Linha da fita | 23000 | Região da fita (casca fina) |
     | Conducting domain boundary | Linha da fita | 25000 | Mesma linha, usada como fronteira condutora |
     | Left edge | Ponto esquerdo | 11001 | Onde a corrente é imposta |
     | Right edge | Ponto direito | 11002 | Retorno da corrente |
     | Arbitrary Point | Ponto (0, –R_inf, 0) | 11000 | Ponto onde φ é fixado para unicidade |

2. **Material da fita (lei de potência)**
   - **Jc = 2,5×10^10 A/m²**, **n = 25**, **ec = 1×10⁻⁴ V/m**.
   - Dependência com campo: **Jc(B) = Jc / (1 + |B|/b0)**, com **b0 = 0,1 T**.
   - Use a espessura **w = H_tape = 1 µm** (w é o alias usado na formulação) para converter corrente de folha em densidade (J = ∂t/∂x / w).

3. **Excitação por corrente (caso padrão, `SourceType = 0`)**
   - Corrente aplicada somente em **Edge1**:  
     **I(t) = Imax · sin(2π·f·t)**, com **f = 50 Hz** e  
     **Imax = 0,9 · Jc · W_tape · H_tape ≈ 270 A**.
   - Condições de contorno associadas:  
     - **a = 0** na fronteira externa (`Exterior boundary`) → campo aplicado nulo.  
     - **φ = 0** no `Arbitrary Point` para fixar o potencial escalar.  
     - Corrente global **I(t)** imposta em `Left edge`; `Right edge` é o retorno (t livre).

4. **Excitação por campo aplicado (`SourceType = 1`) ou corrente + campo (`SourceType = 2`)**
   - Campo magnético uniforme senoidal no ar, amplitude **bmax = 0,02 T**, frequência **50 Hz**.  
     Implementação via potencial vetor: **A_z = -x · bmax · sin(2π·f·t)** na fronteira externa; como **B = ∇×A** e **B_y = -∂A_z/∂x**, resulta **B_y ≈ bmax · sin(2π·f·t)**, uniforme e dirigido em **+y**.
   - Potencial escalar na fronteira externa: **φ = y · sin(2π·f·t)** (`directionApplied = (0,1,0)`).
   - Corrente: **0 A** se apenas campo (`SourceType = 1`), ou **I(t)** acima se corrente + campo (`SourceType = 2`).

5. **Tradução prática para o COMSOL**
   - Use um estudo 2D magnético quasiestático; represente a fita como **borda (edge) com espessura w (= H_tape)** aplicando condição de corrente integrada ou campo de superfície equivalente.
   - Fixe **A = 0** (ou A prescrito conforme o caso de campo) na circunferência externa. Fixe **φ** em um ponto para remover o grau de liberdade nulo.
   - Para pós-processo, acompanhe **B**, **J**, **E** na linha da fita e a tensão entre Edge1 e Edge2; o período de simulação padrão é **25 ms (1,25 períodos a 50 Hz)** com passo inicial **dt ≈ 333 µs**.

---

## 1. Definição de parâmetros geométricos e de malha — `tape_data.pro`

Este é o primeiro arquivo lido (via `Include "tape_data.pro"` tanto no `.geo` quanto no `.pro`). Ele define todas as constantes numéricas usadas na construção da geometria e em toda a simulação:

### Parâmetros geométricos
| Constante     | Valor padrão | Significado |
|---------------|-------------|-------------|
| `R_inf`       | 0.06 m      | Raio da casca esférica exterior (domínio de ar infinito) |
| `R_air`       | 0.04 m      | Raio da casca de ar interna |
| `W_tape`      | 12 mm       | Largura da fita HTS |
| `H_tape`      | 1 µm        | Espessura (altura) da fita HTS |

### Parâmetros de malha
| Constante           | Valor     | Significado |
|---------------------|-----------|-------------|
| `meshMult`          | 4         | Multiplicador global de tamanho de malha |
| `elementMult`       | 10        | Multiplicador do número de elementos na fita |
| `numElementsTape`   | calculado | Número de elementos ao longo da fita |

### IDs das regiões físicas
Cada região do domínio recebe um identificador inteiro único:

| Constante        | Valor    | Significado |
|------------------|----------|-------------|
| `AIR`            | 1000     | Domínio de ar interno |
| `AIR_OUT`        | 2000     | Casca de ar exterior (domínio infinito) |
| `CUT`            | 9000     | Corte topológico (para coHomologia) |
| `ARBITRARY_POINT`| 11000    | Ponto arbitrário para fixar potencial |
| `EDGE_1`         | 11001    | Borda esquerda da fita |
| `EDGE_2`         | 11002    | Borda direita da fita |
| `SURF_SYM`       | 13000    | Linha de simetria |
| `SURF_OUT`       | 14000000 | Fronteira exterior do domínio |
| `MATERIAL`       | 23000    | Domínio da fita supercondutora |
| `BND_MATERIAL`   | 25000    | Fronteira do material condutor |
| `THICK_CUT`      | SURF_OUT+1 | Corte espesso (usado com coHomologia Gmsh) |

---

## 2. Construção da geometria e malha — `htstape.geo`

Este arquivo é processado pelo **Gmsh** para criar a geometria 2D e gerar a malha. O modelo é 2D no plano XY.

### Variáveis locais de tamanho de malha

```
R = W_tape/2          → raio equivalente (metade da largura da fita)
LcTape  = 2*R / numElementsTape  → tamanho do elemento na fita
LcLayer = 2 * LcTape             → tamanho na camada ao redor da fita
LcAir   = meshMult * 0.003       → tamanho no ar
LcInf   = meshMult * 0.003       → tamanho na casca exterior
```

### Pontos e linhas criados

#### Casca exterior circular (domínio de ar + fronteira infinita)

```
Ponto 100 → (0, 0, 0)          — centro do círculo
Ponto 2   → (0, -R_inf, 0)     — polo sul da casca
Ponto 4   → (R_inf, 0, 0)      — polo leste
Ponto 6   → (0, R_inf, 0)      — polo norte
Ponto 8   → (-R_inf, 0, 0)     — polo oeste
```

Com esses quatro pontos sobre a circunferência de raio `R_inf`, são criados quatro arcos de círculo centrados no ponto 100:

```
Arco 2: ponto 2 → ponto 4
Arco 4: ponto 4 → ponto 6
Arco 6: ponto 6 → ponto 8
Arco 8: ponto 8 → ponto 2
```

Juntos, os arcos 2, 4, 6 e 8 formam a **circunferência exterior** do domínio computacional.

#### Fita supercondutora (linha 1D)

```
Ponto 10  → (-R, 0, 0)   — borda esquerda da fita
Ponto 11  → (R,  0, 0)   — borda direita da fita
Linha 10  → segmento de 10 a 11, com numElementsTape elementos (malha uniforme)
```

A fita é modelada como uma **linha** (1D embutida no domínio 2D) porque sua espessura `H_tape` é muito menor que as demais dimensões. Essa é a essência da **formulação T-A de casca fina** (*thin-shell*): substituir um volume muito fino por uma superfície/linha com condições de salto.

### Superfícies e malha

```
Line Loop 30  → {arco2, arco4, arco6, arco8}  (contorno exterior)
Surface 2     → interior do contorno 30        (domínio 2D completo de ar)
Curve 10 In Surface 2  → a linha da fita é embutida na malha 2D
```

### Regiões físicas (`Physical`)

Regiões físicas são os grupos de entidades geométricas que o GetDP irá referenciar:

| Região Física               | Entidade     | ID (`tape_data.pro`) | Significado |
|-----------------------------|--------------|----------------------|-------------|
| `"Air"`                     | Surface 2    | `AIR = 1000`         | Domínio 2D de ar (toda a superfície) |
| `"Exterior boundary"`       | Arcos 2,4,6,8| `SURF_OUT = 14000000`| Fronteira circular exterior |
| `"Conducting domain"`       | Linha 10     | `MATERIAL = 23000`   | A fita supercondutora propriamente dita |
| `"Conducting domain boundary"` | Linha 10  | `BND_MATERIAL = 25000` | Fronteira do condutor (mesma linha) |
| `"Left edge"`               | Ponto 10     | `EDGE_1 = 11001`     | Borda esquerda da fita (onde a corrente entra) |
| `"Right edge"`              | Ponto 11     | `EDGE_2 = 11002`     | Borda direita da fita |
| `"Arbitrary Point"`         | Ponto 2      | `ARBITRARY_POINT = 11000` | Ponto onde o potencial escalar é fixado |
| `"Spherical shell"`         | (vazia)      | `AIR_OUT = 2000`     | Reservada para casca exterior (não usada aqui) |
| `"Symmetry line"`           | (vazia)      | `SURF_SYM = 13000`   | Linha de simetria (não usada aqui) |
| `"Shells common line"`      | (vazia)      | `SURF_SHELL = 3000`  | Linha comum entre cascas (não usada) |
| `"Cut"`                     | (vazia)      | `CUT = 9000`         | Corte topológico clássico (não usado) |

> **Por que algumas regiões estão vazias?** A geometria da fita isolada não precisa de cascas de ar concêntricas, linha de simetria, nem cortes topológicos clássicos. Essas regiões ficam definidas como vazias para compatibilidade com o framework genérico do `.pro`.

### Cohomology

```
Cohomology(1) {{AIR}, {}};
```

Solicita ao Gmsh que calcule o **gerador do 1º grupo de cohomologia** do domínio `AIR`. Isso gera automaticamente o **"thick cut"** (`THICK_CUT`), que representa topologicamente o corte necessário para tornar o potencial vetor `a` univaluado em torno da fita. É a alternativa moderna ao corte manual do `CUT`.

---

## 3. Flags e grupos padrão — `commonInformation.pro`

Incluído no início de `htstape.pro`, define:

- **Identificadores numéricos das formulações** (ex.: `ta_formulation = 7`)
- **Flags de controle** (ex.: `Flag_cohomology`, `Flag_jcb`, `IsThereSuper`, `IsThereFerro`, ...)
- **Grupos genéricos** (`OmegaC`, `OmegaCC`, `Omega`, `Air`, `Super`, `Copper`, `Ferro`, ...) que serão preenchidos pelo `.pro` específico
- **Parâmetros de convergência** (`tol_energy`, `iter_max`, critério de energia, ...)
- **Parâmetros de saída** (`economPos`, `economInfo`, `saveAll`, ...)

---

## 4. Configuração principal da simulação — `htstape.pro`

Este é o arquivo principal lido pelo GetDP. Ele inclui os demais arquivos e define toda a simulação.

### 4.1 Grupo de regiões (`Group`)

Preenche os grupos genéricos do framework com as regiões físicas reais:

```
Air          → AIR + AIR_OUT          (ar: toda superfície 2D)
Cond         → MATERIAL               (fita condutora)
BndOmegaC    → BND_MATERIAL           (fronteira da fita)
Super        → MATERIAL               (a fita é supercondutora: MaterialType = 1)
Edge1        → EDGE_1                 (borda esquerda)
Edge2        → EDGE_2                 (borda direita)
LateralEdges → {Edge1, Edge2}
PositiveEdges→ {Edge1}               (onde a corrente é imposta como condição de contorno)

OmegaC       → Super (+ Copper, se houvesse cobre)
OmegaCC      → Air + Ferro
Omega        → OmegaC + OmegaCC      (domínio completo)
MagnLinDomain→ Air + Super + Copper   (meios com µ = µ₀)
NonLinOmegaC → Super                  (meio com resistividade não-linear)
```

**Configuração da coHomologia:**
```
Flag_cohomology = 1
→ Cuts = THICK_CUT  (corte espesso gerado pelo Gmsh)
```

### 4.2 Parâmetros físicos e numéricos (`Function`)

**Material superconductor (lei de potência):**
```
jc = 2.5×10¹⁰ A/m²    — densidade de corrente crítica
n  = 25               — expoente da lei de potência E ~ (J/Jc)^n
b0 = 0.1 T            — campo de referência para dependência de Jc(B)
Flag_jcb = 1          → Jc(B) = jc / (1 + |B|/b0)  (Jc dependente do campo)
```

**Excitação (SourceType = 0: corrente aplicada):**
```
IFraction = 0.9
Imax = 0.9 × jc × W_tape × H_tape    — amplitude da corrente
f    = 50 Hz
I(t) = Imax × sin(2π × 50 × t)       — corrente senoidal
timeFinalSimu = 1.25/f = 25 ms        — simulação de 1.25 ciclos
```

**Parâmetros numéricos:**
```
nbStepsPerPeriod = 240/meshMult = 60  — passos de tempo por período
dt = 1/(60 × 50) ≈ 333 µs            — passo de tempo inicial
tol_energy = 1e-6                     — tolerância relativa para convergência
iter_max   = 400                      — máximo de iterações não-lineares
extrapolationOrder = 2                — extrapolação quadrática para estimativa inicial
```

**Espessura da casca fina:**
```
thickness[Cond]  = H_tape = 1 µm
thickness[Edge1] = H_tape
thickness[Air]   = H_tape  (necessário tecnicamente pelo framework)
```

### 4.3 Leis constitutivas — `lawsAndFunctions.pro`

Define as relações constitutivas dos materiais:

**Ar (linear):**
```
µ[Air] = µ₀,   ν[Air] = 1/µ₀
```

**Superconductor — lei de potência E(J):**
```
ρ(J,B) = (ec/Jc(B)) × (|J|/Jc(B))^(n-1)
E = ρ(J,B) × J
```
A função `dedj` (jacobiano ∂E/∂J) é usada no método de Newton-Raphson para acelerar a convergência.

**Jacobiano inverso σ(E,B) = J(E)/E** (também disponível, para outras formulações):
```
σ(E,B) = Jc(B)/ec × 1/(ε + (|E|/ec)^((n-1)/n))
```

**Material ferromagnético (não usado nesta simulação, MaterialType ≠ 3):**
- Modelo de Langevin anhisterético para µ(H) e ν(B)

### 4.4 Restrições (condições de contorno) — `Constraint` em `htstape.pro`

**Para `SourceType = 0` (corrente aplicada):**

| Nome | Onde | Valor | Significado |
|------|------|-------|-------------|
| `a`  | `SurfOut` | 0 | Potencial vetor nulo na fronteira exterior (campo aplicado nulo) |
| `phi`| `ArbitraryPoint` | 0 | Fixa o potencial escalar em um ponto para unicidade |
| `Current` | `Edge1` | `I(t)` | Impõe a corrente total que flui pela fita |

O `Current` é a condição de contorno **global**: define o valor de `T` (potencial de corrente) na borda esquerda, impondo que a corrente total integrada ao longo da espessura seja `I(t)`.

### 4.5 Espaços de funções e formulação — `formulations.pro`

#### Espaços de funções

**Espaço `a_space_2D`** (potencial vetor no ar, 2D):
- Tipo: `Form1P` (1-forma perpendicular, adequado para campos 2D com B fora do plano)
- Base: funções de nó `BF_PerpendicularEdge` no domínio `Omega_a`
- `a` é o componente-z do potencial vetor: **B = ∇ × A**, com B no plano XY

**Espaço `t_space`** (potencial de corrente na fita):
- Tipo: `Form0` (função escalar nodal)
- Base: funções de nó `BF_Node` nos nós *internos* da fita (≠ bordas laterais)
- Função global `BF_GroupOfNodes` associada à borda positiva → grau de liberdade `T` (corrente total)
- Grandezas globais: `T` (corrente total) e `V` (tensão/voltagem)

> **Interpretação física de t:** Na formulação T-A, a fita fina é modelada pela função `t̃ = w × t`, onde `w = H_tape` é a espessura. A corrente de folha é `K = ∂t̃/∂x`, e a densidade de corrente volumétrica é `J = K/w = ∂t/∂x`.

#### Formulação fraca — `MagDyn_ta`

O sistema de equações resolvido é derivado das equações de Maxwell para a formulação T-A. As integrais de Galerkin correspondem à forma fraca:

**Equação da fita (domínio `OmegaC`, integração de superfície `Sur`):**

1. **Acoplamento A→t** (lei de Faraday):
   ```
   ∫_OmegaC [-n × A_novo + n × A_antigo] · δ(dt) dΩ
   ```
   Acopla a variação temporal do potencial vetor `a` (calculado no ar) com o potencial de corrente `t` da fita.

2. **Lei constitutiva não-linear (Super):**
   ```
   ∫_OmegaC [-Δt × (1/w) × ρ(J, |da|) × (dt/dn)] · δ(dt) dΩ
   ```
   Implementa `E = ρ(J) × J` de forma implícita, com o jacobiano `dedj` para Newton-Raphson.

3. **Tensão global:**
   ```
   GlobalTerm: -Δt × V · δT
   ```

**Equação do ar (domínio `Omega_a`, integração volumétrica `Vol`):**

4. **Lei de Ampère linearizada:**
   ```
   ∫_Omega_a ν × da · δ(da) dΩ
   ```
   Equação `∇ × H = 0` no ar (sem fonte de corrente volumétrica no ar).

5. **Acoplamento t→A** (condição de salto na fita):
   ```
   ∫_BndOmega_ha [-dt/dn] · δa dΩ
   ```
   Impõe a condição de salto de `H` na superfície da fita: `n × (H⁺ - H⁻) = K = J × w`.

### 4.6 Grupos auxiliares — `jac_int.pro`

Define os grupos de regiões associados aos espaços de funções:

| Grupo | Conteúdo | Significado |
|-------|----------|-------------|
| `Omega_h` | OmegaC | Domínio do potencial de corrente `t` |
| `Omega_a` | OmegaCC (Ar) | Domínio do potencial vetor `a` |
| `BndOmega_ha` | OmegaC | Interface fita/ar (onde o salto é aplicado) |
| `Omega_a_AndBnd` | Ar + OmegaC + GammaAll + PositiveEdges | Suporte completo de `a` |

Também define os **Jacobianos** da transformação isoparamétrica:
- `Vol`: transformação volumétrica (para integrais 2D no ar)
- `Sur`: transformação de superfície (para integrais 1D na fita)

E os esquemas de **integração de Gauss**:
- 3 pontos em linhas, 3 pontos em triângulos (para 2D)

---

## 5. Resolução no tempo — `resolution.pro`

### 5.1 Laço temporal (Euler implícito)

O GetDP integra as equações no tempo usando o **método de Euler implícito** com passo de tempo adaptativo:

```
t = 0 → timeFinalSimu (= 25 ms)

Para cada passo de tempo Δt:
    1. Estimativa inicial por extrapolação de ordem 2
    2. Laço iterativo não-linear (Newton-Raphson / Picard):
       - Gera o sistema A
       - Resolve A·x = b
       - Calcula resíduo e indicadores de energia
       - Verifica convergência: variação relativa da energia < tol_energy
       - Se convergiu: salva solução, aumenta Δt (se convergência rápida)
       - Se não convergiu: reduz Δt pela metade e tenta novamente
```

### 5.2 Critério de convergência

O critério padrão (`convergenceCriterion = 0`) é baseado na **variação relativa de indicadores de energia**:

```
$relChangeSuper = |W_super(iter) - W_super(iter-1)| / |W_super(iter-1)|
Convergido quando: $relChangeSuper / tol_energy < 1
```

onde `W_super` é a potência total calculada por pós-processamento em cada iteração.

### 5.3 Saída de arquivos

Arquivos de texto (`.txt`) salvos a cada passo de tempo:
- `power.txt` — energia e potência ao longo do tempo
- `jLine.txt` — densidade de corrente J ao longo da fita
- `bLine1.txt` — indução magnética B ao longo da fita (entre bordas)
- `bLine2.txt` — indução magnética B acima da fita
- `residual.txt` — histórico de resíduo por iteração
- `iteration.txt` — informações de cada passo de tempo

Arquivos de visualização (`.pos` do Gmsh), se `economPos = 0`:
- `res/a.pos` — potencial vetor A no domínio completo
- `res/t.pos` — potencial de corrente T na fita
- `res/j.pos` — densidade de corrente J na fita
- `res/e.pos` — campo elétrico E na fita
- `res/h.pos` — campo magnético H no domínio completo
- `res/b.pos` — indução magnética B no ar

### 5.4 GIF animado do resultado temporal

Foi adicionado o script `generate_gif.py` para gerar um GIF animado com **todo o intervalo temporal salvo** em `res/b.pos`.

Pré-requisitos:
- `gmsh` no PATH
- `Pillow` no Python (`python3 -m pip install pillow`)

Uso:

```bash
cd hts-ta
python3 generate_gif.py --pos res/b.pos --out res/b.gif --fps 20
```

Saída:
- `res/b.gif` com todos os passos de tempo disponíveis no arquivo `.pos`.

---

## 6. Pós-processamento — `formulations.pro` e `htstape.pro`

### Grandezas calculadas (`PostProcessing MagDyn_ta`)

| Grandeza | Expressão | Onde | Significado |
|----------|-----------|------|-------------|
| `a`      | `{a}`     | Omega_a | Potencial vetor (A·m) |
| `b`      | `∇×a`     | Omega_a | Indução magnética B (T) |
| `h`      | `ν × ∇×a` | MagnLinDomain | Campo magnético H (A/m) |
| `j`      | `(1/w) × ∇t × n` | OmegaC | Densidade de corrente J (A/m²) |
| `t`      | `(1/w) × t × n` | OmegaC | Potencial de corrente t (A/m) |
| `e`      | `ρ(J) × J` | OmegaC | Campo elétrico E (V/m) |
| `V`      | `{V}`     | PositiveEdges | Tensão (V·m⁻¹ — por unidade de comprimento) |
| `I`      | `{T}`     | PositiveEdges | Corrente total (A) |
| `dissPower` | `J·E×w` | OmegaC | Potência dissipada (W/m) |

### Pós-operação de saída (`PostOperation MagDyn` em `htstape.pro`)

1. **`Info`**: saída em tempo real para o painel Onelab (tempo, corrente aplicada, tensão)
2. **`MagDyn`**: salva todos os campos e perfis de linha a cada `writeInterval`
3. **`MagDyn_energy`**: calcula indicadores energéticos para o critério de convergência (interno, não salvo em arquivo principal)

---

## Resumo do fluxo completo

```
tape_data.pro          → Constantes, IDs de regiões
        ↓
htstape.geo (Gmsh)     → Geometria 2D: círculo + linha da fita + regiões físicas + coHomologia
        ↓
htstape.msh (Gmsh)     → Malha gerada
        ↓
GetDP lê htstape.pro:
  ├── tape_data.pro         → reimporta constantes
  ├── commonInformation.pro → flags e grupos genéricos
  ├── Group{}               → preenchimento dos grupos com regiões físicas reais
  ├── Function{}            → parâmetros físicos, excitação I(t)
  ├── lawsAndFunctions.pro  → leis constitutivas E(J), µ(H), ...
  ├── Function{}            → fonte I(t) e espessura da fita
  ├── Constraint{}          → CCs: a=0 na fronteira, I(t) na borda da fita
  ├── jac_int.pro           → grupos auxiliares, Jacobianos, integração de Gauss
  ├── formulations.pro      → espaços de funções (a, t) + formulação fraca T-A
  ├── resolution.pro        → laço temporal implícito + laço iterativo N-R
  └── PostOperation{}       → saída de campos, perfis de linha, tensão/corrente
```
