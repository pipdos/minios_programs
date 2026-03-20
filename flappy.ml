-- Flappy Bird для MiniOS / MiniLang
-- Выход: зажать left + right

-- ── Константы ──────────────────────────────────────────
var SCR_W = 128
var SCR_H = 64

var GRAVITY    = 0.35
var JUMP_VEL   = -3.2
var PIPE_SPEED = 1.5
var PIPE_W     = 10
var PIPE_GAP   = 20
var BIRD_X     = 20
var BIRD_SIZE  = 6

-- ── Переменные игры ────────────────────────────────────
var bird_y    = 30
var bird_vy   = 0
var score     = 0
var best      = 0
var alive     = 1
var frame     = 0

-- Трубы (3 штуки в очереди)
var p1x = 128
var p1h = 20
var p2x = 171
var p2h = 30
var p3x = 214
var p3h = 15

var scored1 = 0
var scored2 = 0
var scored3 = 0

-- ── Спрайт птицы ───────────────────────────────────────
var bird = spr.new(BIRD_X, bird_y, BIRD_SIZE, BIRD_SIZE)

-- ── Функции ────────────────────────────────────────────

func rand_pipe_h()
  return math.rand(28) + 8
end

func reset_pipe(px, ph)
  return 0
end

func draw_pipe(px, ph)
  -- Верхняя труба
  scr.frect(px, 0, PIPE_W, ph)
  -- Нижняя труба
  var bot_y = ph + PIPE_GAP
  var bot_h = SCR_H - bot_y
  scr.frect(px, bot_y, PIPE_W, bot_h)
  -- Шапки труб
  scr.rect(px - 1, ph - 3, PIPE_W + 2, 4)
  scr.rect(px - 1, bot_y, PIPE_W + 2, 4)
end

func check_pipe_hit(px, ph)
  var bx = BIRD_X
  var by = bird_y
  var bx2 = bx + BIRD_SIZE
  var by2 = by + BIRD_SIZE
  var px2 = px + PIPE_W
  -- Хитбокс труб (немного прощаем краи)
  if bx2 > px + 1 and bx < px2 - 1 then
    if by < ph - 1 then
      alive = 0
    end
    var bot_y = ph + PIPE_GAP
    if by2 > bot_y + 1 then
      alive = 0
    end
  end
end

-- ── Экран смерти ───────────────────────────────────────
func show_death()
  scr.clear()
  scr.text("GAME OVER", 20, 10)
  scr.text("Score:", 20, 25)
  var s_str = str.str(score)
  scr.text(s_str, 70, 25)
  scr.text("Best:", 20, 36)
  var b_str = str.str(best)
  scr.text(b_str, 70, 36)
  scr.text("OK - restart", 12, 52)
  scr.show()
  btn.wait(20000)
end

-- ── Экран старта ───────────────────────────────────────
func show_start()
  scr.clear()
  scr.text("FLAPPY BIRD", 14, 8, 1)
  scr.text("Press OK", 28, 30)
  scr.text("to start", 30, 42)
  scr.text("L+R = exit", 20, 54)
  scr.show()
  var b = btn.wait(30000)
  if b == "" then
    exit()
  end
end

-- ── ГЛАВНЫЙ ЦИКЛ ───────────────────────────────────────

show_start()

while 1 do
  -- Проверка выхода L+R
  if btn.combo() == "lr" then
    exit()
  end

  -- ── Чтение кнопок ────────────────────────────────────
  var b = btn.read()
  if b == "ok" or b == "up" then
    if alive == 1 then
      bird_vy = JUMP_VEL
    end
  end

  -- ── Физика птицы ─────────────────────────────────────
  if alive == 1 then
    bird_vy = bird_vy + GRAVITY
    bird_y  = bird_y + bird_vy

    -- Удар об пол / потолок
    if bird_y < 0 then
      bird_y = 0
      bird_vy = 0
    end
    if bird_y + BIRD_SIZE >= SCR_H then
      alive = 0
    end

    -- ── Трубы ─────────────────────────────────────────
    p1x = p1x - PIPE_SPEED
    p2x = p2x - PIPE_SPEED
    p3x = p3x - PIPE_SPEED

    -- Перерождение труб за экраном
    if p1x < 0 - PIPE_W then
      p1x = SCR_W + 10
      p1h = rand_pipe_h()
      scored1 = 0
    end
    if p2x < 0 - PIPE_W then
      p2x = SCR_W + 10
      p2h = rand_pipe_h()
      scored2 = 0
    end
    if p3x < 0 - PIPE_W then
      p3x = SCR_W + 10
      p3h = rand_pipe_h()
      scored3 = 0
    end

    -- Очки: птица пролетела трубу
    if scored1 == 0 and p1x + PIPE_W < BIRD_X then
      score = score + 1
      scored1 = 1
    end
    if scored2 == 0 and p2x + PIPE_W < BIRD_X then
      score = score + 1
      scored2 = 1
    end
    if scored3 == 0 and p3x + PIPE_W < BIRD_X then
      score = score + 1
      scored3 = 1
    end

    -- Столкновения
    check_pipe_hit(p1x, p1h)
    check_pipe_hit(p2x, p2h)
    check_pipe_hit(p3x, p3h)
  end

  -- ── Рисование ────────────────────────────────────────
  scr.clear()

  -- Трубы
  draw_pipe(p1x, p1h)
  draw_pipe(p2x, p2h)
  draw_pipe(p3x, p3h)

  -- Птица
  spr.pos(bird, BIRD_X, bird_y)
  spr.fdraw(bird)
  -- Клюв (маленький треугольник вправо)
  scr.pixel(BIRD_X + BIRD_SIZE, bird_y + 2)
  scr.pixel(BIRD_X + BIRD_SIZE, bird_y + 3)
  -- Глаз
  scr.pixel(BIRD_X + 4, bird_y + 1)

  -- Земля
  scr.line(0, SCR_H - 1, SCR_W, SCR_H - 1)

  -- Счёт
  var sc_str = str.str(score)
  scr.text(sc_str, 55, 2)

  scr.show()

  -- ── Смерть ───────────────────────────────────────────
  if alive == 0 then
    if score > best then
      best = score
    end
    show_death()

    -- Сброс игры
    bird_y  = 30
    bird_vy = 0
    score   = 0
    alive   = 1
    p1x = 128
    p1h = rand_pipe_h()
    p2x = 171
    p2h = rand_pipe_h()
    p3x = 214
    p3h = rand_pipe_h()
    scored1 = 0
    scored2 = 0
    scored3 = 0
    spr.pos(bird, BIRD_X, bird_y)
  end

  time.sleep_ms(28)
end
