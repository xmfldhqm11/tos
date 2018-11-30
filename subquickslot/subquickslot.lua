-- 領域定義
local author = 'weizlogy'
local addonName = 'subquickslot'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS'][author] = _G['ADDONS'][author] or {}
_G['ADDONS'][author][addonName] = _G['ADDONS'][author][addonName] or {}

-- 領域へのポインターを取得
local g = _G['ADDONS'][author][addonName]

-- 個別フレームのコンストラクター
function g.new(self)
  local members = {};

  -- === 定数 === --
  local __ADDON_DIR = '../addons/'..addonName
  local __OPTION_FRAME_NAME = addonName..'_option'
  local __USERVALUE_FRAME_INDEX = 'frameindex'
  local __USERVALUE_SLOT_CATEGORY = 'category'
  local __CONFIG_FRAME_INDEXIES = 'frameindexies'
  local __CONFIG_SLOT_CATEGORY = 'category'
  local __CONFIG_SLOT_TYPE = 'type'
  local __CONFIG_SLOT_IESID = 'iesid'
  local __CONFIG_SLOTSET_SIZE = 'size'
  local __CONFIG_SLOTSET_POS = 'pos'

  -- === 内部データ === --
  local __cid = info.GetCID(session.GetMyHandle())
  local __config = {}

  -- === 内部関数 === --
  local GetConfigByFrameKey = function(index)
    return 'frame'..index
  end

  -- === 公開関数 === --
  -- 全フレームを読み込む
  members.CreateFrames = function(self)
    self:Dbg('CreateFrames called.')

    __config = self:Deserialize(__cid)

    for index in string.gmatch(__config[__CONFIG_FRAME_INDEXIES] or '1', "%S+") do
      self:CreateFrame(index)
    end
  end

  -- シリアライズ
  members.Serialize = function(self, fileName, dataObj)
    self:Dbg('Serialize called. '..fileName)

    local f, e = io.open(string.format('%s/%s', __ADDON_DIR, fileName), 'w')
    if (e) then
      self:Err('Failed to save option to file.'..fileName)
      self:Err(tostring(e))
      return
    end

    -- localを再帰で使うための
    local recursive; recursive = function(key, value, depth)
      local indent = string.rep(' ', depth)
      if (type(value) == 'table') then
        f:write(string.format('%s[\'%s\'] = %s\n', indent, key, '{'))
        for k, v in pairs(value) do
          recursive(k, v, depth + 2)
        end
        f:write(indent..'},\n')
      elseif (value ~= nil) then
        f:write(string.format('%s[\'%s\'] = \'%s\',\n', indent, key, value))
      end
    end

    f:write('local s = {\n')
    for k, v in pairs(dataObj) do
      recursive(k, v, 2)
    end
    f:write('}\n')
    f:write('return s')
    f:flush()
    f:close()
    self:Dbg('Save option to file.'..fileName)
  end

  -- デシリアライズ
  members.Deserialize = function(self, fileName)
    self:Dbg('Deserialize called. '..fileName)

    local filePath = string.format('%s/%s', __ADDON_DIR, fileName)
    local f, e = io.open(filePath, 'r')
    if (e or f == nil) then
      self:Dbg('Nothing to load option from file.')
      return {}
    end
    f:close()
    return dofile(filePath)
  end

  -- ログ出力
  members.Dbg = function(self, msg)
    -- CHAT_SYSTEM(string.format('[%s] <Dbg> %s', addonName, msg))
  end
  members.Log = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Log> %s', addonName, msg))
  end
  members.Err = function(self, msg)
    CHAT_SYSTEM(string.format('[%s] <Err> %s', addonName, msg))
  end

  -- フレーム作成
  members.CreateFrame = function(self, frameIndex)
    self:Dbg('CreateFrame called. '..frameIndex)

    local configKey = GetConfigByFrameKey(frameIndex)
    __config[configKey] = __config[configKey] or {}

    -- スロットサイズ解析
    local slotw, sloth = string.match(__config[configKey][__CONFIG_SLOTSET_SIZE] or '1x1', '(%d+)x(%d+)')
    self:Dbg('creating slot => '..slotw..' x '..sloth)
    local slotsize = 48

    local frame = ui.CreateNewFrame(addonName, addonName..'-'..frameIndex)
    frame:SetUserValue(__USERVALUE_FRAME_INDEX, frameIndex)
    frame:SetSkinName('downbox')
    frame:SetEventScript(ui.RBUTTONUP, 'SUBQUICKSLOT_ON_SHOWMENU')
    frame:SetEventScript(ui.LBUTTONUP, 'SUBQUICKSLOT_ON_ENDMOVE')
    frame:SetAlpha(50)
    local frameX, frameY = string.match(__config[configKey][__CONFIG_SLOTSET_POS] or '200x200', '(%d+)x(%d+)')
    frame:SetOffset(frameX, frameY)
    frame:Resize(slotw * slotsize + 20, sloth * slotsize + 20)
    -- スロット作成
    DESTROY_CHILD_BYNAME(frame, 'slotset')
    local slotset = frame:CreateOrGetControl('slotset', 'slotset', 10, 10, 0, 0)
    tolua.cast(slotset, 'ui::CSlotSet')
    slotset:SetSlotSize(slotsize, slotsize)  -- スロットの大きさ
    slotset:EnablePop(1)
  	slotset:EnableDrag(1)
  	slotset:EnableDrop(1)
  	slotset:SetColRow(slotw, sloth)  -- スロットの配置と個数
  	slotset:SetSpc(0, 0)
  	slotset:SetSkinName('slot')
    slotset:SetEventScript(ui.DROP, 'SUBQUICKSLOT_ON_DROPSLOT')
    slotset:SetEventScript(ui.POP, 'SUBQUICKSLOT_ON_POPSLOT')
  	slotset:EnableSelection(0)
  	slotset:CreateSlots()
    self:Dbg('createed slot.')
    -- スロット復元
    for k, v in pairs(__config[configKey]) do
      local index = string.match(k, 'slot(%d)')
      if (index) then
        local dummyLiftIconInfo = {}
        dummyLiftIconInfo.category = v[__CONFIG_SLOT_CATEGORY]
        dummyLiftIconInfo.type = v[__CONFIG_SLOT_TYPE]
        dummyLiftIconInfo.GetIESID = function(self)
          return v[__CONFIG_SLOT_IESID]
        end
        self:SetSubSlot(slotset:GetSlotByIndex(index), dummyLiftIconInfo)
      end
    end
    self:Dbg('recovered slot.')

    frame:ShowWindow(1)
  end

  -- フレーム削除
  members.DeleteFrame = function(self, frameIndex)
    self:Dbg('DeleteFrame called.')

    ui.DestroyFrame(addonName..'-'..frameIndex)
    __config[GetConfigByFrameKey(frameIndex)] = nil
  end

  -- オプションフレーム作成
  members.CreateOptionFrame = function(self, frameIndex)
    self:Dbg('CreateOptionFrame called. index='..frameIndex)

    local frame = ui.CreateNewFrame(addonName, __OPTION_FRAME_NAME)
    frame:SetUserValue(__USERVALUE_FRAME_INDEX, frameIndex)
    frame:SetEventScript(ui.LOST_FOCUS, "SUBQUICKSLOT_ON_LOSTFOCUSOPTION")
    frame:SetLayerLevel(32)
    frame:SetSkinName('test_frame_low')
    frame:SetOffset(mouse.GetX(), mouse.GetY())
    frame:Resize(250, 200)
    local titlelabel = frame:CreateOrGetControl('richtext', 'titlelabel', 0, 14, 0, 0)
    titlelabel:SetFontName('white_20_ol')
    titlelabel:SetTextAlign('center', 'center')
    titlelabel:SetGravity(ui.CENTER_HORZ, ui.TOP)
    titlelabel:SetText(string.format('SubQuickSlot-%s Options', frameIndex))
    local sizelabel = frame:CreateOrGetControl('richtext', 'sizelabel', 10, 49, 0, 0)
    sizelabel:SetFontName('white_16_ol')
    sizelabel:SetText('VxH')
    sizelabel:SetTextTooltip('Input slot size, what you want. Fromat: <vertial>x<horizon>. Ex: 2x4.')
    local sizeinput = frame:CreateOrGetControl('edit', 'sizeinput', 50, sizelabel:GetY() - 4, 80, 25)
    tolua.cast(sizeinput, 'ui::CEditControl')
		sizeinput:SetFontName('white_16_ol')
    sizeinput:SetSkinName('test_weight_skin')
    sizeinput:SetTextAlign('center', 'center')
    sizeinput:SetText(__config[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_SIZE] or '1x1')

    frame:ShowWindow(1)
  end

  -- 設定保存＋フレーム非表示
  members.CloseOptionFrame = function(self)
    self:Dbg('CloseOptionFrame called.')

    local frame = ui.GetFrame(__OPTION_FRAME_NAME)
    local frameIndex = frame:GetUserValue(__USERVALUE_FRAME_INDEX)
    -- 設定保存
    local size = GET_CHILD(frame, 'sizeinput', 'ui::CEditControl'):GetText()
    -- 再描画判定
    local configKey = GetConfigByFrameKey(frameIndex)
    local redraw = __config[configKey][__CONFIG_SLOTSET_SIZE] ~= size
    __config[configKey][__CONFIG_SLOTSET_SIZE] = size
    self:Dbg('size='..size)
    self:Serialize(__cid, __config)
    -- フレーム非表示
    frame:ShowWindow(0)
    return redraw
  end

  -- 右クリックメニュー作成
  members.CreateOptionMenu = function(self, frame)
    self:Dbg('CreateOptionMenu called. index='..frame:GetName())

    local frameIndex = frame:GetUserValue(__USERVALUE_FRAME_INDEX)
    local menuTitle = 'SubQuickSlot-'..frameIndex
    local context = ui.CreateContextMenu(
      'CONTEXT_COSTUMEPLAY_ON_COSTUME_SELECT', menuTitle, 0, 0, string.len(menuTitle) * 12, 100)
    -- 画面表示
    ui.AddContextMenuItem(context, 'Option', string.format('SUBQUICKSLOT_ON_MENU_SHOWOPTION(%s)', frameIndex))
    ui.AddContextMenuItem(context, 'Redraw', 'SUBQUICKSLOT_ON_MENU_REDRAW')
    if (frameIndex == '1') then
      ui.AddContextMenuItem(context, 'CreateNew', string.format('SUBQUICKSLOT_ON_MENU_CREATENEW(%s)', frameIndex))
    else
      ui.AddContextMenuItem(context, 'Delete', string.format('SUBQUICKSLOT_ON_MENU_DELETE(%s)', frameIndex))
    end
    ui.AddContextMenuItem(context, 'Cancel', 'None')
    ui.OpenContextMenu(context)
  end

  -- サブスロットにアイコンをセット
  members.SetSubSlot = function(self, slot, liftIconInfo)
    self:Dbg('SlotSet called.')

    -- ドロップ情報を取得
    local category = liftIconInfo.category
    local type = liftIconInfo.type
    self:Dbg(string.format('%s - %s - %s', category, type, liftIconInfo:GetIESID()))

    tolua.cast(slot, "ui::CSlot")
    if (category == 'Item') then
      local invItem = session.GetInvItemByGuid(liftIconInfo:GetIESID())
      -- スロット格納してイベント定義
      SET_SLOT_INVITEM(slot, invItem)
      slot:SetUserValue(__USERVALUE_SLOT_CATEGORY, category)
      slot:SetEventScript(ui.RBUTTONUP, 'SUBQUICKSLOT_ON_SLOTRUP')
      slot:SetEventScriptArgNumber(ui.RBUTTONUP, type)
      -- クールダウンの設定
      ICON_SET_ITEM_COOLDOWN_OBJ(slot:GetIcon(), GetIES(invItem:GetObject()))
    end
  end

  -- サブスロットからアイコンを削除
  members.RemoveFromSubSlot = function(self, slot)
    self:Dbg('RemoveFromSubSlot called.')
    slot:ClearIcon()
    slot:ClearText()
  end

  -- スロットからカテゴリー情報を復元
  members.GetCategoryFromSlot = function(self, slot)
    self:Dbg('GetCategoryFromSlot called.')
    return slot:GetUserValue(__USERVALUE_SLOT_CATEGORY)
  end

  -- スロット情報を保存
  members.SaveSlot = function(self, frame, slotIndex, liftIconInfo, removeSlotIndex)
    self:Dbg('SaveSlot called. index='..frame:GetName())

    local configKey = GetConfigByFrameKey(frame:GetUserValue(__USERVALUE_FRAME_INDEX))

    -- 削除
    if (removeSlotIndex) then
      __config[configKey]['slot'..removeSlotIndex] = nil
    end

    -- 追加
    if (slotIndex) then
      local key = 'slot'..slotIndex
      -- __config[configKey] = __config[configKey] or {}
      CHAT_SYSTEM(configKey)
      CHAT_SYSTEM(type(__config[configKey]))
      __config[configKey][key] = __config[configKey][key] or {}
      __config[configKey][key][__CONFIG_SLOT_CATEGORY] = liftIconInfo.category
      __config[configKey][key][__CONFIG_SLOT_TYPE] = liftIconInfo.type
      __config[configKey][key][__CONFIG_SLOT_IESID] = liftIconInfo:GetIESID()
    end

    self:Serialize(__cid, __config)
  end

  -- 位置情報を保存
  members.SavePos = function(self, frame)
    self:Dbg('SavePos called. index='..frame:GetName())

    local frameIndex = frame:GetUserValue(__USERVALUE_FRAME_INDEX)
    __config[GetConfigByFrameKey(frameIndex)][__CONFIG_SLOTSET_POS] =
      string.format('%dx%d', frame:GetX(), frame:GetY())
    self:Serialize(__cid, __config)
  end

  -- フレームインデックスを保存
  members.SaveFrameIndex = function(self, frameIndex, delete)
    self:Dbg('SaveFrameIndex called. index='..frameIndex)

    local config = __config[__CONFIG_FRAME_INDEXIES] or '1'
    if (delete) then
      config = string.gsub(config, '%s'..frameIndex, '', 1)
    else
      config = config..' '..frameIndex
    end
    __config[__CONFIG_FRAME_INDEXIES] = config

    self:Serialize(__cid, __config)
  end

  -- デストラクター
  members.Destroy = function(self)
  end
  -- おまじない
  return setmetatable(members, {__index = self});
end
-- .newなしでコンストラクターを呼ぶエイリアス登録
setmetatable(g, {__call = g.new})

-- 自フレーム初期化処理
function SUBQUICKSLOT_ON_INIT(addon, frame)
  -- インベントリ操作が発生したら再描画が必要
  addon:RegisterMsg('INV_ITEM_ADD', 'SUBQUICKSLOT_ON_REDRAW')
  addon:RegisterMsg('INV_ITEM_POST_REMOVE', 'SUBQUICKSLOT_ON_REDRAW')
  addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'SUBQUICKSLOT_ON_REDRAW')

  g.instance:CreateFrames()
end

-- === イベントハンドラー === --
function SUBQUICKSLOT_ON_SHOWMENU(frame, index, num)
  g.instance:CreateOptionMenu(frame)
end
function SUBQUICKSLOT_ON_MENU_SHOWOPTION(index)
  g.instance:CreateOptionFrame(index)
end
function SUBQUICKSLOT_ON_MENU_REDRAW()
  g.instance:CreateFrames()
end
function SUBQUICKSLOT_ON_MENU_CREATENEW(index)
  local newIndex = IMCRandom(2,999)
  g.instance:CreateFrame(newIndex)
  g.instance:SaveFrameIndex(newIndex)
end
function SUBQUICKSLOT_ON_MENU_DELETE(index)
  g.instance:DeleteFrame(index)
  g.instance:SaveFrameIndex(index, true)
end
function SUBQUICKSLOT_ON_LOSTFOCUSOPTION()
  local redraw = g.instance:CloseOptionFrame()
  if (redraw) then
    g.instance:CreateFrames()
  end
end
function SUBQUICKSLOT_ON_ENDMOVE(frame, str, num)
  g.instance:SavePos(frame)
end
function SUBQUICKSLOT_ON_DROPSLOT(parent, slot, str, num)
  local info = ui.GetLiftIcon():GetInfo()
  g.instance:SetSubSlot(slot, info)
  if (info.fromIndex) then
    g.instance:RemoveFromSubSlot(parent:GetSlotByIndex(info.fromIndex))
  end
  g.instance:SaveSlot(parent:GetTopParentFrame(), slot:GetSlotIndex(), info, info.fromIndex)
end
function SUBQUICKSLOT_ON_POPSLOT(parent, slot, str, num)
  local info = ui.GetLiftIcon():GetInfo()
  -- 画面外にドロップしてもイベント発生しないのでLALTで消すようにする
  if (keyboard.IsKeyPressed('LALT') == 1) then
    g.instance:RemoveFromSubSlot(slot)
    g.instance:SaveSlot(parent:GetTopParentFrame(), nil, info, slot:GetSlotIndex())
    return
  end
  -- スロットからドラッグ開始するとcategoryが抜けるので予め保持したものを持ってくる
  info.category = g.instance:GetCategoryFromSlot(slot)
  -- ドロップ時に消せるようにliftIconInfoにIndexをもたせる
  info.fromIndex = slot:GetSlotIndex()
end
function SUBQUICKSLOT_ON_SLOTRUP(parent, slot, str, num)
  local category = g.instance:GetCategoryFromSlot(slot)
  if (category == 'Item') then
    SLOT_ITEMUSE_BY_TYPE(parent, slot, str, num)
  end
end

-- インスタンス作成
if (g.instance ~= nil) then
  g.instance:Destroy();
end
g.instance = g();