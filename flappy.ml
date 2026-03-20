-- Flappy Bird for MiniOS MiniLang
-- OK = прыжок, L+R+OK = выход

var bx = 20
var by = 32
var bvy = 0
var score = 0
var dead = false

-- труба
var px = 128
var pgap = 20
var pgy = 25
var pspeed = 2

func reset_pipe()
  px = 128
  pgy = math.rand(35) + 10
end

func draw_bird()
  scr.rect(bx, by, 6, 5)
  scr.pixel(bx + 5, by + 1)
end

func draw_pipe()
  scr.frect(px, 0, 8, pgy)
  scr.frect(px, pgy + pgap, 8, 64 - pgy - pgap)
end

reset_pipe()

while true do
  scr.clear()

  -- физика птицы
  bvy = bvy + 1
  by = by + bvy

  -- прыжок
  var b = btn.read()
  if b == "ok" then
    bvy = -4
  end

  -- двигаем трубу
  px = px - pspeed

  -- новая труба
  if px < -8 then
    reset_pipe()
    score = score + 1
    if pspeed < 5 then
      pspeed = pspeed + 0
    end
  end

  -- рисуем
  draw_bird()
  draw_pipe()

  -- счёт
  scr.text(score, 55, 0)

  -- границы
  if by < 0 then
    by = 0
    bvy = 0
  end

  -- смерть: пол или потолок
  if by > 58 then
    dead = true
  end

  -- смерть: труба
  if bx + 6 > px and bx < px + 8 then
    if by < pgy or by + 5 > pgy + pgap then
      dead = true
    end
  end

  if dead then
    scr.text("DEAD", 40, 25)
    scr.text("SC:", 36, 36)
    scr.text(score, 60, 36)
    scr.show()
    var w = btn.wait()
    -- сброс
    by = 32
    bvy = 0
    score = 0
    pspeed = 2
    dead = false
    reset_pipe()
  end

  scr.show()
  time.sleep_ms(50)
end
