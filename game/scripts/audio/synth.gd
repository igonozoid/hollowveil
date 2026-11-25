extends RefCounted
## Síntese de toda a trilha e dos efeitos. Funções estáticas que devolvem
## amostras em ponto flutuante (mono, RATE Hz). Sem nenhum arquivo externo.

const RATE := 22050

const MINOR := [0, 2, 3, 5, 7, 8, 10]
const HARM := [0, 2, 3, 5, 7, 8, 11]
const PHRYG := [0, 1, 3, 5, 7, 8, 10]
const LOCRIAN := [0, 1, 3, 5, 6, 8, 10]

## Receitas das faixas. prog = graus por compasso; voices = camadas.
const TRACKS := {
	"menu": {"bpm": 58, "root": 45, "scale": HARM, "prog": [0, 5, 3, 4, 0, 5, 1, 4],
		"voices": ["organ", "musicbox", "choir"], "tick": false, "seed": 7},
	"terreo": {"bpm": 64, "root": 43, "scale": HARM, "prog": [0, 0, 5, 4, 3, 1, 4, 4],
		"voices": ["cello", "harpsi", "pad"], "tick": true, "seed": 13},
	"enigma": {"bpm": 72, "root": 40, "scale": PHRYG, "prog": [0, 1, 0, 6, 0, 1, 3, 1],
		"voices": ["drone", "glass", "pulse"], "tick": true, "seed": 29},
	"quartos": {"bpm": 54, "root": 44, "scale": MINOR, "prog": [0, 3, 5, 4, 0, 3, 1, 4],
		"voices": ["pad", "musicbox", "cello"], "tick": false, "seed": 37},
	"fantasma": {"bpm": 50, "root": 38, "scale": LOCRIAN, "prog": [0, 1, 0, 4, 0, 1, 6, 4],
		"voices": ["cluster", "heart", "choir"], "tick": false, "seed": 31},
	"poroes": {"bpm": 44, "root": 36, "scale": PHRYG, "prog": [0, 1, 0, 5, 0, 1, 6, 0],
		"voices": ["drone", "chant", "drips"], "tick": false, "seed": 43},
}


static func hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


static func degree(spec: Dictionary, deg: int, octave: int = 0) -> int:
	var sc: Array = spec["scale"]
	var o := octave + floori(float(deg) / sc.size())
	return int(spec["root"]) + int(sc[posmod(deg, sc.size())]) + 12 * o


# ================================================================ música

static func render_track(spec: Dictionary) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(spec["seed"])
	var beat := 60.0 / float(spec["bpm"])
	var prog: Array = spec["prog"]
	var bars := prog.size() * 2
	var total := int(bars * 4.0 * beat * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var voices: Array = spec["voices"]
	for bar in bars:
		var t0 := bar * 4.0 * beat
		var d: int = prog[bar % prog.size()]
		var chord := [degree(spec, d), degree(spec, d + 2), degree(spec, d + 4)]
		var second := bar >= prog.size()
		for v in voices:
			match v:
				"organ":
					for n in chord:
						_tone(buf, t0, 4.0 * beat, hz(n), 0.05, "organ")
					_tone(buf, t0, 4.0 * beat, hz(chord[0] - 12), 0.05, "organ")
				"pad":
					for n in chord:
						_tone(buf, t0, 4.0 * beat, hz(n + 12), 0.03, "pad")
				"choir":
					for n in [chord[0] + 12, chord[2] + 12]:
						_tone(buf, t0 + 0.05, 4.0 * beat, hz(n), 0.035, "choir")
				"drone":
					_tone(buf, t0, 4.0 * beat, hz(int(spec["root"]) - 12), 0.09, "cello")
					_tone(buf, t0, 4.0 * beat, hz(int(spec["root"]) - 5), 0.04, "cello")
				"cello":
					var line := [chord[0] - 12, chord[0] - 12, chord[2] - 24, chord[1] - 12]
					for i in 4:
						_tone(buf, t0 + i * beat, beat * 1.1, hz(line[i]), 0.1, "cello")
				"cluster":
					var base := degree(spec, d) + 12
					for k in [0, 1, 6, 11]:
						_tone(buf, t0, 4.0 * beat, hz(base + k), 0.03, "strings")
				"heart":
					for i in 2:
						_thump(buf, t0 + i * 2.0 * beat, 0.45)
						_thump(buf, t0 + i * 2.0 * beat + 0.22, 0.3)
				"harpsi":
					var arp := [chord[0] + 12, chord[1] + 12, chord[2] + 12, chord[1] + 12,
						chord[0] + 24, chord[2] + 12, chord[1] + 12, chord[2]]
					if second:
						arp.reverse()
					for i in 8:
						if rng.randf() < 0.85:
							_tone(buf, t0 + i * beat * 0.5, beat * 0.9, hz(arp[i]), 0.06, "harpsi")
				"musicbox":
					for i in 8:
						if rng.randf() < 0.7:
							var note := degree(spec, d + [0, 2, 4, 7, 9, 4, 2, 7][i], 2)
							# Caixa de música velha: um quarto de tom fora.
							_tone(buf, t0 + i * beat * 0.5, beat * 2.0, hz(note + rng.randf_range(-0.35, 0.35)), 0.07, "bell")
				"glass":
					if bar % 2 == 0:
						var gn := degree(spec, d + rng.randi_range(0, 6), 2)
						_tone(buf, t0 + rng.randi_range(0, 3) * beat, beat * 3.0, hz(gn), 0.05, "bell")
				"chant":
					# Cantochão: uma linha só, em graus vizinhos, como um padre que reza sozinho.
					var deg := d + 2
					for i in 4:
						deg = clampi(deg + rng.randi_range(-1, 1), d, d + 5)
						if rng.randf() < 0.8:
							_tone(buf, t0 + i * beat + 0.04, beat * 1.05, hz(degree(spec, deg, 1)), 0.05, "choir")
				"drips":
					for i in rng.randi_range(0, 2):
						_drop(buf, t0 + rng.randf() * 4.0 * beat, 0.09, rng.randf_range(900.0, 1700.0))
				"pulse":
					for i in 4:
						_tone(buf, t0 + i * beat, beat * 0.3, hz(chord[0] - 24), 0.12, "pluckbass")
		if bool(spec.get("tick", false)):
			for i in 4:
				_click(buf, t0 + i * beat, 0.05 if i % 2 == 0 else 0.035)
	_reverb(buf, 0.42, 0.35)
	_normalize(buf, 0.8)
	return buf


static func _tone(buf: PackedFloat32Array, t0: float, dur: float, f: float, amp: float, kind: String) -> void:
	var start := int(t0 * RATE)
	var rel := 0.25 if kind in ["organ", "pad", "choir", "strings", "cello"] else 0.0
	var n := int((dur + rel) * RATE)
	var size := buf.size()
	var ph := 0.0
	var ph2 := 0.0
	var ph3 := 0.0
	var inc := TAU * f / RATE
	# Pesos do "ah" do coro: dependem só da nota, então saem do laço.
	var cw := PackedFloat32Array()
	if kind == "choir":
		for h in range(1, 9):
			var hf := f * h
			cw.append(exp(-pow((hf - 720.0) / 220.0, 2.0)) + 0.7 * exp(-pow((hf - 1150.0) / 260.0, 2.0)) + 0.2 / h)
	for i in n:
		var idx := start + i
		if idx >= size:
			idx -= size  # dá a volta: a faixa repete sem emenda
		var t := float(i) / RATE
		var env := 1.0
		var s := 0.0
		match kind:
			"organ":
				env = minf(t / 0.08, 1.0) * (1.0 if t < dur else maxf(0.0, 1.0 - (t - dur) / rel))
				s = sin(ph) + 0.5 * sin(ph * 2.0) + 0.3 * sin(ph * 3.0) + 0.2 * sin(ph * 4.0) + 0.12 * sin(ph * 6.0)
				s *= 0.5
			"pad", "strings":
				env = minf(t / 0.6, 1.0) * (1.0 if t < dur else maxf(0.0, 1.0 - (t - dur) / rel))
				var vib := 1.0 + 0.004 * sin(t * 5.5)
				s = _saw(ph * vib) * 0.4 + _saw(ph2 * 1.006) * 0.4
				s = s * 0.6 + sin(ph) * 0.4
			"choir":
				env = minf(t / 0.7, 1.0) * (1.0 if t < dur else maxf(0.0, 1.0 - (t - dur) / rel))
				# "Ah" sintético: harmônicos realçados perto de 700 e 1100 Hz.
				var vib2 := 1.0 + 0.006 * sin(t * 4.8 + f)
				var pv := ph * vib2
				for h in 8:
					s += sin(pv * (h + 1)) * cw[h]
				s *= 0.35
			"cello":
				env = minf(t / 0.12, 1.0) * (1.0 if t < dur else maxf(0.0, 1.0 - (t - dur) / rel))
				var vib3 := 1.0 + 0.007 * sin(t * 5.0)
				s = _saw(ph * vib3) * 0.55 + sin(ph * vib3) * 0.45
			"harpsi":
				env = exp(-t * 4.5)
				s = _saw(ph) * 0.4 + _sq(ph2) * 0.25 + sin(ph * 2.0) * 0.2
			"bell":
				env = exp(-t * 2.2)
				s = sin(ph) + 0.45 * sin(ph * 2.76) + 0.25 * sin(ph * 5.4) * exp(-t * 6.0)
				s *= 0.6
			"pluckbass":
				env = exp(-t * 8.0)
				s = sin(ph) + 0.4 * sin(ph * 2.0)
		buf[idx] += s * env * amp
		ph += inc
		ph2 += inc * 2.0
		ph3 += inc * 0.5


static func _thump(buf: PackedFloat32Array, t0: float, amp: float) -> void:
	var start := int(t0 * RATE)
	for i in int(0.25 * RATE):
		var idx := (start + i) % buf.size()
		var t := float(i) / RATE
		var f := 55.0 * exp(-t * 6.0) + 32.0
		buf[idx] += sin(TAU * f * t) * exp(-t * 14.0) * amp


## Gota d'água numa poça: um "plim" que sobe de tom.
static func _drop(buf: PackedFloat32Array, t0: float, amp: float, f0: float) -> void:
	var start := int(t0 * RATE)
	var ph := 0.0
	for i in int(0.12 * RATE):
		var idx := (start + i) % buf.size()
		var t := float(i) / RATE
		ph += TAU * f0 * (1.0 + t * 9.0) / RATE
		buf[idx] += sin(ph) * exp(-t * 45.0) * amp


static func _click(buf: PackedFloat32Array, t0: float, amp: float) -> void:
	var start := int(t0 * RATE)
	for i in int(0.025 * RATE):
		var idx := (start + i) % buf.size()
		var t := float(i) / RATE
		buf[idx] += sin(TAU * 2400.0 * t) * exp(-t * 300.0) * amp + sin(TAU * 900.0 * t) * exp(-t * 200.0) * amp * 0.5


# ================================================================ ajudantes DSP

static func _saw(ph: float) -> float:
	return fposmod(ph / TAU, 1.0) * 2.0 - 1.0


static func _sq(ph: float) -> float:
	return 1.0 if fposmod(ph, TAU) < PI else -1.0


## Reverb de Schroeder (quatro pentes e dois passa-tudo), circular.
static func _reverb(buf: PackedFloat32Array, mix: float, decay: float) -> void:
	var n := buf.size()
	var out := PackedFloat32Array()
	out.resize(n)
	var combs := [1557, 1617, 1491, 1422]
	for c in combs:
		var line := PackedFloat32Array()
		line.resize(c)
		var pos := 0
		var fb := 0.72 + decay * 0.2
		var lp := 0.0
		# Duas passadas: a primeira aquece a cauda para o loop não "estalar".
		for pass_i in 2:
			for i in n:
				var y := line[pos]
				lp = y * 0.6 + lp * 0.4
				line[pos] = buf[i] + lp * fb
				pos = (pos + 1) % c
				if pass_i == 1:
					out[i] += y * 0.25
	for a in [225, 556]:
		var aline := PackedFloat32Array()
		aline.resize(a)
		var p := 0
		for i in n:
			var b := aline[p]
			var x := out[i]
			var y2 := -x + b
			aline[p] = x + b * 0.5
			out[i] = y2
			p = (p + 1) % a
	for i in n:
		buf[i] = buf[i] * (1.0 - mix * 0.5) + out[i] * mix


static func _normalize(buf: PackedFloat32Array, peak: float) -> void:
	var m := 0.0001
	for v in buf:
		m = maxf(m, absf(v))
	var k := peak / m
	for i in buf.size():
		buf[i] = tanh(buf[i] * k * 1.1) * 0.95


static func to_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


# ================================================================ efeitos

static func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## Ruído filtrado (passa-baixa de um polo) — base de quase todo efeito.
class Hiss:
	var lp := 0.0
	var lp2 := 0.0
	var rng := RandomNumberGenerator.new()

	func _init(s: int = 1) -> void:
		rng.seed = s

	func white() -> float:
		return rng.randf() * 2.0 - 1.0

	func low(cut: float) -> float:
		lp += (white() - lp) * cut
		return lp

	func band(cut_lo: float, cut_hi: float) -> float:
		lp += (white() - lp) * cut_hi
		lp2 += (lp - lp2) * cut_lo
		return lp - lp2


static func make(name: String) -> PackedFloat32Array:
	match name:
		"step":
			return _fx_step(1)
		"step2":
			return _fx_step(2)
		"door":
			return _fx_creak(1.3, 3)
		"creak":
			return _fx_creak(0.8, 9)
		"locked":
			return _fx_rattle()
		"slam":
			return _fx_slam()
		"squelch":
			return _fx_squelch(0.35, 1.0)
		"splat":
			return _fx_squelch(0.18, 1.6)
		"pop":
			return _fx_pop()
		"heart":
			return _fx_heart()
		"whisper":
			return _fx_whisper(2.2)
		"sting":
			return _fx_sting()
		"thunder":
			return _fx_thunder()
		"tile":
			return _fx_tile()
		"card":
			return _fx_card()
		"saw":
			return _fx_saw()
		"cough":
			return _fx_cough()
		"scream":
			return _fx_scream()
		"laugh":
			return _fx_laugh()
		"solved":
			return _fx_solved()
		"wrong":
			return _fx_wrong()
		"candle":
			return _fx_candle()
		"planchette":
			return _fx_planchette()
		"crunch":
			return _fx_crunch()
		"hover":
			return _fx_hover()
		"tick":
			var b := _buf(0.05)
			_click(b, 0.0, 0.6)
			return b
		"wind":
			return _fx_wind()
		"drip":
			var b2 := _buf(0.5)
			_drop(b2, 0.0, 0.7, 1300.0)
			_reverb(b2, 0.6, 0.6)
			return b2
		"bell":
			return _fx_bell()
		"ice":
			return _fx_ice()
		"cry":
			return _fx_cry()
	return _buf(0.05)


static func _env_ar(t: float, a: float, d: float) -> float:
	return minf(t / maxf(a, 0.0001), 1.0) * exp(-maxf(t - a, 0.0) * d)


static func _fx_step(v: int) -> PackedFloat32Array:
	var b := _buf(0.35)
	var nz := Hiss.new(v * 17)
	for i in b.size():
		var t := float(i) / RATE
		var thud := sin(TAU * (70.0 + v * 8.0) * t) * exp(-t * 30.0)
		var board := nz.low(0.25) * exp(-t * 40.0) * 0.8
		# Rangido curto da tábua.
		var cr := sin(TAU * (380.0 + 60.0 * sin(t * 40.0)) * t) * _env_ar(t - 0.05, 0.02, 18.0) * 0.12 if t > 0.05 else 0.0
		b[i] = (thud * 0.9 + board + cr) * 0.8
	return b


static func _fx_creak(seconds: float, s: int) -> PackedFloat32Array:
	var b := _buf(seconds)
	var nz := Hiss.new(s)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := t / seconds
		var f := 180.0 + 220.0 * sin(k * PI * 1.3) + 40.0 * sin(t * 37.0)
		ph += TAU * f / RATE
		# Atrito: pulsos irregulares (stick-slip).
		var grain := 1.0 if nz.white() > 0.2 else 0.3
		var env := sin(k * PI) * 0.9
		b[i] = (_saw(ph) * 0.5 + sin(ph * 2.0) * 0.3) * grain * env * 0.45 + nz.low(0.1) * 0.08 * env
	return b


static func _fx_rattle() -> PackedFloat32Array:
	var b := _buf(0.6)
	var nz := Hiss.new(5)
	for i in b.size():
		var t := float(i) / RATE
		var pulses := absf(sin(t * TAU * 11.0))
		var metal := sin(TAU * 1250.0 * t) * 0.3 + sin(TAU * 2310.0 * t) * 0.2 + nz.band(0.05, 0.6) * 0.5
		b[i] = metal * pow(pulses, 8.0) * exp(-t * 4.0) * 0.8 + sin(TAU * 90.0 * t) * pow(pulses, 12.0) * 0.4 * exp(-t * 3.0)
	return b


static func _fx_slam() -> PackedFloat32Array:
	var b := _buf(1.4)
	var nz := Hiss.new(8)
	for i in b.size():
		var t := float(i) / RATE
		var boom := sin(TAU * (60.0 * exp(-t * 3.0) + 28.0) * t) * exp(-t * 4.0)
		b[i] = boom * 0.9 + nz.low(0.3) * exp(-t * 18.0) * 0.8 + nz.low(0.03) * exp(-t * 2.0) * 0.3
	return b


static func _fx_squelch(seconds: float, pitch: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	var nz := Hiss.new(int(pitch * 100))
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := (260.0 - 180.0 * t / seconds) * pitch
		ph += TAU * f / RATE
		var wet := nz.band(0.08, 0.5) * (0.6 + 0.4 * sin(ph))
		b[i] = (wet + sin(ph * 0.5) * 0.3) * _env_ar(t, 0.005, 7.0 / seconds) * 0.9
	return b


static func _fx_pop() -> PackedFloat32Array:
	var b := _buf(0.4)
	var nz := Hiss.new(3)
	for i in b.size():
		var t := float(i) / RATE
		var bubble := sin(TAU * (900.0 * exp(-t * 25.0) + 120.0) * t) * exp(-t * 30.0)
		b[i] = bubble * 0.6 + nz.band(0.1, 0.7) * exp(-t * 12.0) * 0.6
	return b


static func _fx_heart() -> PackedFloat32Array:
	var b := _buf(0.9)
	_thump(b, 0.0, 0.9)
	_thump(b, 0.24, 0.65)
	return b


static func _fx_whisper(seconds: float) -> PackedFloat32Array:
	var b := _buf(seconds)
	var nz := Hiss.new(21)
	var nz2 := Hiss.new(22)
	for i in b.size():
		var t := float(i) / RATE
		# Sílabas: envelope que abre e fecha, formante que se move.
		var syll := maxf(0.0, sin(t * TAU * 3.3 + sin(t * 2.0) * 2.0))
		var hiss := nz.band(0.15 + 0.1 * sin(t * 7.0), 0.75) * 0.7 + nz2.band(0.4, 0.95) * 0.3
		b[i] = hiss * pow(syll, 1.5) * sin(PI * t / seconds) * 0.7
	return b


static func _fx_sting() -> PackedFloat32Array:
	var b := _buf(2.6)
	var nz := Hiss.new(4)
	var notes := [hz(50), hz(51), hz(57), hz(62), hz(63), hz(74)]
	var phs := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for k in notes.size():
			phs[k] += TAU * notes[k] * (1.0 + 0.01 * sin(t * (6.0 + k))) / RATE
			s += _saw(phs[k]) * 0.16
		var env := _env_ar(t, 0.04, 1.4)
		b[i] = s * env + nz.low(0.4) * exp(-t * 8.0) * 0.4
	return b


static func _fx_thunder() -> PackedFloat32Array:
	var b := _buf(4.0)
	var nz := Hiss.new(31)
	var nz2 := Hiss.new(32)
	for i in b.size():
		var t := float(i) / RATE
		var crack := nz.low(0.5) * exp(-t * 6.0) * 0.6
		var roll := nz2.low(0.012) * 6.0 * (0.6 + 0.4 * sin(t * 3.0)) * exp(-t * 0.8)
		b[i] = (crack + roll) * minf(t / 0.02, 1.0)
	return b


static func _fx_tile() -> PackedFloat32Array:
	var b := _buf(0.12)
	var nz := Hiss.new(41)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 620.0 * t) * 0.5 + nz.band(0.2, 0.8) * 0.5) * exp(-t * 60.0)
	return b


static func _fx_card() -> PackedFloat32Array:
	var b := _buf(0.18)
	var nz := Hiss.new(43)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = nz.band(0.3, 0.95) * _env_ar(t, 0.01, 25.0) * 0.6
	return b


static func _fx_saw() -> PackedFloat32Array:
	var b := _buf(2.4)
	var nz := Hiss.new(47)
	for i in b.size():
		var t := float(i) / RATE
		var stroke := absf(sin(t * TAU * 2.2))
		var teeth := absf(sin(t * TAU * (90.0 + 60.0 * stroke)))
		var rasp := nz.band(0.08, 0.7) * pow(teeth, 3.0)
		var bone := sin(TAU * 140.0 * t) * pow(teeth, 6.0) * 0.4
		b[i] = (rasp + bone) * (0.3 + 0.7 * stroke) * 0.8
	return b


static func _fx_cough() -> PackedFloat32Array:
	var b := _buf(1.1)
	var nz := Hiss.new(53)
	for i in b.size():
		var t := float(i) / RATE
		var e := 0.0
		for k in 3:
			var tk := t - k * 0.3
			if tk > 0.0:
				e += _env_ar(tk, 0.01, 14.0)
		var voice := sin(TAU * 140.0 * t) * 0.2
		b[i] = (nz.band(0.06, 0.45) * 0.9 + voice) * e * 0.8
	return b


static func _fx_scream() -> PackedFloat32Array:
	var b := _buf(2.2)
	var nz := Hiss.new(59)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 520.0 + 180.0 * sin(t * 2.0) - 160.0 * t + 25.0 * sin(t * 34.0)
		ph += TAU * f / RATE
		var s := 0.0
		for h in range(1, 7):
			var hf := f * h
			s += sin(ph * h) * (exp(-pow((hf - 900.0) / 300.0, 2.0)) + 0.6 * exp(-pow((hf - 2600.0) / 500.0, 2.0)) + 0.1)
		var env := _env_ar(t, 0.08, 0.9)
		b[i] = (s * 0.35 + nz.band(0.2, 0.8) * 0.25) * env
	return b


static func _fx_laugh() -> PackedFloat32Array:
	var b := _buf(2.6)
	var nz := Hiss.new(61)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := floorf(t / 0.24)
		var local := t - k * 0.24
		var f := (150.0 - k * 9.0) * (1.0 - local * 0.6)
		ph += TAU * f / RATE
		var s := 0.0
		for h in range(1, 10):
			var hf := f * h
			s += sin(ph * h) * (exp(-pow((hf - 650.0) / 200.0, 2.0)) + 0.8 * exp(-pow((hf - 1080.0) / 220.0, 2.0)) + 0.25 / h)
		var syll := _env_ar(local, 0.015, 11.0) if k < 9.0 else 0.0
		b[i] = (s * 0.3 + nz.band(0.1, 0.6) * 0.15) * syll * (1.0 - t / 2.8)
	return b


static func _fx_solved() -> PackedFloat32Array:
	var b := _buf(3.0)
	for n in [57, 60, 64, 69, 72]:
		_bell_into(b, 0.12 * [57, 60, 64, 69, 72].find(n), hz(n), 0.22)
	return b


static func _bell_into(b: PackedFloat32Array, t0: float, f: float, amp: float) -> void:
	var start := int(t0 * RATE)
	for i in range(start, b.size()):
		var t := float(i - start) / RATE
		b[i] += (sin(TAU * f * t) + 0.5 * sin(TAU * f * 2.76 * t) * exp(-t * 3.0)) * exp(-t * 1.6) * amp


static func _fx_wrong() -> PackedFloat32Array:
	var b := _buf(1.5)
	for i in b.size():
		var t := float(i) / RATE
		var s := _saw(TAU * hz(40) * t) * 0.3 + _saw(TAU * hz(41) * t) * 0.3 + sin(TAU * hz(28) * t) * 0.4
		b[i] = s * _env_ar(t, 0.03, 2.2) * 0.7
	return b


static func _fx_candle() -> PackedFloat32Array:
	var b := _buf(0.7)
	var nz := Hiss.new(67)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = nz.low(0.05 + 0.1 * t) * _env_ar(t, 0.05, 5.0) * 2.2
	return b


static func _fx_planchette() -> PackedFloat32Array:
	var b := _buf(1.2)
	var nz := Hiss.new(71)
	for i in b.size():
		var t := float(i) / RATE
		var move := sin(PI * t / 1.2)
		b[i] = nz.band(0.02, 0.2) * move * 1.4 + sin(TAU * 98.0 * t) * move * 0.05
	return b


static func _fx_crunch() -> PackedFloat32Array:
	var b := _buf(0.6)
	var nz := Hiss.new(73)
	for i in b.size():
		var t := float(i) / RATE
		var cr := 1.0 if nz.white() > 0.6 else 0.0
		b[i] = (nz.band(0.1, 0.9) * cr * 0.7 + sin(TAU * 110.0 * t) * 0.3) * exp(-t * 6.0)
	return b


static func _fx_hover() -> PackedFloat32Array:
	var b := _buf(0.08)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 1800.0 * t) * exp(-t * 80.0) * 0.15
	return b


static func _fx_wind() -> PackedFloat32Array:
	var seconds := 12.0
	var b := _buf(seconds)
	var nz := Hiss.new(79)
	var nz2 := Hiss.new(80)
	for i in b.size():
		var t := float(i) / RATE
		var gust := 0.5 + 0.3 * sin(TAU * t / seconds) + 0.2 * sin(TAU * t * 3.0 / seconds + 1.0)
		var howl := sin(TAU * (240.0 + 60.0 * sin(TAU * t * 2.0 / seconds)) * t) * 0.04 * gust
		b[i] = (nz.low(0.02 + 0.03 * gust) * 3.0 + nz2.band(0.1, 0.3) * 0.15) * gust + howl
	# Cruzamento das pontas para o laço não estalar.
	var x := int(0.5 * RATE)
	for i in x:
		var k := float(i) / x
		b[i] = b[i] * k + b[b.size() - x + i] * (1.0 - k)
	b.resize(b.size() - x)
	return b


## Sino de capela, grave e rachado.
static func _fx_bell() -> PackedFloat32Array:
	var b := _buf(3.0)
	for i in b.size():
		var t := float(i) / RATE
		var f := 196.0
		var s := sin(TAU * f * t) + 0.6 * sin(TAU * f * 2.41 * t) * exp(-t * 1.5) + 0.4 * sin(TAU * f * 3.02 * t + sin(t * 9.0)) * exp(-t * 2.5) + 0.3 * sin(TAU * f * 0.5 * t)
		b[i] = s * exp(-t * 1.3) * minf(t / 0.004, 1.0) * 0.4
	return b


## Gelo rachando: estalos secos em rajada.
static func _fx_ice() -> PackedFloat32Array:
	var b := _buf(0.7)
	var nz := Hiss.new(21)
	var next := 0.0
	var amp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		if t >= next:
			amp = nz.rng.randf_range(0.4, 1.0) * exp(-t * 3.0)
			next = t + nz.rng.randf_range(0.01, 0.09)
		amp *= 0.993
		b[i] = nz.band(0.2, 0.9) * amp * 0.8
	return b


## Choro de bebê, longe: "uéé" em formante, com soluço no fim.
static func _fx_cry() -> PackedFloat32Array:
	var b := _buf(2.4)
	var nz := Hiss.new(31)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var cyc := fmod(t, 0.8)
		var f := 430.0 + 90.0 * sin(cyc / 0.8 * PI) + 12.0 * sin(t * 38.0)
		ph += TAU * f / RATE
		var env := sin(minf(cyc / 0.62, 1.0) * PI) if cyc < 0.62 else 0.0
		# Formantes de "é": realça harmônicos perto de 600 e 2000 Hz.
		var s := 0.0
		for h in range(1, 7):
			var hf := f * h
			var wgt := exp(-pow((hf - 600.0) / 250.0, 2.0)) + 0.6 * exp(-pow((hf - 2000.0) / 400.0, 2.0)) + 0.15 / h
			s += sin(ph * h) * wgt
		b[i] = (s * 0.3 + nz.band(0.2, 0.8) * 0.05) * env * (1.0 - t / 2.6)
	_reverb(b, 0.7, 0.7)
	return b
