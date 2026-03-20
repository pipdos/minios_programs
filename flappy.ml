-- Flappy Bird для MiniOS / MiniLang
-- Прыжок: OK или UP
-- Выход: держать LEFT + RIGHT

-- ── Константы ──────────────────────────────────────────
var SCR_W      = 128
var SCR_H      = 64
var GRAVITY    = 0.35
var JUMP_VEL   = -3.2
var PIPE_SPEED = 1.5
var PIPE_W     = 10
var PIPE_GAP   = 20
var BIRD_X     = 20
var BIRD_SIZE  = 6

-- ── Состояние игры ─────────────────────────────────────
var bird_y  = 30
var bird_vy = 0
var score   = 0
var best    = 0
var alive   = 1

-- Трубы
var p1x = 128
var p1h = 20
var p2x = 171
var p2h = 30
var p3x = 214
var p3h = 15
var scored1 = 0
var scored2 = 0
var scored3 = 0

-- Дебаунс прыжка и выход
var ok_prev   = 0
var exit_hold = 0

-- ── Спрайт птицы ───────────────────────────────────────
var bird = spr.new(BIRD_X, bird_y, BIRD_SIZE, BIRD_SIZE)

-- ── Функции ────────────────────────────────────────────

func rand_h()
  return math.rand(24) + 8
end

func draw_pipes()
  scr.frect(p1x, 0, PIPE_W, p1h)
  scr.frect(p1x, p1h + PIPE_GAP, PIPE_W, SCR_H)
  scr.rect(p1x - 1, p1h - 3, PIPE_W + 2, 4)
  scr.rect(p1x - 1, p1h + PIPE_GAP, PIPE_W + 2, 4)
  scr.frect(p2x, 0, PIPE_W, p2h)
  scr.frect(p2x, p2h + PIPE_GAP, PIPE_W, SCR_H)
  scr.rect(p2x - 1, p2h - 3, PIPE_W + 2, 4)
  scr.rect(p2x - 1, p2h + PIPE_GAP, PIPE_W + 2, 4)
  scr.frect(p3x, 0, PIPE_W, p3h)
  scr.frect(p3x, p3h + PIPE_GAP, PIPE_W, SCR_H)
  scr.rect(p3x - 1, p3h - 3, PIPE_W + 2, 4)
  scr.rect(p3x - 1, p3h + PIPE_GAP, PIPE_W + 2, 4)
end

func hit_pipe(px, ph)
  if BIRD_X + BIRD_SIZE > px + 1 and BIRD_X < px + PIPE_W - 1 then
    if bird_y < ph - 1 then
      alive = 0
    end
    if bird_y + BIRD_SIZE > ph + PIPE_GAP + 1 then
      alive = 0
    end
  end
end

func reset_game()
  bird_y    = 30
  bird_vy   = 0
  score     = 0
  alive     = 1
  p1x       = 128
  p1h       = rand_h()
  p2x       = 171
  p2h       = rand_h()
  p3x       = 214
  p3h       = rand_h()
  scored1   = 0
  scored2   = 0
  scored3   = 0
  ok_prev   = 1
  exit_hold = 0
  spr.pos(bird, BIRD_X, bird_y)
end

-- ── Стартовый экран ────────────────────────────────────
scr.clear()
scr.text("FLAPPY BIRD", 14, 6, 1)
scr.text("Press OK to play", 4, 28)
scr.text("Hold L+R to exit", 4, 40)
scr.show()

var started = 0
while started == 0 do
  if btn.held("ok") == 1 then
    started = 1
  end
  if btn.held("left") == 1 and btn.held("right") == 1 then
    exit()
  end
  time.sleep_ms(20)
end
while btn.held("ok") == 1 do
  time.sleep_ms(20)
end

-- ── ГЛАВНЫЙ ЦИКЛ ───────────────────────────────────────
while 1 do

  -- Выход: держать L+R
  if btn.held("left") == 1 and btn.held("right") == 1 then
    exit_hold = exit_hold + 1
  else
    exit_hold = 0
  end
  if exit_hold > 15 then
    exit()
  end

  -- Прыжок: held + дебаунс
  var ok_now = btn.held("ok")
  var up_now = btn.held("up")
  if ok_now == 1 or up_now == 1 then
    if ok_prev == 0 then
      if alive == 1 then
        bird_vy = JUMP_VEL
      end
    end
    ok_prev = 1
  else
    ok_prev = 0
  end

  -- Физика
  if alive == 1 then
    bird_vy = bird_vy + GRAVITY
    bird_y  = bird_y + bird_vy

    if bird_y < 0 then
      bird_y  = 0
      bird_vy = 0
    end
    if bird_y + BIRD_SIZE >= SCR_H - 1 then
      alive = 0
    end

    p1x = p1x - PIPE_SPEED
    p2x = p2x - PIPE_SPEED
    p3x = p3x - PIPE_SPEED

    if p1x < 0 - PIPE_W then
      p1x     = SCR_W + 10
      p1h     = rand_h()
      scored1 = 0
    end
    if p2x < 0 - PIPE_W then
      p2x     = SCR_W + 10
      p2h     = rand_h()
      scored2 = 0
    end
    if p3x < 0 - PIPE_W then
      p3x     = SCR_W + 10
      p3h     = rand_h()
      scored3 = 0
    end

    if scored1 == 0 and p1x + PIPE_W < BIRD_X then
      score   = score + 1
      scored1 = 1
    end
    if scored2 == 0 and p2x + PIPE_W < BIRD_X then
      score   = score + 1
      scored2 = 1
    end
    if scored3 == 0 and p3x + PIPE_W < BIRD_X then
      score   = score + 1
      scored3 = 1
    end

    hit_pipe(p1x, p1h)
    hit_pipe(p2x, p2h)
    hit_pipe(p3x, p3h)
  end

  -- Рисование
  scr.clear()
  draw_pipes()
  spr.pos(bird, BIRD_X, bird_y)
  spr.fdraw(bird)
  scr.pixel(BIRD_X + BIRD_SIZE, bird_y + 2)
  scr.pixel(BIRD_X + BIRD_SIZE, bird_y + 3)
  scr.pixel(BIRD_X + 4, bird_y + 1)
  scr.line(0, SCR_H - 1, SCR_W - 1, SCR_H - 1)
  scr.text(str.str(score), 55, 2)
  scr.show()

  -- Смерть
  if alive == 0 then
    if score > best then
      best = score
    end
    scr.clear()
    scr.text("GAME OVER", 20, 10)
    scr.text("Score:", 10, 25)
    scr.text(str.str(score), 55, 25)
    scr.text("Best:", 10, 36)
    scr.text(str.str(best), 55, 36)
    scr.text("OK=retry  L+R=exit", 0, 52)
    scr.show()

    var waiting = 1
    while waiting == 1 do
      if btn.held("ok") == 1 then
        waiting = 0
      end
      if btn.held("left") == 1 and btn.held("right") == 1 then
        exit()
      end
      time.sleep_ms(20)
    end
    while btn.held("ok") == 1 do
      time.sleep_ms(20)
    end

    reset_game()
  end

  time.sleep_ms(28)
end
