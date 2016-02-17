/* Punishes players if they are outsize the blue circle for too long
*
* Executed after round start via init.sqf on player
* Player takes damage on every second tick
*/

waitUntil {player == player};

private ["_messageSent", "_tick"];
diag_log "punishPlayer initialized";


//Waituntil server has generated the first circle
waitUntil {GAMESTARTED};
diag_log "punishPlayer starting...";

waitUntil {!isNil "NEWCIRCLEPOS"};

//Set initial circle center
OLDCENTER = NEWCIRCLEPOS;
OLDSIZE = NEWCIRCLESIZE;
BODYPARTS = ["body", "hand_l", "hand_r", "leg_l", "leg_r"];
_messageSent = false;
_tick = 4;



//Pain effect ======================================================================================================================================
mcd_fnc_paineffect = {

	private ["_handle","_name","_priority","_effect"];
	_name = "ChromAberration";
	_priority = 200;
	_effect = [0.03, 0.03, false];

	_sounds = ["WoundedGuyB_01","WoundedGuyB_02","WoundedGuyB_03","WoundedGuyB_04","WoundedGuyB_05","WoundedGuyB_06","WoundedGuyB_07","WoundedGuyB_08"];
	_sound = _sounds call BIS_fnc_selectRandom;
	player say3D _sound;

	while {
		_handle = ppEffectCreate [_name, _priority];
		_handle < 0;
	} do {
		_priority = _priority + 1;
	};

	_handle ppEffectEnable true;
	_handle ppEffectAdjust _effect;
	_handle ppEffectCommit 0.1;
	waitUntil {ppEffectCommitted _handle};

	_handle ppEffectAdjust [0, 0, false];
	_handle ppEffectCommit 1.8;
	waitUntil {ppEffectCommitted _handle};

	_handle ppEffectEnable false;
	ppEffectDestroy _handle;
};



//Update variables with delay, so player has X minutes to get inside the new circle ================================================================
//Do this shit on playerhost
if (isServer) then {
	[_tick] spawn {
		private ["_tick", "_arrayDiff"];
		_tick = _this select 0;

		while {true} do {
			sleep _tick*2;
			_arrayDiff = OLDCENTER - NEWCIRCLEPOS;
			if ((count _arrayDiff) == 0) then {
				sleep TIME_UNTIL_GETIN;
				OLDCENTER = NEWCIRCLEPOS;
				OLDSIZE = NEWCIRCLESIZE;
				diag_log format ["Updated circle variables on client - Pos: %1 Size: %2", OLDCENTER, OLDSIZE];
				["Play is now restricted to the area inside the blue circle!",0,0,3,1] call BIS_fnc_dynamicText;
			};
		};
	};
}
//Do this if you are on dedicated
else
{
	//EH is non-scheduled, so this has to be spawned
	updateVariables = {		
		sleep TIME_UNTIL_GETIN;
		OLDCENTER = NEWCIRCLEPOS;
		OLDSIZE = NEWCIRCLESIZE;
		diag_log format ["Updated circle variables on client - Pos: %1 Size: %2", OLDCENTER, OLDSIZE];
		["Play is now restricted to the area inside the blue circle!",0,0,3,1] call BIS_fnc_dynamicText;
	};

	"NEWCIRCLEPOS" addPublicVariableEventHandler {[] spawn updateVariables};
};



//Main loop ========================================================================================================================================

while {true} do {
	//Outside playzone?
	if ((player distance2D OLDCENTER) > OLDSIZE) then {
		diag_log format ["Player outside the zone. Message sending: %1", (!_messageSent)];

		//First time? Send message.
		if (!_messageSent) then {
			sleep 3;
			_messageSent = true;
			["You are outside the play zone. Get back inside!",0,0,3,1] call BIS_fnc_dynamicText;
		}
		//Not first time -> punish player
		else
		{
			_messageSent = false;
			_bodyPart = BODYPARTS call BIS_fnc_selectRandom;
			[player, 0.3, _bodyPart, "bullet"] call ace_medical_fnc_addDamageToUnit;
			[] spawn mcd_fnc_paineffect;
		};
	}
	else
	{
		//Did player move back inside? Send message.
		if (_messageSent) then {
			_messageSent = false;
			["You are back inside the zone!",0,0,3,1] call BIS_fnc_dynamicText;
		};
	};

	sleep _tick;
};