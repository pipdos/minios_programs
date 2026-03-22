-- DOOM.ML v2 - fast raycaster for MiniOS
-- UP/DOWN = move, LEFT/RIGHT = turn, OK = shoot, L+R+OK = exit

-- MAP 8x8 (1=wall 0=floor)
var map = [
  1,1,1,1,1,1,1,1,
  1,0,0,0,0,0,0,1,
  1,0,1,1,0,1,0,1,
  1,0,1,0,0,0,0,1,
  1,0,0,0,1,0,0,1,
  1,0,1,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  1,1,1,1,1,1,1,1
]

-- Player pos integer cells, angle 0..15 (16 dirs)
var px = 2
var py = 2
var pa = 0

-- Direction vectors *8 for 16 angles
var DX = [8,7,5,3,0,-3,-5,-7,-8,-7,-5,-3,0,3,5,7]
var DY = [0,3,5,7,8,7,5,3,0,-3,-5,-7,-8,-7,-5,-3]

var health = 100
var ammo = 15
var score = 0
var flash = 0
var ex = 5
var ey = 5
var ealive = 1

func mwall(mx, my)
  if mx < 0 then return 1 end
  if my < 0 then return 1 end
  if mx >= 8 then return 1 end
  if my >= 8 then return 1 end
  return arr.get(map, my * 8 + mx)
end

-- Cast ray from (rx,ry) angle ra, return dist 1..32
func cast(rx, ry, ra)
  var cdx = arr.get(DX, ra)
  var cdy = arr.get(DY, ra)
  var cx = rx * 8 + 4
  var cy = ry * 8 + 4
  var i = 0
  while i < 20 do
    cx = cx + cdx
    cy = cy + cdy
    if mwall(cx / 8, cy / 8) == 1 then
      var dx = cx - rx * 8 - 4
      var dy = cy - ry * 8 - 4
      if dx < 0 then dx = 0 - dx end
      if dy < 0 then dy = 0 - dy end
      var d = dx + dy
      if d < 1 then d = 1 end
      return d
    end
    i = i + 1
  end
  return 160
end

func slice(sx, d)
  var h = 256 / d
  if h > 60 then h = 60 end
  var t = 32 - h / 2
  var b = 32 + h / 2
  scr.line(sx, t, sx, b)
end

func render()
  scr.clear()

  -- floor dots
  var fy = 34
  while fy < 64 do
    var fx = 0
    while fx < 96 do
      scr.pixel(fx, fy)
      fx = fx + 5
    end
    fy = fy + 4
  end

  -- 8 rays -> 8 bands of 12px each
  var col = 0
  while col < 8 do
    var roff = col - 3
    var ra = pa + roff
    if ra < 0 then ra = ra + 16 end
    if ra >= 16 then ra = ra - 16 end
    var d = cast(px, py, ra)
    var sx = col * 12
    slice(sx, d)
    slice(sx+1, d)
    slice(sx+2, d)
    slice(sx+3, d)
    slice(sx+4, d)
    slice(sx+5, d)
    slice(sx+6, d)
    slice(sx+7, d)
    slice(sx+8, d)
    slice(sx+9, d)
    slice(sx+10, d)
    slice(sx+11, d)
    col = col + 1
  end

  -- HUD panel right 32px
  scr.frect(96, 0, 32, 64)

  -- minimap 8x8 cells -> 4px each = 32x32
  var my = 0
  while my < 8 do
    var mx = 0
    while mx < 8 do
      if mwall(mx, my) == 1 then
        scr.pixel(96 + mx*4,   my*4)
        scr.pixel(97 + mx*4,   my*4)
        scr.pixel(96 + mx*4, 1+my*4)
        scr.pixel(97 + mx*4, 1+my*4)
      end
      mx = mx + 1
    end
    my = my + 1
  end

  -- player dot
  scr.pixel(96 + px*4+1, py*4+1)

  -- enemy dot
  if ealive == 1 then
    scr.pixel(96 + ex*4+1, ey*4+1)
    scr.pixel(96 + ex*4,   ey*4)
  end

  -- HP bar
  scr.text("HP", 97, 34)
  scr.rect(96, 42, 30, 5)
  if health > 0 then
    var hw = health * 28 / 100
    scr.frect(97, 43, hw, 3)
  end

  -- ammo + score
  scr.text(ammo, 100, 50)
  scr.text(score, 96, 57)

  -- crosshair
  scr.pixel(47, 29)
  scr.pixel(45, 32)
  scr.pixel(47, 32)
  scr.pixel(49, 32)
  scr.pixel(47, 35)

  -- gun
  if flash > 0 then
    scr.pixel(44, 46)
    scr.pixel(47, 43)
    scr.pixel(50, 46)
  end
  scr.frect(37, 55, 22, 9)
  scr.frect(43, 50, 10, 7)

  scr.show()
end

func move(forward)
  var dx = arr.get(DX, pa)
  var dy = arr.get(DY, pa)
  if forward == 0 then
    dx = 0 - dx
    dy = 0 - dy
  end
  var nx = px
  var ny = py
  if dx > 0 then nx = px + 1 end
  if dx < 0 then nx = px - 1 end
  if dy > 0 then ny = py + 1 end
  if dy < 0 then ny = py - 1 end
  if mwall(nx, py) == 0 then px = nx end
  if mwall(px, ny) == 0 then py = ny end
end

-- INTRO SCREEN
scr.clear()
scr.text("DOOM.ML", 22, 8, 2)
scr.text("UP/DN : move", 16, 30)
scr.text("L/R   : turn", 16, 40)
scr.text("OK    : shoot", 16, 50)
scr.text("press OK", 28, 58)
scr.show()
btn.wait()

-- GAME LOOP
var running = 1
var tick = 0

while running == 1 do
  -- read combo first (exit)
  var bc = btn.combo()
  if bc == "exit" then
    running = 0
  end

  -- turn
  if btn.held("left") == 1 then
    pa = pa - 1
    if pa < 0 then pa = 15 end
  end
  if btn.held("right") == 1 then
    pa = pa + 1
    if pa >= 16 then pa = 0 end
  end

  -- move every 2 ticks so not too fast
  if tick == 0 then
    if btn.held("up") == 1 then
      move(1)
    end
    if btn.held("down") == 1 then
      move(0)
    end
  end

  -- shoot
  var b = btn.read()
  if b == "ok" then
    if ammo > 0 then
      ammo = ammo - 1
      flash = 4
      if ealive == 1 then
        var ddx = ex - px
        var ddy = ey - py
        if ddx < 0 then ddx = 0 - ddx end
        if ddy < 0 then ddy = 0 - ddy end
        if ddx + ddy <= 2 then
          ealive = 0
          score = score + 100
        end
      end
    end
  end

  -- enemy AI
  if ealive == 1 then
    if tick == 0 then
      var ddx = px - ex
      var ddy = py - ey
      if ddx > 0 then
        if mwall(ex+1, ey) == 0 then ex = ex + 1 end
      end
      if ddx < 0 then
        if mwall(ex-1, ey) == 0 then ex = ex - 1 end
      end
      if ddy > 0 then
        if mwall(ex, ey+1) == 0 then ey = ey + 1 end
      end
      if ddy < 0 then
        if mwall(ex, ey-1) == 0 then ey = ey - 1 end
      end
      -- damage if adjacent
      if ddx < 0 then ddx = 0 - ddx end
      if ddy < 0 then ddy = 0 - ddy end
      if ddx + ddy <= 1 then
        health = health - 5
      end
    end
  end

  if flash > 0 then flash = flash - 1 end
  if health <= 0 then running = 0 end

  tick = tick + 1
  if tick >= 2 then tick = 0 end

  render()
  time.sleep_ms(60)
end

-- GAME OVER
scr.clear()
if health <= 0 then
  scr.text("YOU DIED", 18, 14, 1)
else
  scr.text("ESCAPED", 22, 14, 1)
end
scr.text("Score:", 22, 34)
scr.text(score, 70, 34)
scr.text("Ammo:", 22, 44)
scr.text(ammo, 70, 44)
scr.text("press OK", 26, 56)
scr.show()
btn.wait()
