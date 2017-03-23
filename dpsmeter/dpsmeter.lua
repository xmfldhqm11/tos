DPSMeter = {};
DPSMeter.Scores = {};
DPSMeter.IsLock = 0;

-- constructor.
function DPSMeter.new(self)
  -- initialize members.
  local members = {};
  members.timeBased = 0;
  members.timeElapsed = 0;
  members.hpBased = 0;
  members.hpElapsed = 0;
  members.maxdps = 0;
  members.name = "";
  -- start count.
  members.Start = function(self, handle)
		local stat = info.GetStat(handle);
    self.timeBased = imcTime.GetAppTimeMS();
    self.hpBased = stat.HP;
    self.name = info.GetName(handle);

    local frameName = "dpsmeter_" .. handle;
    local frame = ui.GetFrame(frameName);
    if (frame == nil) then
      frame = ui.CreateNewFrame("dpsmeter", frameName, 0);
    end
    frame:SetLayerLevel(1);
    frame:Resize(200, 20);
    frame:ShowWindow(1);

    local dpstext = frame:CreateOrGetControl('richtext', "dpstext", 0, 0, 200, 20);
    dpstext:ShowWindow(1);

    local w, h = 0;
    FRAME_AUTO_POS_TO_OBJ(frame, handle, w, h, 1, 1, 1);
    frame:RunUpdateScript("DPSMETER_UPDATE");
  end
  -- update count.
  members.Update = function(self, frame, handle)
		local stat = info.GetStat(handle);
    local dpstext = GET_CHILD(frame, "dpstext", "ui::CRichText");		

    local distFromActor = info.GetTargetInfo(handle).distance;
    if (distFromActor > 130) then
      self.timeBased = imcTime.GetAppTimeMS();
      self.hpBased = stat.HP;
      dpstext:SetColorTone("99FFFFFF");
      return 1;
    end
    self.timeElapsed = self.timeElapsed + (imcTime.GetAppTimeMS() - self.timeBased);
    self.hpElapsed = self.hpElapsed + (self.hpBased - stat.HP);
    local dps = self.hpElapsed / (self.timeElapsed / 1000);

    self.maxdps = math.max(self.maxdps, dps);
    dpstext:SetColorTone("FFFFFFFF");
    dpstext:SetText(string.format("{ol}%.2f(%.2f) dps", dps, self.maxdps));

    local isDead = world.GetActor(handle):IsDead();
    if (isDead == 1) then
      CHAT_SYSTEM(string.format("max %.2f dps on %s", self.maxdps, self.name));
      --ui.DestroyFrame(frame:GetName());
      local score = DPSMeter.Scores[handle];
      DPSMeter.Scores[handle] = nil;
      return 0;
    end
    return 1;
  end
  return setmetatable(members, {__index = self});
end
-- set call.
setmetatable(DPSMeter, {__call = DPSMeter.new});
-- frame initialize.
function DPSMETER_ON_INIT(addon, frame)
  addon:RegisterMsg('MAP_CHARACTER_UPDATE', 'DPSMETER_START');
end
function DPSMETER_START(frame, msg, str, myhandle)
  if (DPSMeter.IsLock == 1) then
    return;
  end
  DPSMeter.IsLock = 1;
  local list, count = SelectBaseObject(GetMyPCObject(), 500, "ALL");
  for i = 1 , count do
    local obj = list[i];
    local iesObj = GetBaseObjectIES(obj);
    local actor = tolua.cast(obj, "CFSMActor");
    local handle = actor:GetHandleVal();
    -- do nothing for my pc.
    if (myhandle ~= handle) then
      local objType = actor:GetObjType();
      local faction = actor:GetFactionStr();
      if (objType == GT_MONSTER and faction == "Monster") then
        local score = DPSMeter.Scores[handle];
        if (score == nil) then
          score = DPSMeter();
          DPSMeter.Scores[handle] = score;
        end
        score:Start(handle);
      end
    end
  end
  DPSMeter.IsLock = 0;
end
function DPSMETER_UPDATE(frame)
  local handle = frame:GetUserIValue("_AT_OFFSET_HANDLE");    -- Setting by FRAME_AUTO_POS_TO_OBJ
  local score = DPSMeter.Scores[handle];
  return score:Update(frame, handle);
end
