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

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final _sfx = AudioPlayer();
  final _rng = Random();
  Offset _origin = const Offset(0, 0);
  Offset _aim = const Offset(0, -1);
  double _aimAngle = -pi / 2;
  Offset? _laserPos;
  Offset _laserVel = Offset.zero;
  List<Offset> _trail = [];
  Offset _target = const Offset(0, 0);
  int _bouncesLeft = 0;
  int _maxBounces = 3;
  int _level = 1;
  int _score = 0;
  bool _firing = false;
  Duration _last = Duration.zero;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  void _setup() {
    final s = MediaQuery.of(context).size;
    _size = s;
    _origin = Offset(s.width / 2, s.height - 120);
    _target = Offset(60 + _rng.nextDouble() * (s.width - 120),
        140 + _rng.nextDouble() * (s.height * 0.4));
    _maxBounces = 1 + _rng.nextInt(3) + (_level ~/ 4);
    _bouncesLeft = _maxBounces;
    _firing = false;
    _trail = [];
    _laserPos = null;
    setState(() {});
  }

  void _tick(Duration t) {
    final dt = (t - _last).inMicroseconds / 1e6;
    _last = t;
    if (dt > 0.1 || !_firing || _laserPos == null) return;
    setState(() {
      var p = _laserPos!;
      var v = _laserVel;
      var steps = 12;
      while (steps-- > 0 && _firing) {
        final stepDt = dt / 12;
        p = p + v * stepDt * 800;
        if (p.dx <= 8 || p.dx >= _size.width - 8) {
          if (_bouncesLeft <= 0) { _firing = false; _setup(); return; }
          v = Offset(-v.dx, v.dy); _bouncesLeft--; _sfx.play(AssetSource('sfx.wav'));
        }
        if (p.dy <= 8 || p.dy >= _size.height - 8) {
          if (_bouncesLeft <= 0) { _firing = false; _setup(); return; }
          v = Offset(v.dx, -v.dy); _bouncesLeft--; _sfx.play(AssetSource('sfx.wav'));
        }
        if ((p - _target).distance < 28) {
          _score++;
          _level++;
          _firing = false;
          _setup();
          return;
        }
        _trail.add(p);
        if (_trail.length > 220) _trail.removeAt(0);
      }
      _laserPos = p;
      _laserVel = v;
    });
  }

  void _onPan(DragUpdateDetails d) {
    if (_firing) return;
    final dx = d.localPosition.dx - _origin.dx;
    final dy = d.localPosition.dy - _origin.dy;
    setState(() {
      _aimAngle = atan2(dy, dx);
      _aim = Offset(cos(_aimAngle), sin(_aimAngle));
    });
  }

  void _fire() {
    if (_firing) return;
    setState(() {
      _firing = true;
      _laserPos = _origin;
      _laserVel = _aim;
      _trail = [_origin];
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sfx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: GestureDetector(
        onPanUpdate: _onPan,
        onTap: _fire,
        child: Stack(children: [
          CustomPaint(
            size: Size.infinite,
            painter: _Painter(
              origin: _origin, aim: _aim, target: _target,
              trail: _trail, firing: _firing,
            ),
          ),
          Positioned(
            top: 50, left: 0, right: 0,
            child: Column(children: [
              Text('LV $_level', style: const TextStyle(color: Colors.white60)),
              Text('$_score',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold,
                      color: Color(0xFF39FF14))),
              Text('bounces left $_bouncesLeft / $_maxBounces',
                  style: const TextStyle(color: Colors.white54)),
            ]),
          ),
          const Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: Text('drag to aim · tap to fire',
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
  final bool firing;
  _Painter({required this.origin, required this.aim, required this.target,
            required this.trail, required this.firing});
  @override
  void paint(Canvas c, Size s) {
    c.drawCircle(target, 28,
        Paint()..color = const Color(0xFFFF3B3B).withOpacity(0.3));
    c.drawCircle(target, 16, Paint()..color = const Color(0xFFFF3B3B));
    c.drawCircle(origin, 16, Paint()..color = const Color(0xFF39FF14));
    if (!firing) {
      final tip = origin + aim * 90;
      final p = Paint()
        ..color = const Color(0xFF39FF14).withOpacity(0.5)
        ..strokeWidth = 3;
      c.drawLine(origin, tip, p);
    }
    if (trail.isNotEmpty) {
      final p = Paint()
        ..color = const Color(0xFF39FF14)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (int i = 1; i < trail.length; i++) {
        c.drawLine(trail[i-1], trail[i], p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
