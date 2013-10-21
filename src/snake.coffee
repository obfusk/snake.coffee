# <!-- {{{1 -->
#
#     File        : snake.coffee
#     Maintainer  : Felix C. Stegerman <flx@obfusk.net>
#     Date        : 2013-10-21
#
#     Copyright   : Copyright (C) 2013  Felix C. Stegerman
#     Licence     : GPLv3
#
# <!-- }}}1 -->

U = this._        || require 'underscore'
B = this.bigbang  || require 'bigbang'
S = exports ? this.snake ||= {}

# --

S.mk_pit = mk_pit = (snake, goos, opts) ->
  snake: snake, goos: goos, opts: opts

S.mk_snake  = mk_snake  = (dir, segs)   -> dir: dir, segs: segs
S.mk_goo    = mk_goo    = (loc, expire) -> loc: loc, expire: expire
S.mk_posn   = mk_posn   = (x, y)        -> x: x, y: y

# --

S.defaults = defaults =                                         # {{{1
  FPS:                10
  EXPIRATION_TIME:    50
  MAX_GOO:            5

  SEG_SIZE:           30
  ENDGAME_TEXT_SIZE:  '8em'

  BODY_IMG:           null
  CANVAS:             null
  GOO_IMG:            null
  HEAD_LEFT_IMG:      null
  HEAD_UP_IMG:        null
  HEAD_RIGHT_IMG:     null
  HEAD_DOWN_IMG:      null

  WIDTH:              30
  HEIGHT:             30
                                                                # }}}1

# --

S.start = start = (opts) ->                                     # {{{1
  o                 = U.extend {}, defaults, opts
  o.WIDTH_PX        = o.SEG_SIZE * o.WIDTH
  o.HEIGHT_PX       = o.SEG_SIZE * o.HEIGHT
  o.WIDTH_PX_HALF   = Math.round o.WIDTH_PX  / 2
  o.HEIGHT_PX_HALF  = Math.round o.HEIGHT_PX / 2
  o.MT_SCENE        = B.empty_scene o.WIDTH_PX, o.HEIGHT_PX
  w                 = mk_pit mk_snake('right', [mk_posn(1, 1)]),
                        (fresh_goo(o) for i in [1..6]), o
  bb_opts =
    canvas: o.CANVAS, fps: o.FPS, world: w, on_tick: next_pit,
    on_key: direct_snake, to_draw: render_pit, stop_when: is_dead,
    last_draw: render_end
  B bb_opts
                                                                # }}}1

S.next_pit = next_pit = (w) ->                                  # {{{1
  goo_to_eat = can_eat w.snake, w.goos
  if goo_to_eat
    mk_pit grow(w.snake),
      age_goo(eat(w.goos, goo_to_eat, w.opts), w.opts),
      w.opts
  else
    mk_pit slither(w.snake), age_goo(w.goos, w.opts), w.opts
                                                                # }}}1

S.direct_snake = direct_snake = (w, k) ->
  if is_dir k then world_change_dir w, k else w

S.render_pit = render_pit = (w) ->
  snake_and_scene w.snake,
    goo_list_and_scene(w.goos, w.opts.MT_SCENE, w.opts),
    w.opts

S.is_dead = is_dead = (w) ->
  is_self_colliding(w.snake) || is_wall_colliding(w.snake, w.opts)

S.render_end = render_end = (w) ->
  B.place_text 'Game over', w.opts.WIDTH_PX_HALF,
    w.opts.HEIGHT_PX_HALF, w.opts.ENDGAME_TEXT_SIZE, 'black',
    render_pit(w)

# --

S.can_eat = can_eat = (sn, goos) ->
  U.find goos, (x) -> is_close(snake_head(sn), x)

S.eat = eat = (goos, goo, opts) ->
  [fresh_goo(opts)].concat U.without(goos, goo)

S.is_close = is_close = (seg, goo) -> U.isEqual seg, goo.loc

S.grow = grow = (sn) ->
  mk_snake sn.dir, [next_head(sn)].concat(sn.segs)

# --

S.slither = slither = (sn) ->
  mk_snake sn.dir, [next_head(sn)].concat(U.initial(sn.segs))

S.next_head = next_head = (sn) ->                               # {{{1
  head = snake_head sn; dir = sn.dir
  switch
    when dir == 'up'    then posn_move head,  0, -1
    when dir == 'down'  then posn_move head,  0,  1
    when dir == 'left'  then posn_move head, -1,  0
    when dir == 'right' then posn_move head,  1,  0
                                                                # }}}1

S.posn_move = posn_move = (p, dx, dy) -> mk_posn p.x + dx, p.y + dy

# --

S.age_goo = age_goo = (goos, opts) -> rot renew(goos, opts)

S.renew = renew = (goos, opts) ->
  U.map goos, (x) -> if is_rotten x then fresh_goo(opts) else x

S.rot = rot = (goos) -> U.map goos, decay

S.is_rotten = is_rotten = (goo) -> goo.expire == 0

S.decay = decay = (goo) -> mk_goo goo.loc, goo.expire - 1

S.fresh_goo = fresh_goo = (opts) ->
  r = opts.random || random
  x = r 1, opts.WIDTH - 1; y = r 1, opts.HEIGHT - 1
  mk_goo mk_posn(x, y), opts.EXPIRATION_TIME

# --

S.is_dir = is_dir = (x) ->
  x == 'up' || x == 'down' || x == 'left' || x == 'right'

S.world_change_dir = world_change_dir = (w, d) ->
  sn = w.snake
  if is_opposite_dir(sn.dir, d) && sn.segs.length > 1
    B.stop_with w
  else
    mk_pit snake_change_dir(sn, d), w.goos, w.opts

S.is_opposite_dir = is_opposite_dir = (d1, d2) ->
  (d1 == 'up'     && d2 == 'down' ) ||
  (d1 == 'down'   && d2 == 'up'   ) ||
  (d1 == 'left'   && d2 == 'right') ||
  (d1 == 'right'  && d2 == 'left' )

# --

S.snake_and_scene = snake_and_scene = (sn, scene, opts) ->      # {{{1
  sn_body_scene = img_list_and_scene snake_body(sn),
    opts.BODY_IMG, scene, opts
  img = switch sn.dir
    when 'up'     then opts.HEAD_UP_IMG
    when 'down'   then opts.HEAD_DOWN_IMG
    when 'left'   then opts.HEAD_LEFT_IMG
    when 'right'  then opts.HEAD_RIGHT_IMG
  img_and_scene snake_head(sn), img, sn_body_scene, opts
                                                                # }}}1

S.goo_list_and_scene = goo_list_and_scene = (goos, scene, opts) ->
  posns = U.map goos, (x) -> x.loc
  img_list_and_scene posns, opts.GOO_IMG, scene, opts

S.img_list_and_scene = img_list_and_scene =
  (posns, img, scene, opts) ->
    f = (s, p) -> img_and_scene p, img, s, opts
    U.reduce posns, f, scene

S.img_and_scene = img_and_scene = (posn, img, scene, opts) ->
  B.place_image img, (posn.x * opts.SEG_SIZE),
    (posn.y * opts.SEG_SIZE), scene

# --

S.is_self_colliding = is_self_colliding = (sn) ->
  U.some snake_body(sn), (x) -> U.isEqual x, snake_head(sn)

S.is_wall_colliding = is_wall_colliding = (sn, opts) ->
  x = snake_head(sn).x; y = snake_head(sn).y
  x == 0 || x == opts.WIDTH || y == 0 || y == opts.HEIGHT

# --

S.snake_head = snake_head = (sn) -> U.first sn.segs
S.snake_body = snake_body = (sn) -> U.rest  sn.segs

S.snake_change_dir = snake_change_dir = (sn, d) ->
  mk_snake d, sn.segs

# --

S.random = random = (min, max) ->
  Math.round(Math.random() * (max - min) + min)

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
