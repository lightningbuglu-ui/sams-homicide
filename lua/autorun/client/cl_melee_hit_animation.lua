-- Disable the melee hit-stop/reverse animation by default so swings finish
-- normally after hitting props or the world.
if CLIENT then
    local cvar = GetConVar("hg_nomeleestop")

    if not cvar then
        CreateClientConVar("hg_nomeleestop", "1", true, false, "Disable melee stop-on-hit animation")
    else
        RunConsoleCommand("hg_nomeleestop", "1")
    end
end
