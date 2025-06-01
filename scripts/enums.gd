class_name enums
enum e_resource_type {
	none,
	wood,
	gold,
	meat,
	supply,
	supply_cap
}


enum e_object_type {
	none,
	building,
	resource
}


enum e_building_type {
	none,
	townhall,
	house,
	barracks,
	tower
}


enum e_order_type {
	none,
	build,
	deposit,
	gather,
	move,
	attack
}


enum e_purchase_type {
	none,
	worker,
	swordsman
}

enum e_team {
	none,
	player,
	neutral,
	enemy
}

enum e_cannot_build_reason {
	none,
	insufficient_gold,
	insufficient_wood,
	insufficient_meat,
	insufficient_supply,
	blocked_location
}
