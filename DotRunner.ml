-- MiniMan v1.1 — исправленные коллизии
-- Управление: left/right - движение, ok - прыжок, left+right - выход

var SCR_W = 128
var SCR_H = 64
var GRAVITY = 0.4
var JUMP_FORCE = -5
var SPEED = 2
var GROUND_Y = 54

var px = 10
var py = GROUND_Y
var pvx = 0
var pvy = 0
var on_ground = 0
var score = 0
var lives = 3
var dead = 0
var dead_timer = 0
var game_over = 0
var anim = 0
var frame = 0

-- Враг стартует далеко справа
var ex = 110
var ey = GROUND_Y
var evx = -1
var enemy_alive = 1

var player = spr.new(px, py, 7, 8)
var enemy = spr.new(ex, ey, 7, 8)

var plat_x = [30, 70, 95, 10, 55]
var plat_y = [44, 36, 48, 30, 22]
var plat_w = [24, 20, 18, 20, 22]

var coin_x = [38, 78, 102, 18, 63]
var coin_y = [38, 30, 42, 24, 16]
var coin_on = [1, 1, 1, 1, 1]

func check_platform(i)
  var px2 = arr.get(plat_x, i)
  var py2 = arr.get(plat_y, i)
  var pw2 = arr.get(plat_w, i)
  -- Только падение сверху: игрок был выше платформы
  if px + 7 > px2 and px < px2 + pw2 then
    if pvy >= 0 and py + 8 >= py2 and py + 8 <= py2 + 6 then
      py = py2 - 8
      pvy = 0
      on_ground = 1
    end
  end
end

func draw_platform(i)
  var px2 = arr.get(plat_x, i)
  var py2 = arr.get(plat_y, i)
  var pw2 = arr.get(plat_w, i)
  scr.frect(px2, py2, pw2, 3)
end

func draw_coin(i)
  var ca = arr.get(coin_on, i)
  if ca == 1 then
    var cx = arr.get(coin_x, i)
    var cy = arr.get(coin_y, i)
    scr.circle(cx + 2, cy + 2, 2)
  end
end

func check_coins()
  var i = 0
  while i < 5 do
    var ca = arr.get(coin_on, i)
    if ca == 1 then
      var cx = arr.get(coin_x, i)
      var cy = arr.get(coin_y, i)
      if px + 7 > cx and px < cx + 5 and py + 8 > cy and py < cy + 5 then
        arr.set(coin_on, i, 0)
        score = score + 10
      end
    end
    i = i + 1
  end
end

func draw_player()
  scr.rect(px, py, 7, 8)
  scr.pixel(px+1, py+2)
  scr.pixel(px+5, py+2)
  if on_ground == 1 and pvx ~= 0 then
    if frame == 0 then
      scr.line(px+1, py+8, px+3, py+6)
      scr.line(px+4, py+6, px+6, py+8)
    else
      scr.line(px+1, py+6, px+3, py+8)
      scr.line(px+4, py+8, px+6, py+6)
    end
  end
end

func draw_enemy()
  if enemy_alive == 1 then
    scr.frect(ex, ey, 7, 8)
    scr.pixel(ex+1, ey+2)
    scr.pixel(ex+5, ey+2)
  end
end

func draw_hud()
  scr.text(str.cat("SC:", str.str(score)), 0, 0, 1)
  scr.text(str.cat("HP:", str.str(lives)), 88, 0, 1)
end

func draw_ground()
  scr.frect(0, GROUND_Y + 8, SCR_W, 4)
end

func player_die()
  lives = lives - 1
  dead = 1
  dead_timer = 80
  if lives <= 0 then
    game_over = 1
  end
end

func respawn()
  px = 10
  py = GROUND_Y
  pvx = 0
  pvy = 0
  on_ground = 0
  dead = 0
  spr.pos(player, px, py)
end

func restart_game()
  score = 0
  lives = 3
  game_over = 0
  dead = 0
  dead_timer = 0
  ex = 110
  ey = GROUND_Y
  evx = -1
  enemy_alive = 1
  arr.set(coin_on, 0, 1)
  arr.set(coin_on, 1, 1)
  arr.set(coin_on, 2, 1)
  arr.set(coin_on, 3, 1)
  arr.set(coin_on, 4, 1)
  respawn()
end

-- Главный цикл
while 1 do

  if dead == 1 then
    scr.clear()
    if game_over == 1 then
      scr.text("GAME OVER", 22, 18, 1)
      scr.text(str.cat("Score:", str.str(score)), 28, 32, 1)
      scr.text("ok = restart", 20, 46, 1)
    else
      scr.text("OUCH!", 44, 22, 1)
      scr.text(str.cat("Lives:", str.str(lives)), 36, 36, 1)
    end
    scr.show()
    dead_timer = dead_timer - 1
    if dead_timer <= 0 then
      if game_over == 1 then
        var bw = btn.read()
        if bw == "ok" then
          restart_game()
        end
        dead_timer = 1
      else
        respawn()
      end
    end
    time.sleep_ms(16)
    continue
  end

  -- Ввод
  var hl = btn.held("left")
  var hr = btn.held("right")
  var b2 = btn.read()

  pvx = 0
  if hl == 1 then
    pvx = -SPEED
  end
  if hr == 1 then
    pvx = SPEED
  end
  if b2 == "ok" and on_ground == 1 then
    pvy = JUMP_FORCE
    on_ground = 0
  end

  -- Физика
  pvy = pvy + GRAVITY
  if pvy > 6 then
    pvy = 6
  end
  px = px + pvx
  py = py + pvy

  -- Границы
  if px < 0 then
    px = 0
  end
  if px > SCR_W - 7 then
    px = SCR_W - 7
  end

  -- Земля
  on_ground = 0
  if py >= GROUND_Y then
    py = GROUND_Y
    pvy = 0
    on_ground = 1
  end

  -- Платформы
  var pi = 0
  while pi < 5 do
    check_platform(pi)
    pi = pi + 1
  end

  -- Анимация
  anim = anim + 1
  if anim >= 10 then
    anim = 0
    if frame == 0 then
      frame = 1
    else
      frame = 0
    end
  end

  -- Монеты
  check_coins()

  -- Враг
  if enemy_alive == 1 then
    ex = ex + evx
    if ex <= 20 then
      evx = 1
    end
    if ex >= 108 then
      evx = -1
    end
    spr.pos(enemy, ex, ey)

    -- Коллизия игрок-враг
    spr.pos(player, px, py)
    var hit = spr.hit(player, enemy)
    if hit == 1 then
      -- Прыжок сверху: игрок падает (pvy > 0) и нижний край игрока
      -- не глубже середины врага
      if pvy > 0 and py + 8 < ey + 5 then
        score = score + 50
        enemy_alive = 0
        pvy = -3
      else
        -- Боковое касание — только если враг живой и реально рядом
        player_die()
      end
    end
  end

  -- Отрисовка
  scr.clear()
  draw_ground()
  var di = 0
  while di < 5 do
    draw_platform(di)
    di = di + 1
  end
  di = 0
  while di < 5 do
    draw_coin(di)
    di = di + 1
  end
  draw_enemy()
  draw_player()
  draw_hud()
  scr.show()

  time.sleep_ms(33)
end
