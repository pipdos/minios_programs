-- Mario для MiniOS / MiniLang
-- Экран: 128x64 пикселей
-- Управление: left/right - движение, ok - прыжок, left+right - выход

-- Константы
var SCR_W = 128
var SCR_H = 64
var GRAVITY = 0.5
var JUMP_FORCE = -5
var SPEED = 2
var GROUND_Y = 54

-- Состояние игрока
var px = 10
var py = GROUND_Y
var pvx = 0
var pvy = 0
var on_ground = 0
var score = 0
var lives = 3
var dead = 0
var dead_timer = 0

-- Спрайт игрока (8x8)
var player = spr.new(px, py, 8, 8)

-- Платформы: x, y, ширина
var plat_x = [30, 70, 95, 10, 55]
var plat_y = [44, 36, 48, 30, 22]
var plat_w = [24, 20, 18, 20, 22]

-- Монеты: x, y, активна
var coin_x = [38, 78, 102, 18, 63]
var coin_y = [38, 30, 42, 24, 16]
var coin_on = [1, 1, 1, 1, 1]

-- Враг
var ex = 80
var ey = GROUND_Y
var evx = -1
var enemy = spr.new(ex, ey, 8, 8)

-- Анимация
var anim = 0
var frame = 0
var game_over = 0

-- Вспомогательная: проверка пересечения с платформой
func check_platform(i)
  var px2 = arr.get(plat_x, i)
  var py2 = arr.get(plat_y, i)
  var pw2 = arr.get(plat_w, i)
  if px + 8 > px2 and px < px2 + pw2 and pvy >= 0 and py + 8 > py2 and py + 8 < py2 + 8 then
    py = py2 - 8
    pvy = 0
    on_ground = 1
  end
end

-- Нарисовать платформу
func draw_platform(i)
  var px2 = arr.get(plat_x, i)
  var py2 = arr.get(plat_y, i)
  var pw2 = arr.get(plat_w, i)
  scr.frect(px2, py2, pw2, 4)
end

-- Нарисовать монету
func draw_coin(i)
  var ca = arr.get(coin_on, i)
  if ca == 1 then
    var cx = arr.get(coin_x, i)
    var cy = arr.get(coin_y, i)
    scr.circle(cx + 2, cy + 2, 2)
  end
end

-- Сбор монет
func check_coins()
  var i = 0
  while i < 5 do
    var ca = arr.get(coin_on, i)
    if ca == 1 then
      var cx = arr.get(coin_x, i)
      var cy = arr.get(coin_y, i)
      if px + 8 > cx and px < cx + 5 and py + 8 > cy and py < cy + 5 then
        arr.set(coin_on, i, 0)
        score = score + 10
      end
    end
    i = i + 1
  end
end

-- Нарисовать игрока (анимация)
func draw_player()
  spr.pos(player, px, py)
  spr.draw(player)
  if on_ground == 1 then
    if pvx ~= 0 then
      if frame == 0 then
        scr.line(px+1, py+8, px+3, py+5)
        scr.line(px+5, py+8, px+7, py+5)
      else
        scr.line(px+1, py+5, px+3, py+8)
        scr.line(px+5, py+5, px+7, py+8)
      end
    end
  end
  scr.pixel(px+2, py+2)
  scr.pixel(px+5, py+2)
  scr.line(px+2, py+4, px+5, py+4)
end

-- Нарисовать врага
func draw_enemy()
  spr.pos(enemy, ex, ey)
  spr.fdraw(enemy)
  scr.pixel(ex+2, ey+2)
  scr.pixel(ex+5, ey+2)
end

-- Нарисовать HUD
func draw_hud()
  scr.text(str.cat("SC:", str.str(score)), 0, 0, 1)
  scr.text(str.cat("HP:", str.str(lives)), 80, 0, 1)
end

-- Нарисовать землю
func draw_ground()
  scr.line(0, GROUND_Y + 8, SCR_W - 1, GROUND_Y + 8)
  scr.frect(0, GROUND_Y + 9, SCR_W, 4)
end

-- Смерть игрока
func player_die()
  lives = lives - 1
  dead = 1
  dead_timer = 60
  if lives <= 0 then
    game_over = 1
  end
end

-- Экран смерти / игры окончена
func show_death()
  scr.clear()
  if game_over == 1 then
    scr.text("GAME OVER", 22, 20, 1)
    scr.text(str.cat("Score:", str.str(score)), 30, 35, 1)
    scr.text("ok - restart", 20, 48, 1)
  else
    scr.text("OUCH!", 45, 24, 1)
    scr.text(str.cat("Lives:", str.str(lives)), 38, 36, 1)
  end
  scr.show()
end

-- Сброс позиции игрока
func respawn()
  px = 10
  py = GROUND_Y
  pvx = 0
  pvy = 0
  on_ground = 0
  dead = 0
  spr.pos(player, px, py)
end

-- Полный сброс игры
func restart_game()
  score = 0
  lives = 3
  game_over = 0
  dead = 0
  dead_timer = 0
  ex = 80
  evx = -1
  arr.set(coin_on, 0, 1)
  arr.set(coin_on, 1, 1)
  arr.set(coin_on, 2, 1)
  arr.set(coin_on, 3, 1)
  arr.set(coin_on, 4, 1)
  respawn()
end

-- Главный цикл
while 1 do

  -- Если мёртв
  if dead == 1 then
    show_death()
    dead_timer = dead_timer - 1
    if dead_timer <= 0 then
      if game_over == 1 then
        var b = btn.read()
        if b == "ok" then
          restart_game()
        end
      else
        respawn()
      end
    end
    time.sleep_ms(16)
    continue
  end

  -- Ввод
  var held_l = btn.held("left")
  var held_r = btn.held("right")
  var held_ok = btn.held("ok")
  var b2 = btn.read()

  pvx = 0
  if held_l == 1 then
    pvx = -SPEED
  end
  if held_r == 1 then
    pvx = SPEED
  end

  -- Прыжок
  if b2 == "ok" and on_ground == 1 then
    pvy = JUMP_FORCE
    on_ground = 0
  end

  -- Гравитация
  pvy = pvy + GRAVITY
  px = px + pvx
  py = py + pvy

  -- Границы экрана
  if px < 0 then
    px = 0
  end
  if px > SCR_W - 8 then
    px = SCR_W - 8
  end

  -- Земля
  on_ground = 0
  if py >= GROUND_Y then
    py = GROUND_Y
    pvy = 0
    on_ground = 1
  end

  -- Упал за экран (ямы нет, но на всякий)
  if py > SCR_H then
    player_die()
    continue
  end

  -- Платформы
  var pi = 0
  while pi < 5 do
    check_platform(pi)
    pi = pi + 1
  end

  -- Анимация ног
  anim = anim + 1
  if anim >= 8 then
    anim = 0
    if frame == 0 then
      frame = 1
    else
      frame = 0
    end
  end

  -- Монеты
  check_coins()

  -- Враг: движение
  ex = ex + evx
  spr.pos(enemy, ex, ey)

  -- Враг разворачивается у стен
  if ex <= 20 then
    evx = 1
  end
  if ex >= 100 then
    evx = -1
  end

  -- Проверка: прыгнул ли на врага
  spr.pos(player, px, py)
  spr.pos(enemy, ex, ey)
  if spr.hit(player, enemy) == 1 then
    if pvy > 0 and py + 8 < ey + 4 then
      -- Прыгнул сверху — убил врага
      score = score + 50
      ex = 200
      evx = 0
      spr.pos(enemy, ex, ey)
      pvy = JUMP_FORCE / 2
    else
      -- Столкновение сбоку — смерть
      player_die()
      continue
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
