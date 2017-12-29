ark_admin_tools_fnc_initVariables = {
    ark_aiDebugEnabled = false;
    ark_mapTeleportEnabled = false;
    [] call ark_admin_tools_eh_mapClickTeleport;
};

ark_admin_tools_fnc_isHost = {
    private _adminWhiteList = ["76561197969272205", "76561198001868030", "76561197980517821", "76561197972043388"];
    !isMultiplayer || {serverCommandAvailable "#logout"} || (getplayerUID player) in _adminWhiteList;
};

ark_admin_tools_fnc_isAdmiralEnabled = {
    getNumber (missionConfigFile >> "Admiral" >> "isEnabled") == 1;
};

ark_admin_tools_fnc_isTownSweep = {
    getNumber(missionConfigFile >> 'TownSweep' >> 'isEnabled') == 1
};

ark_admin_tools_fnc_assignMapTeleport = {
    params ["_teleportEnabled"];

    if (_teleportEnabled) then {
        ark_mapTeleportEnabled = true;
    } else {
        ark_mapTeleportEnabled = false;
    };
    publicVariable "ark_mapTeleportEnabled";
};

ark_admin_tools_fnc_enableMapTeleport = {
    params ["_player"];
    hintSilent "Map Click Teleport has been enabled.";
    openMap [true, true];
    _player onMapSingleClick {
        _this setposATL _pos;
        [] call ark_admin_tools_fnc_disableMapTeleport;
        openMap [false, false];
    };
};

ark_admin_tools_fnc_disableMapTeleport = {
    hintSilent "Map Click Teleport has been disabled";
    onMapSingleClick {};
};

ark_admin_tools_eh_mapClickTeleport = {
    "ark_mapTeleportEnabled" addPublicVariableEventHandler {
        if (_this select 1) then {
            [player] call ark_admin_tools_fnc_enableMapTeleport;
        } else {
            [] call ark_admin_tools_fnc_disableMapTeleport;
        };
    };
};

ark_admin_tools_fnc_AiDebug = {
    private ["_deleteMarkers"];
    _deleteMarkers = if (count _this > 0) then {_this select 0} else {false};

    call {
        if (!_deleteMarkers && {isNil {ark_admin_canUpdateMarkers} || {!ark_admin_canUpdateMarkers}}) then {
            ark_admin_canUpdateMarkers = true;
            ark_admin_sideCountMarkers = [];
            private ["_sides", "_sideColors"];
            _sides = [EAST, WEST, RESISTANCE, CIVILIAN];
            _sideColors = ["ColorRed", "ColorBlue", "ColorGreen", "ColorPink"];
            for "_i" from 0 to (count _sides) - 1 do {
                private ["_markerName", "_side"];
                _side = _sides select _i;
                _markerName = format ["ark_admin_sideCountMarker_%1", _side];
                createMarkerLocal [_markerName, [-500, 1500 + _i * 200]];
                _markerName setMarkerShapeLocal "ICON";
                _markerName setMarkerTypeLocal "mil_dot";
                _markerName setMarkerColorLocal (_sideColors select _i);
                _markerName setMarkerTextLocal format ["%1: %2", _side, {side _x == _side} count allUnits];
                _markerName setMarkerSizeLocal [1,1];
                ark_admin_sideCountMarkers set [count ark_admin_sideCountMarkers, _side];
            };
            [] spawn {
                while {ark_admin_canUpdateMarkers} do {
                    {
                        private "_marker";
                        _marker = _x getVariable "ark_admin_unitMarker";
                        if (!isNil {_marker}) then {
                            deleteMarkerLocal _marker;
                        }
                    } foreach allDead;
                    sleep 30;
                };
            };
            while {ark_admin_canUpdateMarkers} do {
                {
                    private ["_unit", "_marker"];
                    _unit = _x;
                    _marker = _unit getVariable "ark_admin_unitMarker";
                    if (!isNil {_marker}) then {
                        _marker setMarkerPosLocal getPosATL _unit;
                        _marker setMarkerDirLocal getDir _unit;
                    } else {
                        private ["_markerName", "_sideIndex", "_sideColor"];
                        _markerName = format ["ark_admin_unitMarker_%1", _unit];
                        _unit setVariable ["ark_admin_unitMarker", _markerName, false];
                        _sideIndex = _sides find side _unit;
                        if (_sideIndex >= 0) then {
                            _sideColor = ["ColorRed", "ColorBlue", "ColorGreen", "ColorPink"] select _sideIndex;
                        } else {
                            _sideColor = "ColorWhite";
                        };
                        createMarkerLocal [_markerName, getPosATL _unit];
                        _markerName setMarkerShapeLocal "ICON";
                        _markerName setMarkerTypeLocal "mil_triangle";
                        _markerName setMarkerColorLocal _sideColor;
                        _markerName setMarkerTextLocal "";
                        _markerName setMarkerSizeLocal [0.5,0.75];
                        _markerName setMarkerDirLocal getDir _unit;
                        if (!isNil {(group _unit) getVariable "ark_adm_spawnedBy"}) then {
                            _markerName setMarkerTextLocal "*";
                        };
                    };
                } foreach allUnits;
                {
                    private "_markerName";
                    _side = _x;
                    (format ["ark_admin_sideCountMarker_%1", _side]) setMarkerTextLocal format ["%1: %2", _side, {side _x == _side} count allUnits];
                } foreach ark_admin_sideCountMarkers;
                sleep 4;
            };
        };
        if (_deleteMarkers && {!isNil {ark_admin_canUpdateMarkers}} && {ark_admin_canUpdateMarkers}) then {
            ark_admin_canUpdateMarkers = false;
            {
                private "_marker";
                _marker = _x getVariable "ark_admin_unitMarker";
                if (!isNil {_marker}) then {
                    _x setVariable ["ark_admin_unitMarker", nil, false];
                    deleteMarkerLocal _marker;
                }
            } foreach allUnits;
            {
                private "_marker";
                _marker = _x getVariable "ark_admin_unitMarker";
                if (!isNil {_marker}) then {
                    _x setVariable ["ark_admin_unitMarker", nil, false];
                    deleteMarkerLocal _marker;
                }
            } foreach allDead;
            {
                deleteMarkerLocal (format ["ark_admin_sideCountMarker_%1", _x]);
            } foreach ark_admin_sideCountMarkers;
            ark_admin_sideCountMarkers = nil;
        };
    };
};

ark_admin_tools_fnc_enableAiDebug = {
    ark_aiDebugEnabled = true;
    [] spawn ark_admin_tools_fnc_AiDebug;
};

ark_admin_tools_fnc_disableAiDebug = {
    ark_aiDebugEnabled = false;
    [true] spawn ark_admin_tools_fnc_AiDebug;
};

// Only call below from server, clients will fail
ark_admin_tools_fnc_callAttackHelo = {
    params ["_player"];
    private _unitTemplate = adm_camp_defaultUnitTemplate;
    private _side = [_unitTemplate] call adm_common_fnc_getUnitTemplateSide;
    private _pilotArray = getArray (configfile >> "Admiral" >> "UnitTemplates" >> _unitTemplate >> "pilots");
    private _heloArray = getArray (configfile >> "Admiral" >> "UnitTemplates" >> _unitTemplate >> "ah");
    if (isNil "_heloArray" || { count _heloArray == 0 }) exitWith {
        diag_log "[ARK] (Admin Tools) - No helo defined in Admiral template";
    };
    private _unit = selectRandom _pilotArray;
    private _helo = selectRandom _heloArray;

    private _vehicle = createVehicle [_helo, position _player, [], 2000, "FLY"]; 
    private _grp = createGroup _side; 
    private _allTurrets = allTurrets [_vehicle, true];

    private _driver = _grp createUnit [_unit, [0,0,0], [], 0, "NONE"];
    _driver assignAsDriver _vehicle;
    _driver moveInDriver _vehicle;

    {
        private _units = _grp createUnit [_unit, [0,0,0], [], 0, "NONE"];
        _units assignAsTurret [_vehicle, _x];
        _units moveInTurret [_vehicle, _x];
    } forEach _allTurrets;

    private _waypoint = _grp addWaypoint [position _player, 0, 1]; 
    _waypoint setWaypointType "SAD"; 
    _waypoint setWaypointBehaviour "COMBAT"; 
    _waypoint setWaypointCombatMode "RED"; 
    _waypoint setWaypointSpeed "FULL";
    [_grp, 2] waypointAttachVehicle _player;
    _grp reveal [_player, 3.5];
};

ark_admin_tools_fnc_callArmour = {
    params ["_player"];
    private _unitTemplate = adm_camp_defaultUnitTemplate;
    private _side = [_unitTemplate] call adm_common_fnc_getUnitTemplateSide;
    private _pos = [_player, 1000, 1100, 3, 0, 20, 0] call BIS_fnc_findSafePos;
    private _crewmanArray = getArray (configfile >> "Admiral" >> "UnitTemplates" >> _unitTemplate >> "crewmen");
    private _armourArray = getArray (configfile >> "Admiral" >> "UnitTemplates" >> _unitTemplate >> "armour");
    private _unit = selectRandom _crewmanArray;
    private _vic = selectRandom _armourArray;

    private _vehicle = createVehicle [_vic, _pos, [], 0, "NONE"];
    private _grp = createGroup _side;
    private _allTurrets = allTurrets [_vehicle, true];

    private _driver = _grp createUnit [_unit, [0,0,0], [], 0, "NONE"];
    _driver assignAsDriver _vehicle;
    _driver moveInDriver _vehicle;

    {
        private _units = _grp createUnit [_unit, [0,0,0], [], 0, "NONE"];
        _units assignAsTurret [_vehicle, _x];
        _units moveInTurret [_vehicle, _x];
    } forEach _allTurrets;

    _vehicle allowCrewInImmobile true;
    _vehicle setUnloadInCombat [false, false];

    private _waypoint = _grp addWaypoint [position _player, 0, 1]; 
    _waypoint setWaypointType "SAD"; 
    _waypoint setWaypointBehaviour "COMBAT"; 
    _waypoint setWaypointCombatMode "RED"; 
    _waypoint setWaypointSpeed "FULL";
    [_grp, 2] waypointAttachVehicle _player;
};

ark_admin_tools_fnc_ammoDrop = {
    params ["_player"];
    _player setVariable ["ark_ts_paradropInProgress", true, true];
    private _hull3Faction = _player getVariable "hull3_faction";
    private _dropHeight = 150;
    [[_player, _hull3Faction, _dropHeight], {
        params ["_player", "_hull3Faction", "_dropHeight"];

        private _position = getPosATL _player;
        _position set [2, _dropHeight];

        private _parachute = createVehicle ["B_Parachute_02_F", _position, [], 0, "FLY"];

        private _ammoBox = createVehicle ["B_CargoNet_01_ammo_F", position _parachute, [], 0, "NONE"];
        _ammoBox allowDamage false;
        [_ammoBox, ["faction", _hull3Faction], ["gear", "Truck"]] call hull3_unit_fnc_init;
        _ammoBox attachTo [_parachute, [0, 0, -1.3]];

        private _smoke = createVehicle ["SmokeShellOrange", position _parachute, [], 0, "NONE"];
        _smoke attachTo [_parachute, [0, 0, 0]];

        waitUntil { getPosATL _ammoBox select 2 < 1 || isNull _parachute };
        detach _ammoBox;
        _player setVariable ["ark_ts_paradropInProgress", false, true];
    }] remoteExec ["bis_fnc_spawn", 2];
}; 

[] call ark_admin_tools_fnc_initVariables;