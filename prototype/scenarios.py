"""
15 hardcoded root-cause scenarios for the Auto Fix AI Simulator.
Each scenario has: id, difficulty, vehicle, complaint, root_cause, 
correct_diagnosis_key, and key_clues the AI should reveal during testing.
"""

SCENARIOS = [
    # ============== EASY (1-5) ==============
    {
        "id": 1,
        "difficulty": "Easy",
        "vehicle": "2002 Toyota Corolla 1.6, Gasoline, Manual",
        "complaint": "The car won't start at all. When I turn the key, nothing happens — no sound, no lights, nothing.",
        "root_cause": "Dead battery (battery has reached end of life)",
        "correct_repair": "Replace the battery with a new one",
        "protected_normal": ["starter motor", "alternator", "ignition switch", "fuel pump", "spark plugs", "fuses", "wiring harness"],
        "key_clues": {
            "check_dashboard_lights": "No dashboard lights come on when you turn the key to the ON position.",
            "check_headlights": "Headlights are completely dead. No glow at all.",
            "check_battery_terminals": "Battery terminals show white-green corrosion buildup. The positive terminal is particularly crusty.",
            "test_battery_voltage": "Multimeter reads 9.2V across the battery terminals. Way below the normal 12.6V.",
            "try_jump_start": "With jumper cables connected to a donor car, the engine cranks and starts immediately.",
            "check_battery_age": "The battery label shows a manufacturing date from over 5 years ago."
        }
    },
    {
        "id": 2,
        "difficulty": "Easy",
        "vehicle": "2006 Ford Focus 1.6 TDCi, Diesel, Manual",
        "complaint": "When I turn the key, I hear a clicking sound but the engine doesn't turn over.",
        "root_cause": "Faulty starter motor (solenoid engaging but motor not spinning)",
        "correct_repair": "Replace the starter motor",
        "protected_normal": ["battery", "alternator", "ignition switch", "flywheel", "fuel pump", "engine oil", "coolant"],
        "key_clues": {
            "listen_to_starting": "You hear a rapid clicking sound from under the hood when the key is turned to START.",
            "check_battery_voltage": "Battery reads 12.4V — that's within normal range.",
            "check_dashboard_lights": "Dashboard lights come on bright and stay bright during cranking attempt.",
            "tap_starter_motor": "After giving the starter motor a couple of firm taps with a wrench, the engine starts on the next attempt.",
            "check_starter_connections": "Wiring to the starter looks intact, no corrosion on the connections.",
            "check_engine_oil": "Oil level is normal, dipstick shows clean oil at the correct mark."
        }
    },
    {
        "id": 3,
        "difficulty": "Easy",
        "vehicle": "2010 Volkswagen Polo 1.4, Gasoline, Automatic",
        "complaint": "My left headlight isn't working. The right one is fine.",
        "root_cause": "Blown fuse for the left headlight circuit",
        "correct_repair": "Replace the blown fuse (#14, 15A)",
        "protected_normal": ["headlight bulb", "wiring harness", "headlight switch", "relay", "battery", "alternator"],
        "key_clues": {
            "check_headlights": "Right headlight works on both low and high beam. Left headlight is completely dead on both settings.",
            "check_bulb": "You remove the left headlight bulb — the filament is intact, bulb looks fine.",
            "check_fuse_box": "In the engine bay fuse box, fuse #14 (15A, left headlight circuit) is visibly blown — the metal strip inside is broken.",
            "replace_fuse": "After replacing fuse #14 with a new 15A fuse, the left headlight turns on and works normally.",
            "check_wiring": "No visible damage to the wiring harness going to the left headlight assembly.",
            "check_other_electrics": "All other electrical systems work fine — wipers, radio, indicators."
        }
    },
    {
        "id": 4,
        "difficulty": "Easy",
        "vehicle": "2008 Hyundai Accent 1.5 CRDi, Diesel, Manual",
        "complaint": "My windshield wipers don't move at all when I switch them on. The washer fluid squirts fine though.",
        "root_cause": "Wiper motor failure",
        "correct_repair": "Replace the wiper motor",
        "protected_normal": ["wiper fuse", "wiper switch", "wiper linkage", "wiring", "washer pump", "battery"],
        "key_clues": {
            "test_wiper_switch": "Switching between all wiper speeds (intermittent, low, high) produces no movement at all.",
            "check_washer": "Washer fluid pump works perfectly, sprays onto the windshield.",
            "check_fuse": "The wiper fuse in the fuse box is intact — not blown.",
            "listen_to_motor": "With the hood open and wipers switched on, you hear no sound at all from the wiper motor area.",
            "test_motor_voltage": "Using a multimeter at the wiper motor connector: 12V is present when the switch is on. Power is reaching the motor but it's not spinning.",
            "check_linkage": "The wiper linkage arms move freely by hand — they're not seized."
        }
    },
    {
        "id": 5,
        "difficulty": "Easy",
        "vehicle": "2012 Renault Clio 1.5 dCi, Diesel, Manual",
        "complaint": "The AC blows air but it's not cold at all. It used to work fine last summer.",
        "root_cause": "AC refrigerant leak (system is empty)",
        "correct_repair": "Fix the leaking AC line fitting and recharge the refrigerant",
        "protected_normal": ["AC compressor", "AC condenser", "cabin filter", "blend door", "blower motor", "serpentine belt"],
        "key_clues": {
            "test_ac": "AC blows room-temperature air on all fan speeds. Temperature dial position makes no difference.",
            "check_compressor": "With the AC on and hood open, the AC compressor clutch is NOT engaging — the pulley spins freely but the center hub doesn't lock in.",
            "check_refrigerant_pressure": "Connecting pressure gauges: both high and low side read nearly 0 PSI. The system is empty.",
            "visual_inspection": "You spot oily residue around one of the AC line fittings near the firewall — signs of a slow leak.",
            "check_cabin_filter": "Cabin filter is a bit dusty but airflow is fine.",
            "check_belt": "The serpentine belt that drives the AC compressor is in good condition, proper tension."
        }
    },
    # ============== MEDIUM (6-10) ==============
    {
        "id": 6,
        "difficulty": "Medium",
        "vehicle": "2005 Opel Astra 1.6, Gasoline, Manual",
        "complaint": "The engine temperature gauge goes into the red after about 15 minutes of driving. I can see steam sometimes.",
        "root_cause": "Thermostat stuck in closed position",
        "correct_repair": "Replace the thermostat",
        "protected_normal": ["radiator", "water pump", "head gasket", "radiator fan", "coolant hoses", "radiator cap"],
        "key_clues": {
            "check_temp_gauge": "After idling for 10 minutes, the temperature gauge climbs past the 3/4 mark and keeps rising.",
            "check_coolant_level": "Coolant reservoir is at the correct level. No visible leaks under the car.",
            "feel_radiator_hoses": "The upper radiator hose is scorching hot. The lower hose is cold — coolant isn't circulating through the radiator.",
            "check_radiator_fan": "The radiator fan kicks on when temp gets high — it's working.",
            "check_for_leaks": "No coolant puddles under the car. No visible leaks at hose connections.",
            "remove_thermostat": "Removing the thermostat housing reveals the thermostat is stuck in the fully closed position. It doesn't open even when submerged in boiling water."
        }
    },
    {
        "id": 7,
        "difficulty": "Medium",
        "vehicle": "1998 Fiat Palio 1.6, LPG, Manual",
        "complaint": "The car struggles to start in the mornings and shakes badly at idle once it does start.",
        "root_cause": "Fouled spark plug on cylinder 3 (ignition system fault)",
        "correct_repair": "Replace the spark plug on cylinder 3",
        "protected_normal": ["ignition coil", "fuel injector", "head gasket", "idle control valve", "LPG regulator", "timing belt", "compression"],
        "key_clues": {
            "listen_engine_running": "The engine has a rough, uneven idle. There's a noticeable rhythmic vibration — like one cylinder isn't firing properly.",
            "smell_exhaust": "You catch a faint smell of unburnt fuel from the exhaust.",
            "remove_spark_plugs": "Pulling the spark plugs: Cylinders 1, 2, 4 look normal (light tan deposits). Cylinder 3's plug is wet and the tip is black with carbon buildup.",
            "check_plug_wires": "Spark plug wires show no cracks or damage. Resistance readings are within spec.",
            "check_compression": "Compression test: All 4 cylinders read between 150-160 PSI — that's even and healthy.",
            "swap_coil_pack": "Swapping the ignition coil from cylinder 3 to cylinder 1 does NOT move the misfire — problem stays on cylinder 3."
        }
    },
    {
        "id": 8,
        "difficulty": "Medium",
        "vehicle": "2011 Honda Civic 1.8 i-VTEC, Gasoline, Automatic",
        "complaint": "The gear shifts feel very harsh and jerky, especially from 1st to 2nd. It used to shift smooth as butter.",
        "root_cause": "Worn clutch plates in automatic transmission (low/degraded ATF fluid)",
        "correct_repair": "Drain and replace the automatic transmission fluid (ATF)",
        "protected_normal": ["torque converter", "shift solenoid", "TCM", "engine mounts", "clutch plate", "drive shaft"],
        "key_clues": {
            "test_drive": "During a test drive, the 1-2 shift is noticeably harsh with a clear 'thunk'. 2-3 and 3-4 are slightly rough too.",
            "check_atf_level": "Transmission dipstick shows the fluid level is within range, but...",
            "check_atf_condition": "The ATF fluid on the dipstick is dark brown instead of the normal pink/red color. It has a slight burnt smell.",
            "check_engine_mounts": "Engine mounts are firm, no excessive engine movement during shifts.",
            "scan_for_codes": "OBD-II scanner shows no transmission fault codes stored.",
            "check_service_history": "The car has 145,000 km on the odometer. Owner confirms the transmission fluid has never been changed."
        }
    },
    {
        "id": 9,
        "difficulty": "Medium",
        "vehicle": "2014 Kia Ceed 1.6 GDI, Gasoline, Manual",
        "complaint": "There's a squealing noise from the front wheels when I press the brakes, especially at low speeds.",
        "root_cause": "Front brake pads worn down to the wear indicator",
        "correct_repair": "Replace the front brake pads",
        "protected_normal": ["brake caliper", "wheel bearing", "CV joint", "power steering", "rear brakes", "brake fluid"],
        "key_clues": {
            "test_drive_braking": "At low speed, pressing the brake pedal produces a high-pitched metallic squealing from the front. It stops when you release the brake.",
            "check_brake_pedal": "Brake pedal feel is normal — no sponginess or excessive travel.",
            "visual_wheel_inspection": "Looking through the wheel spokes, the brake disc surface looks scored with visible grooves.",
            "remove_front_wheel": "With the front wheel removed: The inner brake pad is worn down to about 1mm. The metal wear indicator tab is touching the disc — that's what's making the noise.",
            "measure_disc_thickness": "Brake disc thickness is 22mm (minimum spec is 20mm). Discs are still usable but should be monitored.",
            "check_rear_brakes": "Rear brake pads are at about 5mm — still have life left."
        }
    },
    {
        "id": 10,
        "difficulty": "Medium",
        "vehicle": "2009 Peugeot 308 1.6 HDi, Diesel, Manual",
        "complaint": "The check engine light came on yesterday. The car feels a bit sluggish and uses more fuel than usual.",
        "root_cause": "Faulty oxygen (lambda) sensor — downstream O2 sensor",
        "correct_repair": "Replace the downstream O2 sensor (Bank 1 Sensor 2)",
        "protected_normal": ["catalytic converter", "MAF sensor", "fuel injector", "EGR valve", "DPF filter", "turbo"],
        "key_clues": {
            "scan_obd_codes": "OBD-II scanner pulls code P0136: 'O2 Sensor Circuit — Bank 1 Sensor 2'. No other codes stored.",
            "check_exhaust": "Exhaust smells slightly richer than normal. No visible smoke though.",
            "live_data_o2": "Live data shows Bank 1 Sensor 1 (upstream) switching normally between 0.1V and 0.9V. Bank 1 Sensor 2 (downstream) is stuck at 0.45V — it's not responding.",
            "visual_o2_sensor": "The downstream O2 sensor's wiring looks intact. No visible damage.",
            "check_catalytic_converter": "Tapping the catalytic converter produces a solid sound — no rattling inside. Converter seems fine.",
            "check_fuel_system": "Fuel pressure is within spec. Injectors are spraying properly."
        }
    },
    # ============== HARD (11-15) ==============
    {
        "id": 11,
        "difficulty": "Hard",
        "vehicle": "2003 BMW 320i E46, Gasoline, Automatic",
        "complaint": "The engine is burning oil. I have to top it up every 1000 km. There's blue smoke from the exhaust under acceleration.",
        "root_cause": "Worn piston rings (oil consumption from ring blow-by)",
        "correct_repair": "Replace the piston rings on cylinders 2 and 3",
        "protected_normal": ["valve seals", "head gasket", "turbo", "PCV valve", "oil pan gasket", "timing chain"],
        "key_clues": {
            "observe_exhaust": "Under hard acceleration, a puff of blue-gray smoke comes from the exhaust. At idle, the exhaust is relatively clean.",
            "check_oil_level": "Oil dipstick confirms oil is about 1 liter low since the last top-up 1200 km ago.",
            "check_for_external_leaks": "No oil drips or puddles under the car. No oil weeping from gaskets or seals visually.",
            "compression_test": "Compression readings: Cyl 1: 145, Cyl 2: 130, Cyl 3: 128, Cyl 4: 148 PSI. Cylinders 2 and 3 are below spec (should be 155+).",
            "wet_compression_test": "Adding a squirt of oil to cylinders 2 and 3 and retesting: readings jump to 155 and 152 PSI. The oil temporarily sealed the worn rings — confirms ring wear.",
            "check_spark_plugs": "Spark plugs on cylinders 2 and 3 show oily residue on the electrode. Others are normal.",
            "check_pcv": "PCV valve clicks and moves freely — it's functioning correctly."
        }
    },
    {
        "id": 12,
        "difficulty": "Hard",
        "vehicle": "2007 Volkswagen Passat 1.9 TDI, Diesel, Manual",
        "complaint": "Hard to start in cold mornings. Once running, white smoke comes from exhaust for a few minutes and coolant level drops slowly over weeks.",
        "root_cause": "Blown head gasket (coolant leaking into combustion chamber)",
        "correct_repair": "Replace the head gasket",
        "protected_normal": ["glow plugs", "fuel injector", "thermostat", "water pump", "radiator", "turbo"],
        "key_clues": {
            "cold_start_observation": "Engine cranks longer than normal before firing. White, sweet-smelling smoke from exhaust for 3-4 minutes after cold start.",
            "check_coolant_level": "Coolant reservoir is about 300ml below the MIN line. Owner says they've been topping up every 2 weeks.",
            "check_for_coolant_leaks": "No visible external coolant leaks — hoses, radiator, water pump all dry.",
            "check_oil_cap": "Removing the oil filler cap reveals a milky, mayo-like residue on the underside — water/coolant mixing with oil.",
            "pressure_test_cooling": "Cooling system pressure test: System won't hold pressure. It slowly drops from 15 PSI to 8 PSI over 5 minutes with no external leaks visible.",
            "exhaust_gas_test": "Chemical block test (combustion gas detector) on the coolant reservoir: The test fluid turns from blue to yellow — confirms combustion gases are present in the cooling system.",
            "check_glow_plugs": "All 4 glow plugs heat up and resistance readings are within spec."
        }
    },
    {
        "id": 13,
        "difficulty": "Hard",
        "vehicle": "2013 Renault Megane 1.5 dCi, Diesel, Manual",
        "complaint": "There's a whining noise from the engine area and I noticed a small puddle of greenish fluid under the car this morning.",
        "root_cause": "Failing water pump (bearing failure + seal leak)",
        "correct_repair": "Replace the water pump",
        "protected_normal": ["power steering pump", "alternator", "timing belt", "radiator", "thermostat", "coolant hoses"],
        "key_clues": {
            "identify_fluid": "The puddle under the engine is greenish and slippery — it's coolant, not oil or power steering fluid.",
            "locate_leak": "Tracing the drip upward: the coolant is coming from behind the timing belt cover area, near the water pump.",
            "listen_engine": "With a mechanic's stethoscope on the water pump housing, there's a clear grinding/whining sound. Other accessories (alternator, PS pump) sound normal.",
            "check_water_pump_shaft": "Grabbing the water pump pulley and wiggling it: there's noticeable play — the bearing is worn. A healthy pump should have zero play.",
            "check_timing_belt": "Removing the timing cover: the timing belt shows some coolant contamination from the leaking pump. Belt is wet on one side.",
            "check_coolant_level": "Coolant level is about 400ml below MIN. System needs a top-up.",
            "check_power_steering": "Power steering reservoir is full. No noise from the PS pump."
        }
    },
    {
        "id": 14,
        "difficulty": "Hard",
        "vehicle": "2004 Fiat Doblo 1.9 JTD, Diesel, Manual",
        "complaint": "The engine has lost a lot of power. It can barely get up hills. Sometimes it stalls when I give it gas from idle.",
        "root_cause": "Timing belt has jumped 2 teeth (timing misalignment)",
        "correct_repair": "Replace the timing belt and tensioner, then realign the timing marks",
        "protected_normal": ["turbo", "fuel pump", "EGR valve", "DPF", "fuel injector", "intercooler"],
        "key_clues": {
            "test_drive": "The engine feels very sluggish. It hesitates badly under acceleration and occasionally stumbles/stalls when blipping the throttle from idle.",
            "listen_engine": "Engine sounds 'off' — the idle is rougher than normal with an uneven rhythm.",
            "scan_codes": "OBD-II scanner pulls P0016: 'Crankshaft/Camshaft Position Correlation — Bank 1'. This indicates timing misalignment.",
            "visual_timing_check": "Removing the timing cover and aligning the crankshaft to TDC: The camshaft timing mark is off by 2 teeth from its correct position.",
            "check_timing_belt_condition": "The timing belt shows signs of wear — some fraying on the edges. The tensioner pulley feels rough when spun by hand.",
            "check_turbo": "Turbo spools up and there's no excessive shaft play or oil leaks. Turbo is functioning.",
            "check_fuel_pressure": "Fuel rail pressure is within normal diesel spec."
        }
    },
    {
        "id": 15,
        "difficulty": "Hard",
        "vehicle": "2010 Hyundai Accent Era 1.5 CRDi, LPG Converted, Manual",
        "complaint": "Car runs fine on gasoline but on LPG it hesitates, misfires, and has noticeably less power. LPG was working fine until last month.",
        "root_cause": "LPG ECU mapping/calibration is off (needs recalibration)",
        "correct_repair": "Recalibrate the LPG ECU fuel map",
        "protected_normal": ["LPG injectors", "LPG filter", "LPG reducer", "spark plugs", "intake manifold", "gasoline ECU"],
        "key_clues": {
            "test_on_gasoline": "Switching to gasoline: Engine runs smoothly, good power, no misfires. Perfectly fine on petrol.",
            "test_on_lpg": "Switching to LPG: After 10 seconds, engine starts hesitating, rpm fluctuates, and there are intermittent misfires.",
            "check_lpg_filter": "LPG filter is relatively clean — doesn't look clogged. Last replaced 8 months ago.",
            "check_lpg_reducer": "LPG reducer/vaporizer is warm to the touch (coolant is flowing through it). No ice buildup — it's vaporizing properly.",
            "check_lpg_injectors": "Removing and testing LPG injectors: All 4 click and spray when activated. Flow rates look similar.",
            "read_lpg_ecu": "Connecting the LPG diagnostic software: The fuel map shows injection durations that don't match the gasoline ECU's requirements. The calibration is significantly off — likely corrupted or reset after a battery disconnect.",
            "check_spark_plugs": "Spark plugs are standard copper type. For LPG, iridium plugs are recommended but the current ones aren't fouled."
        }
    },
]


def get_scenario_by_id(scenario_id: int) -> dict | None:
    """Get a specific scenario by its ID."""
    for s in SCENARIOS:
        if s["id"] == scenario_id:
            return s
    return None


def get_scenarios_by_difficulty(difficulty: str) -> list[dict]:
    """Get all scenarios matching a difficulty level."""
    return [s for s in SCENARIOS if s["difficulty"].lower() == difficulty.lower()]


def get_all_difficulties() -> list[str]:
    """Return available difficulty levels."""
    return ["Easy", "Medium", "Hard"]
