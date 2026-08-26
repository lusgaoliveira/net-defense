# NetDefense 🛡️

**NetDefense** é um jogo de cartas estratégico 1v1 baseado em conceitos de redes de computadores. Dois jogadores defendem seus servidores enquanto tentam derrubar o servidor adversário usando cartas com poderes de rede.

---

## 📖 Sumário

- [Como Jogar](#como-jogar)
- [Fases do Turno](#fases-do-turno)
- [Tipos de Pacotes](#tipos-de-pacotes)
- [Cartas Disponíveis](#cartas-disponíveis)
- [Atributos do Servidor](#atributos-do-servidor)
- [Multiplayer](#multiplayer)
- [Como Executar](#como-executar)

---

## 🎮 Como Jogar

O objetivo é **reduzir o HP do servidor inimigo a 0** antes que o seu chegue a zero.

Cada jogador controla um **Servidor** com vida (HP), um **Buffer de Pacotes** e um **Campo** onde pode invocar cartas com habilidades especiais.

### Controles
| Ação | Controle |
|---|---|
| Jogar carta no campo | Arraste a carta da mão para um slot do campo |
| Ver detalhes de uma carta | Clique com o **botão direito** sobre ela |
| Ativar poder de uma carta no campo | Clique com o **botão esquerdo** na carta do campo → escolha "Ativar poder" |
| Descartar carta do campo | Clique na carta do campo → escolha "Descartar" |
| Passar o turno | Botão **"Passar Turno"** (canto superior direito) |

---

## 🔄 Fases do Turno

Cada turno possui **3 fases** que acontecem automaticamente:

### 1. 📦 Fase de Pacotes (Packet Phase)
No início do turno, **4 pacotes de rede** são gerados aleatoriamente e adicionados ao Buffer do servidor do jogador ativo. Os pacotes podem ser benignos (geram PP) ou maliciosos (causam dano).

### 2. ⚔️ Fase Principal (Main Phase)
O jogador ativo pode:
- **Invocar cartas** do campo (custo em PP)
- **Ativar poderes** das cartas já no campo (custo em PP)
- **Descartar cartas** do campo
- Aguardar os pacotes no Buffer serem processados (o servidor vai processando automaticamente em tempo real!)

### 3. 🔚 Fase de Fim de Turno (End Phase)
Ao clicar em "Passar Turno", o controle passa para o adversário.

> **Dica:** Seus pacotes continuam sendo processados **mesmo durante o turno do adversário**. Acumule PP estrategicamente!

---

## 📦 Tipos de Pacotes

Pacotes chegam ao seu servidor durante a Fase de Pacotes. Cada tipo tem características diferentes:

| Tipo | Símbolo | Efeito ao processar | Tempo | Maligno? |
|---|---|---|---|---|
| **DATA** | `DAT` | Gera **+1 PP** | 1.0s | Não |
| **VIDEO** | `VID` | Gera **+3 PP** | 3.0s | Não |
| **VOICE** | `VOI` | Gera **+2 PP** | 2.0s | Não |
| **MALWARE** | `MAL` | Causa **-10 HP** | 4.0s | ⚠️ Sim |
| **DDoS** | `DDS` | Causa **-20 HP** | 8.0s | ⚠️ Sim |

> **Buffer cheio:** Quando o Buffer (10 slots) está lotado, novos pacotes são recusados. Além disso, quanto mais cheio o Buffer, **mais lento** o servidor processa:
> - 60–79% cheio → 80% da velocidade
> - 80–99% cheio → 60% da velocidade
> - 100% cheio → 40% da velocidade

> **Firewall:** Pacotes maliciosos que atingem um servidor com Firewall consomem 1 de Firewall **em vez** de causar dano ao HP.

---

## 🃏 Cartas Disponíveis

### Beta, o Access Point Arcano
| Atributo | Valor |
|---|---|
| **Custo de Invocar** | 1 PP |
| **Custo de Ativar** | 1 PP |
| **Efeito** | Causa **2 de dano** direto ao HP do servidor inimigo |

Carta ofensiva básica. Útil para dar pressão constante no adversário.

---

### Nekros, o Switch Profano
| Atributo | Valor |
|---|---|
| **Custo de Invocar** | 2 PP |
| **Custo de Ativar** | 1 PP |
| **Efeito** | Gera **2 pacotes DATA** imediatamente no seu servidor |

Gera PP extra ao custo de encher seu Buffer. Use com cuidado quando o Buffer já estiver carregado.

---

### Oráculo DNS
| Atributo | Valor |
|---|---|
| **Custo de Invocar** | 1 PP |
| **Custo de Ativar** | 1 PP |
| **Efeito** | Adiciona **+2 de Firewall** ao seu servidor |

Carta defensiva essencial. Cada ponto de Firewall absorve um pacote malicioso sem causar dano.

---

### Ransomware Espectral
| Atributo | Valor |
|---|---|
| **Custo de Invocar** | 2 PP |
| **Custo de Ativar** | 2 PP |
| **Efeito** | Remove **3 de PP** do servidor inimigo |

Carta de controle que drena a capacidade de jogo do adversário. Impede que o oponente invoque cartas caras.

---

## 🖥️ Atributos do Servidor

| Atributo | Descrição |
|---|---|
| **HP (vida)** | Pontos de vida do servidor. Chega a 0 → derrota |
| **Buffer** | Fila de pacotes em processamento (máx. 10 por padrão) |
| **PP (Processing Power)** | Moeda para jogar e ativar cartas. Gerada pelos pacotes benignos |
| **Firewall** | Escudo contra pacotes maliciosos. Cada ponto absorve 1 pacote MAL/DDoS |
| **Pacotes Processados** | Contador total de pacotes concluídos com sucesso |

---

## 🌐 Multiplayer

### Mesma Rede Local (Wi-Fi)
1. O **Host** verifica seu IP local (`hostname -I` no terminal Linux)
2. Ambos clicam em **Iniciar Partida > Multiplayer**
3. O **Host** clica em **Criar Sala**
4. O **Cliente** digita o IP do Host e clica em **Conectar**

### Pela Internet (Redes Diferentes)
Use uma VPN P2P gratuita como o **ZeroTier**:
1. Ambos criam conta em [my.zerotier.com](https://my.zerotier.com)
2. Host cria uma rede e compartilha o **Network ID**
3. Cliente entra na rede
4. Conecte usando o IP virtual do ZeroTier normalmente

### Regras do Multiplayer
- Cada jogador vê **somente a própria mão** (cartas do adversário ficam viradas)
- O indicador no topo mostra de quem é o turno
- Apenas o jogador ativo pode arrastar e jogar cartas
- Todas as ações são **validadas pelo servidor** (Host) antes de serem aplicadas

---

## 🚀 Como Executar

### Pré-requisitos
- [Godot Engine 4.x](https://godotengine.org/)

### Rodando o projeto
```bash
# Clone o repositório
git clone <url-do-repositório>

# Abra o Godot e importe a pasta do projeto
# Ou via terminal:
godot --path ./net-defense
```

### Testando o Multiplayer localmente (duas instâncias)
No Godot Editor: **Debug > Run Multiple Instances > Run 2 Instances** e pressione **F5**.

---

## 📚 Conceitos de Redes no Jogo

O jogo é uma analogia lúdica a conceitos reais de redes:

| Elemento do Jogo | Conceito Real |
|---|---|
| Pacotes no Buffer | Filas de pacotes TCP/IP |
| Buffer cheio / lento | Congestionamento de rede |
| Firewall | Firewall de rede real |
| PP (Processing Power) | Largura de banda disponível |
| MALWARE / DDoS | Ataques reais de rede |
| DNS | Domain Name System |
| Switch / Access Point | Equipamentos de rede |
