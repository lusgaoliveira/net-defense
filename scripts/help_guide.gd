extends Control

# Conteúdo das páginas do guia
const PAGES := [
	{
		"title": "🎮  Como Jogar",
		"content": """Objetivo: Reduza o HP do servidor inimigo a 0 antes que o seu chegue a zero.

Cada jogador controla um Servidor com vida (HP), um Buffer de Pacotes e um Campo onde cartas com poderes especiais são invocadas.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONTROLES

▶  Jogar carta no campo
      Arraste a carta da mão para um slot no campo

▶  Ver detalhes da carta
      Clique com o botão DIREITO sobre ela

▶  Ativar / Descartar carta no campo
      Clique com o botão ESQUERDO na carta do campo
      e escolha a ação no menu

▶  Passar o turno
      Botão "Passar Turno" no canto da tela"""
	},
	{
		"title": "🔄  Fases do Turno",
		"content": """Cada turno possui 3 fases automáticas:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦  1. FASE DE PACOTES

No início do turno, 4 pacotes de rede são gerados aleatoriamente e entram no Buffer do jogador ativo.

Pacotes benignos geram PP quando processados.
Pacotes maliciosos causam dano ao HP quando terminam.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚔️  2. FASE PRINCIPAL

O jogador ativo pode:
  • Invocar cartas do campo (custa PP)
  • Ativar poderes de cartas no campo (custa PP)
  • Descartar cartas do campo
  • Esperar os pacotes do Buffer serem processados
    em tempo real!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔚  3. FASE DE FIM

Ao clicar em "Passar Turno", o controle vai ao adversário.

💡 DICA: Seus pacotes continuam sendo processados
mesmo durante o turno do oponente!"""
	},
	{
		"title": "📦  Tipos de Pacotes",
		"content": """Pacotes chegam ao seu servidor e ficam no Buffer até serem processados:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DAT  DATA
      Benigno  •  Tempo: 1.0s  •  Gera +1 PP

VID  VIDEO
      Benigno  •  Tempo: 3.0s  •  Gera +3 PP

VOI  VOICE
      Benigno  •  Tempo: 2.0s  •  Gera +2 PP

MAL  ⚠ MALWARE
      Malicioso  •  Tempo: 4.0s  •  Causa -10 HP

DDS  ⚠ DDoS
      Malicioso  •  Tempo: 8.0s  •  Causa -20 HP

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CONGESTIONAMENTO

Quando o Buffer está muito cheio, o processamento
fica mais lento:

  60–79% cheio  →  80% velocidade
  80–99% cheio  →  60% velocidade
  100% cheio    →  40% velocidade

FIREWALL: Cada ponto absorve 1 pacote malicioso
sem causar dano ao HP."""
	},
	{
		"title": "🃏  Cartas — Parte 1",
		"content": """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ BETA, O ACCESS POINT ARCANO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Custo de Invocar:  1 PP
Custo de Ativar:   1 PP

Efeito:
Causa 2 de dano direto ao HP do servidor inimigo.

Estratégia:
Carta ofensiva básica. Ideal para pressionar
o adversário constantemente ao longo da partida.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔀 NEKROS, O SWITCH PROFANO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Custo de Invocar:  2 PP
Custo de Ativar:   1 PP

Efeito:
Gera 2 pacotes DATA imediatamente no seu servidor.

Estratégia:
Acelera a geração de PP, mas enche o Buffer.
Use quando o Buffer ainda tem espaço livre."""
	},
	{
		"title": "🃏  Cartas — Parte 2",
		"content": """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️ ORÁCULO DNS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Custo de Invocar:  1 PP
Custo de Ativar:   1 PP

Efeito:
Adiciona +2 de Firewall ao seu servidor.

Estratégia:
Defesa essencial contra ataques MALWARE e DDoS.
Cada ponto de Firewall absorve um pacote malicioso
sem causar dano ao HP.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💀 RANSOMWARE ESPECTRAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Custo de Invocar:  2 PP
Custo de Ativar:   2 PP

Efeito:
Remove 3 de PP do servidor inimigo.

Estratégia:
Carta de controle poderosa. Drena a capacidade
do adversário de invocar cartas caras, travando
sua estratégia."""
	},
	{
		"title": "🖥️  Atributos do Servidor",
		"content": """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❤️  HP  (Pontos de Vida)
      Vida do servidor. Ao chegar a 0, você perde.
      Valor inicial: 1000

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦  BUFFER
      Fila de pacotes sendo processados.
      Capacidade máxima: 10 pacotes.
      Buffer cheio = processamento mais lento.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚡  PP  (Processing Power)
      Moeda do jogo. Usada para invocar e
      ativar cartas. Gerada pelos pacotes
      benignos quando processados.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔒  FIREWALL
      Escudo contra ataques. Cada ponto de
      Firewall absorve 1 pacote malicioso
      sem dano ao HP.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊  PACOTES PROCESSADOS
      Contador total de pacotes concluídos
      com sucesso pelo seu servidor."""
	},
	{
		"title": "🌐  Multiplayer",
		"content": """━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MESMA REDE LOCAL (Wi-Fi)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. O Host descobre seu IP local
   (no terminal: hostname -I)

2. Ambos clicam em:
   Iniciar Partida → Multiplayer

3. Host clica em Criar Sala

4. Cliente digita o IP do Host
   e clica em Conectar

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PELA INTERNET (ZeroTier)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Ambos criam conta em my.zerotier.com

2. Host cria uma rede e compartilha
   o Network ID

3. Cliente entra na rede

4. Conecte pelo IP virtual do ZeroTier

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REGRAS DO MULTIPLAYER

• Você vê apenas a sua própria mão
• Cartas do adversário ficam viradas
• O indicador no topo mostra o turno atual
• Ações são validadas pelo servidor (Host)"""
	},
]

var current_page := 0

@onready var title_label: Label = $Panel/VBox/title_label
@onready var content_label: Label = $Panel/VBox/ScrollContainer/content_label
@onready var page_label: Label = $Panel/VBox/nav/page_label
@onready var prev_button: Button = $Panel/VBox/nav/prev_button
@onready var next_button: Button = $Panel/VBox/nav/next_button
@onready var close_button: Button = $Panel/VBox/close_button


func _ready() -> void:
	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)
	close_button.pressed.connect(_on_close)
	_show_page(0)


func _show_page(index: int) -> void:
	current_page = index
	var page = PAGES[index]
	title_label.text = page["title"]
	content_label.text = page["content"]
	page_label.text = "%d / %d" % [index + 1, PAGES.size()]
	prev_button.disabled = (index == 0)
	next_button.disabled = (index == PAGES.size() - 1)
	$Panel/VBox/ScrollContainer.scroll_vertical = 0


func _on_prev() -> void:
	if current_page > 0:
		_show_page(current_page - 1)


func _on_next() -> void:
	if current_page < PAGES.size() - 1:
		_show_page(current_page + 1)


func _on_close() -> void:
	queue_free()
