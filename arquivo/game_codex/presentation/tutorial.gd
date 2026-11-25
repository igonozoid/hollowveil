extends RefCounted

const GUIDE := """
1. Ande com A/D ou ←/→. Quando aparecer o nome de um objeto, pressione E para examiná-lo.
2. Leia o painel de rondas e memorize a ordem das marcas. Procure o relógio à direita.
3. No close-up, gire os anéis e teste a combinação. Use mouse ou Tab e Enter. Esc fecha a vista e guarda o rascunho.
4. Leia o registro do relógio. Atravesse a porta liberada e desça pela esquerda do patamar.
5. Nas alas seguintes, procure as instruções antes de testar cada mecanismo. Use M para se localizar.
"""
const FIRST_STEPS := [
	"Ande com A/D ou ←/→. Leia o painel de rondas com E.",
	"Procure o relógio. Alinhe os anéis pela ordem do painel.",
	"Volte quando quiser. Esc fecha o relógio e guarda o rascunho."
]

static func objective(chapter: int, step: int, solved: bool, record_read: bool, landing: bool) -> String:
	if landing:
		return "Vá à esquerda para descer à galeria. A direita volta ao corredor."
	if chapter == 3:
		return ""
	if chapter in [1,2]:
		return "Atravesse a saída liberada." if solved else "Leia as instruções desta ala e examine o mecanismo."
	if solved:
		return "Atravesse a porta do patamar." if record_read else "Leia o registro no compartimento do relógio."
	return FIRST_STEPS[step]
