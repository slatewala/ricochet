import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const RicochetApp());

class RicochetApp extends StatelessWidget {
  const RicochetApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ricochet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const GamePage(),
      );
}

enum Phase { aiming, firing, hit, miss }

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final _sfx = AudioPlayer();
  final _rng = Random();
  Offset _origin = Offset.zero;
  Offset _aim = const Offset(0.7, -0.7);
  Offset _laserPos = Offset.zero;
  Offset _laserVel = Offset.zero;
  final List<Offset> _trail = [];
  Offset _target = Offset.zero;
  int _bouncesLeft = 0;
  int _maxBounces = 3;
  int _level = 1;
  int _score = 0;
  Phase _phase = Phase.aiming;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  double _resetIn = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup(true));
  }

  void _setup(bool full) {
    final s = MediaQuery.of(context).size;
    _size = s;
    _origin = Offset(s.width / 2, s.height - 140);
    if (full) { _level = 1; _score = 0; }
    _target = Offset(60 + _rng.nextDouble() * (s.width - 120),
        140 + _rng.nextDouble() * (s.height * 0.35));
    _maxBounces = 1 + _rng.nextInt(3) + (_level ~/ 5);
    _bouncesLeft = _maxBounces;
    _aim = const Offset(0.7, -0.7) / sqrt(2 * 0.49);
    final ang = -pi/2 + (_rng.nextDouble() - 0.5) * 0.8;
    _aim = Offset(cos(ang), sin(ang));
    _trail.clear();
    _phase = Phase.aiming;
    _resetIn = 0;
    setState(() {});
  }

  void _tick(Duration t) {
    final dt = (t - _last).inMicroseconds / 1e6;
    _last = t;
    if (dt > 0.1 || _size == Size.zero) return;
    setState(() {
      if (_phase == Phase.firing) {
        var p = _laserPos;
        var v = _laserVel;
        const speed = 600.0;
        var steps = 8;
        while (steps-- > 0 && _phase == Phase.firing) {
          final stepDt = dt / 8;
          p = p + v * stepDt * speed;
          if (p.dx <= 6) { p = Offset(6, p.dy); v = Offset(-v.dx, v.dy); _bounce(); }
          else if (p.dx >= _size.width - 6) { p = Offset(_size.width - 6, p.dy); v = Offset(-v.dx, v.dy); _bounce(); }
          if (p.dy <= 6) { p = Offset(p.dx, 6); v = Offset(v.dx, -v.dy); _bounce(); }
          else if (p.dy >= _size.height - 6) { p = Offset(p.dx, _size.height - 6); v = Offset(v.dx, -v.dy); _bounce(); }
          if ((p - _target).distance < 30) {
            _trail.add(p);
            _phase = Phase.hit;
            _resetIn = 0.6;
            _score++;
            _level++;
            _sfx.play(AssetSource('sfx.wav'));
            break;
          }
          if (_phase != Phase.firing) break;
          _trail.add(p);
        }
        if (_trail.length > 600) _trail.removeRange(0, _trail.length - 600);
        _laserPos = p;
        _laserVel = v;
      } else if (_phase == Phase.hit || _phase == Phase.miss) {
        _resetIn -= dt;
        if (_resetIn <= 0) _setup(false);
      }
    });
  }

  void _bounce() {
    if (_bouncesLeft <= 0) {
      _phase = Phase.miss;
      _resetIn = 0.9;
      return;
    }
    _bouncesLeft--;
    _sfx.play(AssetSource('sfx.wav'));
  }

  void _aimAt(Offset p) {
    if (_phase != Phase.aiming) return;
    final dx = p.dx - _origin.dx;
    final dy = p.dy - _origin.dy;
    final len = sqrt(dx*dx + dy*dy);
    if (len < 1) return;
    setState(() => _aim = Offset(dx / len, dy / len));
  }

  void _fire() {
    if (_phase != Phase.aiming) {
      if (_phase == Phase.miss || _phase == Phase.hit) _setup(false);
      return;
    }
    setState(() {
      _phase = Phase.firing;
      _laserPos = _origin;
      _laserVel = _aim;
      _trail.clear();
      _trail.add(_origin);
    });
  }

  @override
  void dispose() { _ticker.dispose(); _sfx.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hudColor = _phase == Phase.miss ? const Color(0xFFFF3B3B)
                    : _phase == Phase.hit ? const Color(0xFF39FF14)
                    : Colors.white60;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          _aimAt(e.localPosition);
          // arm fire-on-up
        },
        onPointerMove: (e) => _aimAt(e.localPosition),
        onPointerUp: (e) {
          if (_phase == Phase.aiming) {
            _aimAt(e.localPosition);
            _fire();
          } else if (_phase == Phase.miss || _phase == Phase.hit) {
            _setup(false);
          }
        },
        child: Stack(children: [
          CustomPaint(
            size: Size.infinite,
            painter: _Painter(
              origin: _origin, aim: _aim, target: _target,
              trail: _trail, phase: _phase,
            ),
          ),
          Positioned(
            top: 50, left: 0, right: 0,
            child: Column(children: [
              Text('LV $_level', style: const TextStyle(color: Colors.white60)),
              Text('$_score',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold,
                      color: Color(0xFF39FF14))),
              Text('bounces $_bouncesLeft / $_maxBounces',
                  style: TextStyle(color: hudColor)),
              if (_phase == Phase.miss)
                const Padding(padding: EdgeInsets.only(top: 8),
                    child: Text('MISS', style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 22))),
              if (_phase == Phase.hit)
                const Padding(padding: EdgeInsets.only(top: 8),
                    child: Text('HIT', style: TextStyle(color: Color(0xFF39FF14), fontSize: 22))),
            ]),
          ),
          const Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: Text('touch to aim · release to fire',
                  style: TextStyle(color: Colors.white38)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final Offset origin, aim, target;
  final List<Offset> trail;
  final Phase phase;
  _Painter({required this.origin, required this.aim, required this.target,
            required this.trail, required this.phase});
  @override
  void paint(Canvas c, Size s) {
    // target
    c.drawCircle(target, 30,
        Paint()..color = const Color(0xFFFF3B3B).withOpacity(0.25));
    c.drawCircle(target, 18, Paint()..color = const Color(0xFFFF3B3B));
    c.drawCircle(target, 8, Paint()..color = Colors.white);
    // origin / cannon
    c.drawCircle(origin, 18, Paint()..color = const Color(0xFF39FF14));
    c.drawCircle(origin, 8, Paint()..color = Colors.black);
    // aim guide always visible during aiming
    if (phase == Phase.aiming) {
      final tipShort = origin + aim * 60;
      final tipLong = origin + aim * 220;
      c.drawLine(origin, tipLong,
          Paint()..color = const Color(0xFF39FF14).withOpacity(0.25)..strokeWidth = 2);
      c.drawLine(origin, tipShort,
          Paint()..color = const Color(0xFF39FF14)..strokeWidth = 4);
    }
    // trail
    if (trail.length > 1) {
      final p = Paint()
        ..color = const Color(0xFF39FF14)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (int i = 1; i < trail.length; i++) {
        c.drawLine(trail[i-1], trail[i], p);
      }
      // glowing head
      c.drawCircle(trail.last, 8, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
