extends Resource
class_name Server

signal packet_processed(packet: Packet)
signal packet_added(packet: Packet)
signal server_damaged(amount: int)
signal throughput_gained(amount: int)

# =========================
# ATRIBUTOS PRINCIPAIS
# =========================
var hp: int = 1000
# protege contra pacotes maliciosos
var firewall: int = 0
# recurso para jogar cartas
var processing_power: int = 0
# quantidade total processada
var processed_packets: int = 0
# tamanho máximo da fila
var buffer_size: int = 10
# velocidade de processamento
var processing_speed: float = 1.0
# fila de pacotes
var buffer: Array[Packet] = []

# =========================
# BUFFER
# =========================
func add_packet(packet: Packet) -> bool:
	if buffer.size() >= buffer_size:
		return false
	buffer.append(packet)
	packet_added.emit(packet)
	return true


func remove_packet(packet: Packet) -> void:
	buffer.erase(packet)


func buffer_usage() -> float:
	if buffer_size == 0:
		return 0.0
	return float(buffer.size()) / float(buffer_size)


func is_buffer_full() -> bool:
	return buffer.size() >= buffer_size


# =========================
# PROCESSAMENTO
# =========================
func update_processing(delta: float) -> void:
	if buffer.is_empty():
		return
	var multiplier := get_processing_multiplier()
	for packet in buffer:
		packet.remaining_time -= delta * processing_speed * multiplier

	var completed: Array[Packet] = []
	for packet in buffer:
		if packet.remaining_time <= 0:
			completed.append(packet)

	for packet in completed:
		_finish_packet(packet)


func _finish_packet(packet: Packet) -> void:
	buffer.erase(packet)
	if packet.is_malicious:
		if firewall > 0:
			firewall -= 1
		else:
			hp -= packet.damage
			server_damaged.emit(packet.damage)
	else:
		processing_power += packet.throughput_value
		processed_packets += 1
		throughput_gained.emit(packet.throughput_value)
	packet_processed.emit(packet)


# =========================
# CONGESTIONAMENTO
# =========================
func get_processing_multiplier() -> float:
	var usage := buffer_usage()
	if usage >= 1.0:
		return 0.4
	if usage >= 0.8:
		return 0.6
	if usage >= 0.6:
		return 0.8
	return 1.0


# =========================
# MELHORIAS
# =========================
func add_firewall(amount: int) -> void:
	firewall += amount


func add_processing_speed(amount: float) -> void:
	processing_speed += amount


func add_buffer(amount: int) -> void:
	buffer_size += amount


# =========================
# UTILIDADES
# =========================
func get_status() -> Dictionary:
	return {
		"hp": hp,
		"firewall": firewall,
		"processing_power": processing_power,
		"processed_packets": processed_packets,
		"buffer_current": buffer.size(),
		"buffer_max": buffer_size,
	}


func can_afford(cost: int) -> bool:
	return processing_power >= cost


# =========================
# REDE — estado completo (público, sem informação oculta)
# O buffer/hp/processing_power de um servidor são visíveis pros dois jogadores,
# então isso pode ir em broadcast normal (sem rpc_id específico).
# =========================
func get_full_state() -> Dictionary:
	var buffer_data: Array = []
	for p in buffer:
		buffer_data.append(p.to_dict())
	return {
		"hp": hp,
		"firewall": firewall,
		"processing_power": processing_power,
		"processed_packets": processed_packets,
		"buffer_size": buffer_size,
		"processing_speed": processing_speed,
		"buffer": buffer_data,
	}


func apply_full_state(d: Dictionary) -> void:
	var next_hp = d.get("hp", hp)
	if next_hp < hp:
		server_damaged.emit(hp - next_hp)
	
	var next_pp = d.get("processing_power", processing_power)
	if next_pp > processing_power:
		throughput_gained.emit(next_pp - processing_power)

	hp = next_hp
	firewall = d.get("firewall", firewall)
	processing_power = next_pp
	processed_packets = d.get("processed_packets", processed_packets)
	buffer_size = d.get("buffer_size", buffer_size)
	processing_speed = d.get("processing_speed", processing_speed)

	var new_buffer: Array[Packet] = []
	for pd in d.get("buffer", []):
		var p := Packet.new()
		p.from_dict(pd)
		new_buffer.append(p)
	buffer = new_buffer
