Dice = {};

-- constructor.
function Dice.new(self)
  -- initialize members.
  local members = {};
  -- throw dice.
  members.Throw = function(self)
    return string.format("ダイス！%sは、%dを出した！", GETMYFAMILYNAME(), IMCRandom(1, 999));
  end
  -- destroy.
  members.Destroy = function(self)
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(Dice, {__call = Dice.new});

-- frame initialize.
function DICE_ON_INIT(addon, frame)
  if (dice.UI_CHAT == nil) then
    dice.UI_CHAT = UI_CHAT;
  end
  UI_CHAT = function(msg)
    if (msg == "/random") then
      msg = dice:Throw();
    end
    dice.UI_CHAT(msg);
  end
end

-- create instance.
if (dice ~= nil) then
  dice:Destroy();
end
dice = Dice();
