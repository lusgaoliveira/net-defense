extends Resource
class_name Packet

enum PacketType {
	DATA,
	VIDEO,
	VOICE,
	MALWARE,
	DDOS
}

var type: PacketType
var is_malicious: bool = false
# throughput gerado ao concluir
var throughput_value: int = 0
# dano causado ao concluir
var damage: int = 0
# tempo necessário para processar
var process_time: float = 1.0
# contador regressivo
var remaining_time: float = 1.0


func setup(
	p_type: PacketType,
	p_throughput: int,
	p_damage: int,
	p_time: float,
	p_malicious: bool
) -> void:
	type = p_type
	throughput_value = p_throughput
	damage = p_damage
	process_time = p_time
	remaining_time = p_time
	is_malicious = p_malicious


# Serialização para envio via RPC (Resource não trafega direto por RPC)
func to_dict() -> Dictionary:
	return {
		"type": type,
		"is_malicious": is_malicious,
		"throughput_value": throughput_value,
		"damage": damage,
		"process_time": process_time,
		"remaining_time": remaining_time,
	}


func from_dict(d: Dictionary) -> void:
	type = d.get("type", PacketType.DATA)
	is_malicious = d.get("is_malicious", false)
	throughput_value = d.get("throughput_value", 0)
	damage = d.get("damage", 0)
	process_time = d.get("process_time", 1.0)
	remaining_time = d.get("remaining_time", 1.0)
