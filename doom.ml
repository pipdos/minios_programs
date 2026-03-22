-- DOOM.ML  raycaster for MiniOS 128x64
-- Controls: LEFT/RIGHT = turn, UP = move forward, DOWN = move back
-- OK = shoot, L+R = exit

-- ── MAP 8x8 ──────────────────────────────────────────────────────────────
-- 1=wall 0=floor
var map = [
  1,1,1,1,1,1,1,1,
  1,0,0,0,0,0,0,1,
  1,0,1,1,0,1,0,1,
  1,0,1,0,0,0,0,1,
  1,0,0,0,1,0,1,1,
  1,0,1,0,0,0,0,1,
  1,0,0,0,0,0,0,1,
  1,1,1,1,1,1,1,1
]
var MAP_W = 8
var MAP_H = 8

-- ── PLAYER ───────────────────────────────────────────────────────────────
var px = 160   -- fixed point x16: real=10.0
var py = 96    -- fixed point x16: real=6.0
-- angle in degrees * 4 (0..1439)
var pa = 0
-- speed
var MOVE_SPD = 6
var TURN_SPD = 18

-- ── SCREEN ───────────────────────────────────────────────────────────────
var SCR_W = 96    -- render width (leaving 32px for HUD)
var SCR_H = 64
var HALF_H = 32
var FOV = 60      -- degrees

-- ── SINE TABLE (0..90 deg, *256) ─────────────────────────────────────────
-- We store sin*256 for angles 0..360 in steps of 1 deg
-- Too large for 360 entries, use formula approximation instead
-- sin(x) approx via linear interpolation of 10 key points
-- We'll use a tiny fixed-point sin via Taylor isn't ideal on ESP32 without float
-- MiniLang has no trig, so we use a 24-entry table (every 15 deg)
var SIN24 = [
  0, 66, 128, 185, 234, 269, 290, 298,
  290, 269, 234, 185, 128, 66, 0,
  -66, -128, -185, -234, -269, -290, -298, -290, -269
]
-- SIN24[i] = sin(i*15 deg)*298, i=0..23

func sin256(adeg)
  -- returns sin(adeg)*256, adeg in degrees
  -- normalize
  var a = adeg
  while a < 0 do
    a = a + 360
  end
  while a >= 360 do
    a = a - 360
  end
  -- which 15-deg bucket
  var idx = math.floor(a / 15)
  var frac = a - idx * 15
  var i0 = idx
  var i1 = i0 + 1
  if i1 >= 24 then
    i1 = 0
  end
  var s0 = arr.get(SIN24, i0)
  var s1 = arr.get(SIN24, i1)
  -- lerp * 256/298
  var sv = s0 + (s1 - s0) * frac / 15
  return sv * 256 / 298
end

func cos256(adeg)
  return sin256(adeg + 90)
end

-- ── MAP LOOKUP ────────────────────────────────────────────────────────────
func map_get(mx, my)
  if mx < 0 or mx >= MAP_W then
    return 1
  end
  if my < 0 or my >= MAP_H then
    return 1
  end
  var idx = my * MAP_W + mx
  return arr.get(map, idx)
end

-- ── DRAW COLUMN ───────────────────────────────────────────────────────────
-- x=column(0..SCR_W-1), dist=distance*256
func draw_col(cx, dist)
  if dist <= 0 then
    dist = 1
  end
  -- wall height: 32*256/dist (tune scale)
  var h = 2048 / dist
  if h > SCR_H then
    h = SCR_H
  end
  var top = HALF_H - h / 2
  var bot = HALF_H + h / 2
  if top < 0 then
    top = 0
  end
  if bot > SCR_H then
    bot = SCR_H - 1
  end
  -- floor (bottom half) - dots
  -- wall (solid line)
  scr.line(cx, top, cx, bot)
end

-- ── RAYCASTER ─────────────────────────────────────────────────────────────
func render()
  scr.clear()

  -- ceiling (top half fill)
  -- leave ceiling black, just draw floor dots
  var fy = HALF_H
  while fy < SCR_H do
    var fx = 0
    while fx < SCR_W do
      scr.pixel(fx, fy)
      fx = fx + 3
    end
    fy = fy + 2
  end

  -- cast SCR_W rays
  var ray = 0
  while ray < SCR_W do
    -- ray angle = player_angle - FOV/2 + ray*(FOV/SCR_W)
    var ra_deg = pa / 4 - 30 + ray * 60 / SCR_W
    while ra_deg < 0 do
      ra_deg = ra_deg + 360
    end
    while ra_deg >= 360 do
      ra_deg = ra_deg - 360
    end

    var rdx = cos256(ra_deg)  -- *256
    var rdy = sin256(ra_deg)  -- *256

    -- DDA raycasting in fixed point
    -- player pos in fixed*16
    var rx = px   -- x16
    var ry = py   -- x16

    var hit = 0
    var dist = 0
    var steps = 0
    while hit == 0 and steps < 64 do
      -- step along ray
      rx = rx + rdx / 8
      ry = ry + rdy / 8
      -- map cell
      var mx = rx / 16
      var my = ry / 16
      if map_get(mx, my) == 1 then
        hit = 1
        -- distance = approx euclidean from player
        var ddx = rx - px
        var ddy = ry - py
        -- dist in fixed*16, we want dist*256 for draw_col
        -- |d| = sqrt(ddx^2+ddy^2)/16 * 16 = sqrt(ddx^2+ddy^2)
        var dsq = ddx * ddx / 256 + ddy * ddy / 256
        dist = math.sqrt(dsq)
        -- fish-eye fix: multiply by cos(ra - pa/4)
        var diff = ra_deg - pa / 4
        while diff < -180 do
          diff = diff + 360
        end
        while diff > 180 do
          diff = diff - 360
        end
        if diff < 0 then
          diff = 0 - diff
        end
        -- cos256(diff) is 0..256
        var cv = cos256(diff)
        if cv > 16 then
          dist = dist * cv / 256
        end
        if dist < 1 then
          dist = 1
        end
      end
      steps = steps + 1
    end

    if hit == 1 then
      draw_col(ray, dist)
    end

    ray = ray + 1
  end

  -- HUD (right 32px)
  scr.frect(97, 0, 31, 64)

  -- mini-map 16x16 in HUD
  var mm = 0
  while mm < MAP_H do
    var mn = 0
    while mn < MAP_W do
      if map_get(mn, mm) == 1 then
        var tx = 97 + mn * 2
        var ty = mm * 2
        scr.pixel(tx, ty)
        scr.pixel(tx + 1, ty)
        scr.pixel(tx, ty + 1)
        scr.pixel(tx + 1, ty + 1)
      end
      mn = mn + 1
    end
    mm = mm + 1
  end

  -- player dot on mini-map
  var pdx = 97 + px / 8
  var pdy = py / 8
  scr.pixel(pdx, pdy)
  scr.pixel(pdx + 1, pdy)

  -- health bar
  scr.rect(97, 52, 30, 6)
  scr.frect(98, 53, health / 4, 4)

  scr.show()
end

-- ── MOVEMENT ──────────────────────────────────────────────────────────────
func try_move(dx, dy)
  var nx = px + dx
  var ny = py + dy
  var mx = nx / 16
  var my = py / 16
  if map_get(mx, my) == 0 then
    px = nx
  end
  mx = px / 16
  my = ny / 16
  if map_get(mx, my) == 0 then
    py = ny
  end
end

-- ── ENEMY ─────────────────────────────────────────────────────────────────
var ex = 80    -- fixed*16
var ey = 48
var e_alive = 1
var e_hp = 3

-- ── GAME STATE ────────────────────────────────────────────────────────────
var health = 100
var ammo   = 20
var score  = 0
var shooting = 0
var shoot_timer = 0
var game_over = 0

-- ── MAIN LOOP ─────────────────────────────────────────────────────────────
scr.clear()
scr.text("DOOM.ML", 30, 20, 2)
scr.text("OK = Start", 28, 48)
scr.show()
btn.wait()

while game_over == 0 do
  -- INPUT
  var b = btn.combo()
  if b == "exit" then
    game_over = 2
  end

  var b2 = btn.read()

  if btn.held("left") == 1 then
    pa = pa - TURN_SPD
    if pa < 0 then
      pa = pa + 1440
    end
  end
  if btn.held("right") == 1 then
    pa = pa + TURN_SPD
    if pa >= 1440 then
      pa = pa - 1440
    end
  end

  if btn.held("up") == 1 then
    var adeg = pa / 4
    var mdx = cos256(adeg) * MOVE_SPD / 256
    var mdy = sin256(adeg) * MOVE_SPD / 256
    try_move(mdx, mdy)
  end

  if btn.held("down") == 1 then
    var adeg = pa / 4
    var mdx = cos256(adeg) * MOVE_SPD / 256
    var mdy = sin256(adeg) * MOVE_SPD / 256
    try_move(0 - mdx, 0 - mdy)
  end

  if b2 == "ok" then
    if ammo > 0 then
      ammo = ammo - 1
      shooting = 4
      -- hit check: if enemy in front
      if e_alive == 1 then
        var ddx = ex - px
        var ddy = ey - py
        var dsq = ddx * ddx + ddy * ddy
        if dsq < 2048 then
          e_hp = e_hp - 1
          score = score + 10
          if e_hp <= 0 then
            e_alive = 0
            score = score + 50
          end
        end
      end
    end
  end

  -- enemy simple AI: move toward player
  if e_alive == 1 then
    var ddx = px - ex
    var ddy = py - ey
    var dsq = ddx * ddx + ddy * ddy
    if dsq > 64 then
      if ddx > 0 then
        ex = ex + 1
      end
      if ddx < 0 then
        ex = ex - 1
      end
      if ddy > 0 then
        ey = ey + 1
      end
      if ddy < 0 then
        ey = ey - 1
      end
    end
    -- enemy hits player
    if dsq < 512 then
      health = health - 1
      if health <= 0 then
        game_over = 1
      end
    end
  end

  -- shoot timer
  if shooting > 0 then
    shooting = shooting - 1
  end

  -- RENDER
  render()

  -- crosshair
  scr.pixel(47, 31)
  scr.pixel(46, 32)
  scr.pixel(47, 32)
  scr.pixel(48, 32)
  scr.pixel(47, 33)

  -- gun sprite
  if shooting > 0 then
    -- muzzle flash
    scr.line(40, 55, 44, 50)
    scr.line(52, 55, 48, 50)
    scr.pixel(46, 48)
    scr.pixel(47, 47)
  end
  -- gun body
  scr.frect(38, 56, 20, 8)
  scr.frect(43, 52, 10, 6)

  -- ammo counter
  scr.text(ammo, 99, 42)

  scr.show()

  time.sleep_ms(50)
end

-- GAME OVER SCREEN
scr.clear()
if game_over == 1 then
  scr.text("DEAD", 36, 16, 2)
  scr.text("You died!", 24, 40)
else
  scr.text("ESCAPED", 16, 16, 2)
end
scr.text("Score:", 20, 50)
scr.text(score, 68, 50)
scr.show()
btn.wait()
