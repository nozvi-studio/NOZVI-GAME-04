import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/cue_model.dart';
import '../models/table_skin_model.dart';

/// Hiệu ứng va chạm sóng kích (Shockwave Ring) giữa 2 quả bi - GPU Accelerated
class _BallCollisionShockwave {
  final double cx;
  final double cy;
  final Offset center;
  final double maxRadius;
  final double maxLife;
  final double intensity;
  final List<_SparkSpeck> sparks;
  double age = 0.0;

  _BallCollisionShockwave({
    required Vector2 position,
    required this.maxRadius,
    required this.maxLife,
    required this.intensity,
    required this.sparks,
  })  : cx = position.x,
        cy = position.y,
        center = Offset(position.x, position.y);

  bool update(double dt) {
    age += dt;
    for (int i = 0; i < sparks.length; i++) {
      sparks[i].update(dt);
    }
    return age < maxLife;
  }

  void render(Canvas canvas, Paint ringPaint, Paint glowPaint, Paint corePaint, Paint sparkPaint) {
    final t = (age / maxLife).clamp(0.0, 1.0);
    // Ease out quartic cho sóng kích nảy bung tức thì
    final ease = 1.0 - math.pow(1.0 - t, 3.5).toDouble();
    final r = maxRadius * (0.2 + 0.8 * ease);
    final alpha = (1.0 - t) * intensity;

    if (alpha <= 0.001) return;

    // 1. Lớp quầng sáng nở mờ bên ngoài (Glow Halo) - 100% GPU, không dùng MaskFilter.blur
    final strokeW = (1.8 * (1.0 - t * 0.65)).clamp(0.4, 2.0);
    glowPaint
      ..color = Color.fromRGBO(200, 240, 255, (0.35 * alpha).clamp(0.0, 1.0))
      ..strokeWidth = strokeW * 2.2;
    canvas.drawCircle(center, r, glowPaint);

    // 2. Vòng sóng kích lõi phát quang trắng xanh tinh tế
    ringPaint
      ..color = Color.fromRGBO(240, 250, 255, (0.85 * alpha).clamp(0.0, 1.0))
      ..strokeWidth = strokeW;
    canvas.drawCircle(center, r, ringPaint);

    // 3. Điểm chớp sáng tâm va chạm (Core Flash) siêu ngắn (trong 35% đầu thời gian)
    if (t < 0.35) {
      final coreFlashT = 1.0 - (t / 0.35);
      corePaint.color = Color.fromRGBO(255, 255, 255, (0.95 * coreFlashT * intensity).clamp(0.0, 1.0));
      canvas.drawCircle(center, maxRadius * 0.28 * coreFlashT, corePaint);
    }

    // 4. Các tia hạt vi lượng văng ra dọc theo tiếp tuyến va chạm
    for (int i = 0; i < sparks.length; i++) {
      sparks[i].render(canvas, alpha, sparkPaint);
    }
  }
}

/// Tia hạt vi lượng tiếp xúc (Micro Spark) - Zero heap allocations
class _SparkSpeck {
  double px;
  double py;
  double vx;
  double vy;
  final double length;
  final Color color;

  _SparkSpeck({
    required double startX,
    required double startY,
    required double velX,
    required double velY,
    required this.length,
    required this.color,
  })  : px = startX,
        py = startY,
        vx = velX,
        vy = velY;

  void update(double dt) {
    px += vx * dt;
    py += vy * dt;
    final friction = math.pow(0.2, dt).toDouble();
    vx *= friction;
    vy *= friction;
  }

  void render(Canvas canvas, double parentAlpha, Paint sparkPaint) {
    if (parentAlpha <= 0.01) return;
    final speed2 = vx * vx + vy * vy;
    if (speed2 < 0.0001) return;

    final invSpeed = 1.0 / math.sqrt(speed2);
    final nx = vx * invSpeed;
    final ny = vy * invSpeed;
    final halfLen = length * 0.5;

    sparkPaint
      ..color = color.withValues(alpha: (parentAlpha * 0.85).clamp(0.0, 1.0))
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(px, py),
      Offset(px - nx * halfLen, py - ny * halfLen),
      sparkPaint,
    );
  }
}

/// Bụi lơ gậy (Chalk Dust Puff) khi đầu cơ tiếp xúc bi cái - GPU Accelerated Dual-Circle Halo
class _ChalkDustParticle {
  double px;
  double py;
  double vx;
  double vy;
  final double radius;
  final double maxLife;
  final Color color;
  double age = 0.0;

  _ChalkDustParticle({
    required double startX,
    required double startY,
    required double velX,
    required double velY,
    required this.radius,
    required this.maxLife,
    required this.color,
  })  : px = startX,
        py = startY,
        vx = velX,
        vy = velY;

  bool update(double dt) {
    age += dt;
    px += vx * dt;
    py += vy * dt;
    final drag = math.pow(0.15, dt).toDouble();
    vx *= drag;
    vy *= drag;
    return age < maxLife;
  }

  void render(Canvas canvas, Paint fillPaint) {
    final t = (age / maxLife).clamp(0.0, 1.0);
    final alpha = (1.0 - t * t).clamp(0.0, 1.0);
    if (alpha <= 0.005) return;

    final curRadius = radius * (1.0 + 0.8 * t);
    final offset = Offset(px, py);

    // Lớp quầng bụi tỏa rộng mờ ảo
    fillPaint.color = color.withValues(alpha: (alpha * 0.28).clamp(0.0, 1.0));
    canvas.drawCircle(offset, curRadius * 1.5, fillPaint);

    // Lớp lõi bụi phấn đậm đà
    fillPaint.color = color.withValues(alpha: (alpha * 0.70).clamp(0.0, 1.0));
    canvas.drawCircle(offset, curRadius * 0.75, fillPaint);
  }
}

/// Gợn ép đàn hồi băng cao su (Cushion Impact Ripple) khi bi đập vào băng - Thiết kế theo Concept Anime
class _RailImpactRipple {
  final double cx;
  final double cy;
  final double tx;
  final double ty;
  final double nx;
  final double ny;
  final double maxHalfLength;
  final double maxLife;
  final double intensity;
  final TableAnimeConcept concept;
  final Color? accentColor;
  final List<_SparkSpeck> railSparks;
  double age = 0.0;

  _RailImpactRipple({
    required Vector2 position,
    required Vector2 tangent,
    required this.maxHalfLength,
    required this.maxLife,
    required this.intensity,
    this.concept = TableAnimeConcept.classic,
    this.accentColor,
    this.railSparks = const [],
  })  : cx = position.x,
        cy = position.y,
        tx = tangent.x,
        ty = tangent.y,
        nx = -tangent.y,
        ny = tangent.x;

  bool update(double dt) {
    age += dt;
    for (int i = 0; i < railSparks.length; i++) {
      railSparks[i].update(dt);
    }
    return age < maxLife;
  }

  void render(Canvas canvas, Paint ripplePaint, Paint glowPaint, [Paint? sparkPaint]) {
    final t = (age / maxLife).clamp(0.0, 1.0);
    final ease = 1.0 - math.pow(1.0 - t, 2.5).toDouble();
    final halfLen = maxHalfLength * (0.3 + 0.7 * ease);
    final alpha = (1.0 - t) * intensity;
    if (alpha <= 0.01) return;

    final x1 = cx - tx * halfLen;
    final y1 = cy - ty * halfLen;
    final x2 = cx + tx * halfLen;
    final y2 = cy + ty * halfLen;
    final p1 = Offset(x1, y1);
    final p2 = Offset(x2, y2);

    final strokeW = (2.4 * (1.0 - t)).clamp(0.6, 3.0);

    // Bảng màu và hiệu ứng đồ họa riêng biệt theo Concept Anime của bàn đấu
    Color glowColor;
    Color coreColor;

    switch (concept) {
      case TableAnimeConcept.sakuraZen:
        glowColor = const Color(0xFFF48FB1); // Cánh hoa anh đào Sakura hồng phấn
        coreColor = const Color(0xFFFFF0F5);
        break;
      case TableAnimeConcept.cyberTokyo:
        glowColor = const Color(0xFF00E5FF); // Cyber neon cyan
        coreColor = const Color(0xFFE040FB); // Cyber magenta
        break;
      case TableAnimeConcept.dragonLava:
        glowColor = const Color(0xFFFF6D00); // Lửa dung nham rực cháy
        coreColor = const Color(0xFFFFD600);
        break;
      case TableAnimeConcept.arcaneGrimoire:
        glowColor = const Color(0xFF7C4DFF); // Vòng tròn ma pháp huyền bí
        coreColor = const Color(0xFFE040FB);
        break;
      case TableAnimeConcept.shadowVoid:
        glowColor = const Color(0xFF6A1B9A); // Hư không bóng tối
        coreColor = const Color(0xFFBA68C8);
        break;
      case TableAnimeConcept.mechaEva:
        glowColor = const Color(0xFF76FF03); // Lá chắn AT-Field Mecha xanh neon
        coreColor = const Color(0xFFFF9100);
        break;
      case TableAnimeConcept.classic:
        glowColor = accentColor ?? const Color(0xFFB4FFDC);
        coreColor = const Color(0xFFDCFFF0);
        break;
    }

    // 1. Quầng nảy mờ lan tỏa đàn hồi cao su mang màu Concept Anime
    glowPaint
      ..color = glowColor.withValues(alpha: (0.42 * alpha).clamp(0.0, 1.0))
      ..strokeWidth = strokeW * 2.8;
    canvas.drawLine(p1, p2, glowPaint);

    // 2. Đường tiếp xúc nảy băng sắc nét
    ripplePaint
      ..color = coreColor.withValues(alpha: (0.90 * alpha).clamp(0.0, 1.0))
      ..strokeWidth = strokeW;
    canvas.drawLine(p1, p2, ripplePaint);

    // 3. Đồ họa vi mô Concept Anime bổ sung dọc thân băng
    if (concept == TableAnimeConcept.cyberTokyo) {
      // Vạch dữ liệu số (Digital Circuit Glitch) nhấp nháy dọc theo mép băng
      final tickPaint = glowPaint
        ..color = coreColor.withValues(alpha: (0.85 * alpha).clamp(0.0, 1.0))
        ..strokeWidth = 1.2;
      for (double d = -halfLen * 0.7; d <= halfLen * 0.7; d += halfLen * 0.35) {
        final bx = cx + tx * d;
        final by = cy + ty * d;
        canvas.drawLine(
          Offset(bx, by),
          Offset(bx + nx * 5.0, by + ny * 5.0),
          tickPaint,
        );
      }
    } else if (concept == TableAnimeConcept.mechaEva) {
      // Dấu chevron năng lượng lục giác AT-Field nhô ra từ băng
      final mechaPaint = glowPaint
        ..color = glowColor.withValues(alpha: (0.80 * alpha).clamp(0.0, 1.0))
        ..strokeWidth = 1.4;
      final midPoint = Offset(cx, cy);
      final tipPoint = Offset(cx + nx * (6.0 * (1.0 - t)), cy + ny * (6.0 * (1.0 - t)));
      canvas.drawLine(p1, tipPoint, mechaPaint);
      canvas.drawLine(p2, tipPoint, mechaPaint);
      canvas.drawLine(midPoint, tipPoint, mechaPaint);
    } else if (concept == TableAnimeConcept.sakuraZen) {
      // 2 chấm cánh hoa Sakura hồng nở tung ở 2 đầu sóng nảy băng
      final petalPaint = glowPaint
        ..color = glowColor.withValues(alpha: (0.75 * alpha).clamp(0.0, 1.0))
        ..strokeWidth = 1.0;
      canvas.drawCircle(p1, 2.5 * (1.0 - t), petalPaint);
      canvas.drawCircle(p2, 2.5 * (1.0 - t), petalPaint);
    }

    // 4. Các tia hạt vi lượng tóe ra từ mép băng
    if (sparkPaint != null && railSparks.isNotEmpty) {
      for (int i = 0; i < railSparks.length; i++) {
        railSparks[i].render(canvas, alpha, sparkPaint);
      }
    }
  }
}

/// Điểm vệt chuyển động có thời gian sống tự tiêu hủy - Pre-cached Offset
class _TrailPoint {
  final double x;
  final double y;
  final Offset offset;
  double age = 0.0;
  static const double maxAge = 0.11; // 110ms: vệt mờ sắc nét, biến mất tức thì không để lại cặn

  _TrailPoint(this.x, this.y) : offset = Offset(x, y);

  bool update(double dt) {
    age += dt;
    return age < maxAge;
  }

  double get alphaMultiplier => (1.0 - (age / maxAge)).clamp(0.0, 1.0);
}

/// Lịch sử vệt chuyển động của quả bi ở tốc độ cao
class _BallMotionTrailHistory {
  final List<_TrailPoint> points = [];
  double idleTime = 0.0;

  void addPosition(double x, double y) {
    idleTime = 0.0;
    if (points.isNotEmpty) {
      final dx = points.first.x - x;
      final dy = points.first.y - y;
      if (dx * dx + dy * dy < 9.0) {
        return; // Không thêm điểm trùng khi bi di chuyển cực nhỏ (< 3px)
      }
    }
    points.insert(0, _TrailPoint(x, y));
    if (points.length > 4) {
      points.removeLast();
    }
  }

  bool update(double dt) {
    idleTime += dt;
    // Nếu bi không cập nhật điểm mới (chậm lại, rơi vào lỗ hoặc đứng yên) -> làm mờ cực nhanh
    final factor = idleTime > 0.03 ? 4.0 : 1.0;
    for (int i = 0; i < points.length; i++) {
      points[i].age += dt * factor;
    }
    points.removeWhere((p) => p.age >= _TrailPoint.maxAge);
    return points.isNotEmpty;
  }

  void clear() {
    points.clear();
    idleTime = 0.0;
  }
}

/// Hiệu ứng xoáy tụ hút vào lỗ (Pocket Drop Vortex) khi bi lọt lỗ - Dual Ring GPU
class _PocketDropVortex {
  static const double maxLife = 0.38;
  final Offset center;
  final double radius;
  double age = 0.0;

  _PocketDropVortex({
    required Vector2 position,
    required this.radius,
  }) : center = Offset(position.x, position.y);

  bool update(double dt) {
    age += dt;
    return age < maxLife;
  }

  void render(Canvas canvas, Paint strokePaint, Paint glowPaint, Paint fillPaint) {
    final t = (age / maxLife).clamp(0.0, 1.0);
    final alpha = (1.0 - t * t).clamp(0.0, 1.0);
    if (alpha <= 0.01) return;

    // Vòng tụ sáng xoáy vào tâm lỗ mượt mà
    final shrink = 1.0 - math.pow(t, 1.8).toDouble() * 0.52;
    final curR = radius * shrink;
    final strokeW = (2.2 * (1.0 - t * 0.7)).clamp(0.5, 2.5);

    // 1. Quầng sáng xoáy vàng ánh kim (Glow Halo)
    glowPaint
      ..color = Color.fromRGBO(255, 230, 140, (0.28 * alpha).clamp(0.0, 1.0))
      ..strokeWidth = strokeW * 2.2;
    canvas.drawCircle(center, curR, glowPaint);

    // 2. Vành tụ xoáy vàng kim sắc nét
    strokePaint
      ..color = Color.fromRGBO(255, 225, 120, (0.75 * alpha).clamp(0.0, 1.0))
      ..strokeWidth = strokeW;
    canvas.drawCircle(center, curR, strokePaint);

    // 3. Vùng bóng sâu lòng lỗ tạo cảm giác bi rơi chìm vào họng lỗ
    fillPaint.color = Color.fromRGBO(5, 5, 5, (0.55 * alpha).clamp(0.0, 1.0));
    canvas.drawCircle(center, radius * 0.65 * (1.0 - t * 0.3), fillPaint);
  }
}

/// Xung chấn tiếp xúc đầu gậy cơ (Cue Tip Strike Pulse)
class _CueTipHitPulse {
  static const double maxLife = 0.14;
  final Offset center;
  final double maxRadius;
  final double intensity;
  double age = 0.0;

  _CueTipHitPulse({
    required Vector2 position,
    required this.maxRadius,
    required this.intensity,
  }) : center = Offset(position.x, position.y);

  bool update(double dt) {
    age += dt;
    return age < maxLife;
  }

  void render(Canvas canvas, Paint strokePaint, Paint glowPaint, Paint fillPaint) {
    final t = (age / maxLife).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * intensity;
    if (alpha <= 0.01) return;

    final r = maxRadius * math.sqrt(t);
    final strokeW = (1.8 * (1.0 - t)).clamp(0.5, 2.0);

    // 1. Quầng chấn động đầu cơ
    glowPaint
      ..color = Color.fromRGBO(220, 245, 255, (0.35 * alpha).clamp(0.0, 1.0))
      ..strokeWidth = strokeW * 2.0;
    canvas.drawCircle(center, r, glowPaint);

    // 2. Sóng tròn sắc nét
    strokePaint
      ..color = Color.fromRGBO(255, 255, 255, (0.90 * alpha).clamp(0.0, 1.0))
      ..strokeWidth = strokeW;
    canvas.drawCircle(center, r, strokePaint);

    // 3. Chớp tâm phát lực
    if (t < 0.4) {
      final coreAlpha = (1.0 - t / 0.4) * intensity;
      fillPaint.color = Color.fromRGBO(255, 255, 255, coreAlpha.clamp(0.0, 1.0));
      canvas.drawCircle(center, maxRadius * 0.3 * (1.0 - t / 0.4), fillPaint);
    }
  }
}

enum _AnimeParticleType { spark, petal, pixel, ember, star, shard }

/// Hạt hiệu ứng vi mô Anime (Anime VFX Particle) - Tối ưu GPU
class _AnimeVfxParticle {
  double px;
  double py;
  double vx;
  double vy;
  final double size;
  final Color color;
  final _AnimeParticleType type;
  final double maxLife;
  final double rotSpeed;
  double rotation = 0.0;
  double age = 0.0;

  _AnimeVfxParticle({
    required this.px,
    required this.py,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.type,
    required this.maxLife,
    this.rotSpeed = 0.0,
  });

  bool update(double dt) {
    age += dt;
    px += vx * dt;
    py += vy * dt;
    rotation += rotSpeed * dt;
    final drag = math.pow(0.20, dt).toDouble();
    vx *= drag;
    vy *= drag;
    return age < maxLife;
  }

  void render(Canvas canvas, double parentAlpha, Paint fillPaint, Paint strokePaint) {
    final t = (age / maxLife).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * parentAlpha;
    if (alpha <= 0.01) return;

    final curColor = color.withValues(alpha: alpha.clamp(0.0, 1.0));

    switch (type) {
      case _AnimeParticleType.petal:
        // Cánh hoa Sakura xoay tròn nhẹ nhàng trong gió
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(rotation);
        fillPaint.color = curColor;
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: size * 1.8, height: size * 0.9),
          fillPaint,
        );
        canvas.restore();
        break;

      case _AnimeParticleType.pixel:
        // Điểm ảnh số Cyberpunk Glitch hình vuông
        fillPaint.color = curColor;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(px, py), width: size, height: size),
          fillPaint,
        );
        break;

      case _AnimeParticleType.ember:
        // Đốm lửa dung nham rực cháy
        fillPaint.color = curColor;
        canvas.drawCircle(Offset(px, py), size * (1.0 - t * 0.5), fillPaint);
        break;

      case _AnimeParticleType.star:
        // Ngôi sao ma thuật lấp lánh (4-Point Star)
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(rotation);
        strokePaint
          ..color = curColor
          ..strokeWidth = 1.0;
        final half = size * 0.8;
        canvas.drawLine(Offset(-half, 0), Offset(half, 0), strokePaint);
        canvas.drawLine(Offset(0, -half), Offset(0, half), strokePaint);
        canvas.restore();
        break;

      case _AnimeParticleType.shard:
        // Mảnh băng pha lê vỡ vụn
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(rotation);
        strokePaint
          ..color = curColor
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(-size * 0.5, -size * 0.3), Offset(size * 0.5, size * 0.3), strokePaint);
        canvas.restore();
        break;

      case _AnimeParticleType.spark:
        final speed2 = vx * vx + vy * vy;
        if (speed2 < 0.0001) return;
        final invSpeed = 1.0 / math.sqrt(speed2);
        strokePaint
          ..color = curColor
          ..strokeWidth = 1.0;
        canvas.drawLine(
          Offset(px, py),
          Offset(px - vx * invSpeed * size, py - vy * invSpeed * size),
          strokePaint,
        );
        break;
    }
  }
}

/// Hiệu ứng chạm bi cái độc quyền theo Concept Anime của từng cây cơ (Cue Anime Contact VFX)
class _AnimeCueContactEffect {
  final Offset center;
  final CueAnimeConcept concept;
  final Vector2 shotDirection;
  final double intensity;
  final double maxRadius;
  final double maxLife;
  final List<_AnimeVfxParticle> particles;
  double age = 0.0;

  _AnimeCueContactEffect({
    required Vector2 position,
    required this.concept,
    required this.shotDirection,
    required this.intensity,
    required this.maxRadius,
    required this.maxLife,
    required this.particles,
  }) : center = Offset(position.x, position.y);

  bool update(double dt) {
    age += dt;
    for (int i = 0; i < particles.length; i++) {
      particles[i].update(dt);
    }
    return age < maxLife;
  }

  void render(Canvas canvas, Paint strokePaint, Paint glowPaint, Paint fillPaint) {
    final t = (age / maxLife).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * intensity;
    if (alpha <= 0.005) return;

    final dirAngle = math.atan2(shotDirection.y, shotDirection.x);

    // 1. Vẽ các biểu tượng độc quyền theo từng Anime Concept
    canvas.save();
    canvas.translate(center.dx, center.dy);

    switch (concept) {
      case CueAnimeConcept.katanaSamurai:
        // Nhát chém trăng khuyết Katana (Crescent Blade Slash Arc) vuông góc với hướng bắn
        final slashAngle = dirAngle + math.pi / 2;
        canvas.rotate(slashAngle);
        final slashR = maxRadius * (0.4 + 1.2 * math.sqrt(t));

        // Lớp quầng chém đỏ huyết kiếm
        glowPaint
          ..color = Color.fromRGBO(255, 23, 68, (0.75 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 3.2 * (1.0 - t);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: slashR),
          -math.pi * 0.45,
          math.pi * 0.90,
          false,
          glowPaint,
        );

        // Lõi lưỡi kiếm trắng sắc lẹm
        strokePaint
          ..color = Color.fromRGBO(255, 255, 255, (0.95 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 1.4 * (1.0 - t);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: slashR),
          -math.pi * 0.45,
          math.pi * 0.90,
          false,
          strokePaint,
        );

        // Chớp kiếm lóe sáng (Cross flash) ở thời điểm va chạm ban đầu
        if (t < 0.35) {
          final flashT = 1.0 - (t / 0.35);
          final glintLen = maxRadius * 0.9 * flashT;
          strokePaint
            ..color = Color.fromRGBO(255, 255, 255, (0.90 * flashT).clamp(0.0, 1.0))
            ..strokeWidth = 1.0;
          canvas.drawLine(Offset(-glintLen, 0), Offset(glintLen, 0), strokePaint);
          canvas.drawLine(Offset(0, -glintLen * 0.6), Offset(0, glintLen * 0.6), strokePaint);
        }
        break;

      case CueAnimeConcept.cyberNeo:
        // Vòng tròn lưới kỹ thuật số Cyberpunk & tâm ngắm Hologram
        canvas.rotate(dirAngle);
        final cyberR = maxRadius * (0.3 + 0.9 * t);

        // Vành xung chấn Cyber neon cyan
        glowPaint
          ..color = Color.fromRGBO(0, 229, 255, (0.80 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 2.4 * (1.0 - t);
        canvas.drawCircle(Offset.zero, cyberR, glowPaint);

        strokePaint
          ..color = Color.fromRGBO(224, 64, 251, (0.90 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 1.0;
        // Khung ngoặc vuông ngắm điện tử (Glitch Reticle)
        final bSize = cyberR * 0.7;
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: bSize, height: bSize), strokePaint);
        break;

      case CueAnimeConcept.dragonFlame:
        // Cú nổ lửa Hỏa Long bùng nổ (Draconic Flame Shockwave)
        final flameR = maxRadius * (0.4 + 1.1 * math.pow(t, 0.7));
        glowPaint
          ..color = Color.fromRGBO(255, 109, 0, (0.85 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 3.6 * (1.0 - t);
        canvas.drawCircle(Offset.zero, flameR, glowPaint);

        strokePaint
          ..color = Color.fromRGBO(255, 214, 0, (0.95 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 1.6 * (1.0 - t);
        canvas.drawCircle(Offset.zero, flameR * 0.75, strokePaint);
        break;

      case CueAnimeConcept.arcaneMagic:
        // Trận đồ ma pháp xoay tròn (Rotating Arcane Octagram)
        canvas.rotate(t * 2.8);
        final magicR = maxRadius * (0.35 + 0.9 * t);

        glowPaint
          ..color = Color.fromRGBO(124, 77, 255, (0.85 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 2.0 * (1.0 - t);
        canvas.drawCircle(Offset.zero, magicR, glowPaint);

        // Vẽ 2 hình vuông lồng nhau thành hình bát giác ma thuật
        strokePaint
          ..color = Color.fromRGBO(224, 64, 251, (0.90 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 1.0;
        final s1 = magicR * 0.7;
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s1, height: s1), strokePaint);
        canvas.save();
        canvas.rotate(math.pi / 4);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s1, height: s1), strokePaint);
        canvas.restore();
        break;

      case CueAnimeConcept.shadowVoid:
        // Vòng xoáy sụp đổ Hư Không (Void Singularity Pulse)
        final voidR = maxRadius * (0.3 + 0.9 * (1.0 - math.pow(1.0 - t, 2.0)));
        glowPaint
          ..color = Color.fromRGBO(106, 27, 154, (0.90 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 3.0 * (1.0 - t);
        canvas.drawCircle(Offset.zero, voidR, glowPaint);

        fillPaint.color = Color.fromRGBO(10, 5, 20, (0.75 * alpha).clamp(0.0, 1.0));
        canvas.drawCircle(Offset.zero, voidR * 0.45 * (1.0 - t * 0.5), fillPaint);
        break;

      case CueAnimeConcept.mechaGundam:
        // Lá chắn năng lượng lục giác AT-Field vỡ tung
        canvas.rotate(dirAngle);
        final mechaR = maxRadius * (0.35 + 0.95 * t);
        glowPaint
          ..color = Color.fromRGBO(118, 255, 3, (0.85 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 2.2 * (1.0 - t);

        // Vẽ hình lục giác năng lượng
        final hexPath = Path();
        for (int i = 0; i < 6; i++) {
          final ang = i * math.pi / 3;
          final hx = math.cos(ang) * mechaR;
          final hy = math.sin(ang) * mechaR;
          if (i == 0) {
            hexPath.moveTo(hx, hy);
          } else {
            hexPath.lineTo(hx, hy);
          }
        }
        hexPath.close();
        canvas.drawPath(hexPath, glowPaint);
        break;

      case CueAnimeConcept.sakuraZen:
        // Hoa anh đào 5 cánh nở rộ phát quang
        canvas.rotate(t * 1.5);
        final flowerR = maxRadius * (0.3 + 0.85 * t);
        glowPaint
          ..color = Color.fromRGBO(244, 143, 177, (0.85 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 2.0 * (1.0 - t);

        for (int i = 0; i < 5; i++) {
          final ang = i * (math.pi * 2 / 5);
          final px = math.cos(ang) * flowerR * 0.6;
          final py = math.sin(ang) * flowerR * 0.6;
          canvas.drawCircle(Offset(px, py), flowerR * 0.38, glowPaint);
        }
        break;

      case CueAnimeConcept.frostCryo:
        // Hoa tuyết băng giá sắc nhọn bung tỏa
        canvas.rotate(dirAngle);
        final iceR = maxRadius * (0.35 + 0.9 * t);
        glowPaint
          ..color = Color.fromRGBO(128, 216, 255, (0.85 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 2.0 * (1.0 - t);
        for (int i = 0; i < 6; i++) {
          final ang = i * math.pi / 3;
          final ix = math.cos(ang) * iceR;
          final iy = math.sin(ang) * iceR;
          canvas.drawLine(Offset.zero, Offset(ix, iy), glowPaint);
        }
        break;

      case CueAnimeConcept.classic:
        // Sóng tròn cổ điển thanh lịch
        final defR = maxRadius * math.sqrt(t);
        glowPaint
          ..color = Color.fromRGBO(255, 255, 255, (0.80 * alpha).clamp(0.0, 1.0))
          ..strokeWidth = 1.8 * (1.0 - t);
        canvas.drawCircle(Offset.zero, defR, glowPaint);
        break;
    }
    canvas.restore();

    // 2. Vẽ tất cả các hạt vi lượng Anime
    for (int i = 0; i < particles.length; i++) {
      particles[i].render(canvas, alpha, fillPaint, strokePaint);
    }
  }
}

/// Component quản lý toàn bộ hiệu ứng vật lý thị giác (VFX) đỉnh cao của bàn bida:
/// 1. Sóng kích va chạm & chớp tâm nảy bi
/// 2. Bụi lơ gậy cơ tán xạ khi phát lực
/// 3. Xung chấn tiếp xúc đầu gậy cơ & Hiệu ứng Anime Concept riêng cho từng cây cơ
/// 4. Gợn sóng đàn hồi băng cao su theo Anime Concept của bàn đấu
/// 5. Vệt mờ tốc độ cao chân thực
/// 6. Xoáy hút chìm bi vào lỗ
///
/// Tối ưu hóa 100% phần cứng GPU:
/// - Loại bỏ hoàn toàn CPU Skia MaskFilter.blur gây khựng giật khung hình
/// - Tái sử dụng các Paint tĩnh dùng chung, triệt tiêu cấp phát heap và Garbage Collection
/// - Cắt giảm sớm (Fast Early Return) khi bàn đứng yên
class BilliardVfxComponent extends Component {
  final List<_BallCollisionShockwave> _shockwaves = [];
  final List<_ChalkDustParticle> _chalkPuffs = [];
  final List<_RailImpactRipple> _railRipples = [];
  final List<_PocketDropVortex> _pocketVortices = [];
  final List<_CueTipHitPulse> _cueHitPulses = [];
  final List<_AnimeCueContactEffect> _animeCueContacts = [];
  final Map<int, _BallMotionTrailHistory> _motionTrails = {};

  final math.Random _random = math.Random();

  // Reusable static Paint instances - Triệt tiêu GC churn trong render loop
  static final Paint _sharedStrokePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _sharedGlowPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _sharedFillPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;

  static final Paint _sharedSparkPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _sharedTrailCorePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _sharedTrailGlowPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  BilliardVfxComponent() {
    priority = 5; // Hiển thị phía trên mặt bàn và bi
  }

  /// Kích hoạt hiệu ứng va chạm giữa 2 bi bida
  void addBallCollision(Vector2 contactPoint, double relativeSpeed, {double ballRadius = 12.0}) {
    if (relativeSpeed < 32.0) return;

    // Giới hạn số lượng sóng kích cùng lúc tối đa 8 để giữ khung hình ổn định khi phá bi mạnh
    if (_shockwaves.length >= 8) {
      _shockwaves.removeAt(0);
    }

    // Chuẩn hóa cường độ theo vận tốc va chạm
    final intensity = (relativeSpeed / 480.0).clamp(0.25, 1.0);
    final maxRadius = (ballRadius * 0.75 + ballRadius * 1.35 * intensity).clamp(8.0, 32.0);
    final maxLife = 0.16 + 0.08 * intensity;

    // Sinh các tia hạt tiếp xúc nếu va chạm mạnh
    final sparks = <_SparkSpeck>[];
    if (relativeSpeed > 220.0) {
      final count = (2 + (intensity * 4).round()).clamp(2, 6);
      for (int i = 0; i < count; i++) {
        final angle = _random.nextDouble() * 2 * math.pi;
        final speed = 40.0 + _random.nextDouble() * 110.0 * intensity;
        sparks.add(
          _SparkSpeck(
            startX: contactPoint.x,
            startY: contactPoint.y,
            velX: math.cos(angle) * speed,
            velY: math.sin(angle) * speed,
            length: 3.5 + 3.5 * intensity,
            color: _random.nextBool()
                ? const Color(0xFFE0F7FA)
                : const Color(0xFFFFF9C4),
          ),
        );
      }
    }

    _shockwaves.add(
      _BallCollisionShockwave(
        position: contactPoint,
        maxRadius: maxRadius,
        maxLife: maxLife,
        intensity: intensity,
        sparks: sparks,
      ),
    );
  }

  /// Kích hoạt hiệu ứng chạm vào bi cái riêng biệt theo Concept Anime của từng cây cơ
  void addCueContactEffect({
    required CueModel cue,
    required Vector2 tipPos,
    required Vector2 shotDirection,
    required double shotSpeed,
    double ballRadius = 12.0,
  }) {
    final speedRatio = (shotSpeed / 1200.0).clamp(0.25, 1.0);
    final baseDir = -shotDirection.normalized();
    final baseAngle = math.atan2(baseDir.y, baseDir.x);

    if (_animeCueContacts.length >= 4) {
      _animeCueContacts.removeAt(0);
    }

    final particles = <_AnimeVfxParticle>[];
    final particleCount = (6 + (speedRatio * 8).round()).clamp(6, 14);

    _AnimeParticleType pType;
    List<Color> colorPool;

    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        pType = _AnimeParticleType.petal;
        colorPool = const [
          Color(0xFFFF1744), // Đỏ chém Katana
          Color(0xFFFFD54F), // Vàng kim Tsuba
          Color(0xFFF8BBD0), // Cánh hoa Sakura
          Color(0xFFFFFFFF),
        ];
        break;

      case CueAnimeConcept.cyberNeo:
        pType = _AnimeParticleType.pixel;
        colorPool = const [
          Color(0xFF00E5FF), // Cyber neon cyan
          Color(0xFFE040FB), // Neon magenta
          Color(0xFF76FF03), // Matrix lime
          Color(0xFFFFFFFF),
        ];
        break;

      case CueAnimeConcept.dragonFlame:
        pType = _AnimeParticleType.ember;
        colorPool = const [
          Color(0xFFFF6D00), // Cam lửa rực cháy
          Color(0xFFFFD600), // Vàng rực
          Color(0xFFFF3D00),
        ];
        break;

      case CueAnimeConcept.arcaneMagic:
        pType = _AnimeParticleType.star;
        colorPool = const [
          Color(0xFF7C4DFF), // Tím ma pháp
          Color(0xFFB388FF),
          Color(0xFFFFD54F),
        ];
        break;

      case CueAnimeConcept.shadowVoid:
        pType = _AnimeParticleType.ember;
        colorPool = const [
          Color(0xFF6A1B9A), // Tím bóng tối
          Color(0xFFBA68C8),
          Color(0xFF212121),
        ];
        break;

      case CueAnimeConcept.mechaGundam:
        pType = _AnimeParticleType.shard;
        colorPool = const [
          Color(0xFF76FF03), // Xanh lá neon EVA
          Color(0xFFFF9100), // Cam cảnh báo
          Color(0xFF00E5FF),
        ];
        break;

      case CueAnimeConcept.sakuraZen:
        pType = _AnimeParticleType.petal;
        colorPool = const [
          Color(0xFFF48FB1), // Hồng hoa anh đào
          Color(0xFFFF80AB),
          Color(0xFFFFF0F5),
        ];
        break;

      case CueAnimeConcept.frostCryo:
        pType = _AnimeParticleType.shard;
        colorPool = const [
          Color(0xFF80D8FF), // Băng giá pha lê
          Color(0xFF00B0FF),
          Color(0xFFFFFFFF),
        ];
        break;

      case CueAnimeConcept.classic:
        pType = _AnimeParticleType.spark;
        colorPool = const [
          Color(0xFF80DEEA),
          Color(0xFFFFFFFF),
          Color(0xFFFFF9C4),
        ];
        break;
    }

    for (int i = 0; i < particleCount; i++) {
      final spread = (_random.nextDouble() - 0.5) * 1.6;
      final angle = baseAngle + spread;
      final pSpeed = (40.0 + _random.nextDouble() * 105.0) * speedRatio;
      final vx = math.cos(angle) * pSpeed;
      final vy = math.sin(angle) * pSpeed;
      final color = colorPool[_random.nextInt(colorPool.length)];

      particles.add(
        _AnimeVfxParticle(
          px: tipPos.x,
          py: tipPos.y,
          vx: vx,
          vy: vy,
          size: 2.2 + _random.nextDouble() * 2.8 * speedRatio,
          color: color,
          type: pType,
          maxLife: 0.22 + _random.nextDouble() * 0.16,
          rotSpeed: (_random.nextDouble() - 0.5) * 12.0,
        ),
      );
    }

    _animeCueContacts.add(
      _AnimeCueContactEffect(
        position: tipPos,
        concept: cue.animeConcept,
        shotDirection: shotDirection,
        intensity: speedRatio,
        maxRadius: ballRadius * (1.1 + 0.6 * speedRatio),
        maxLife: 0.22 + 0.08 * speedRatio,
        particles: particles,
      ),
    );
  }

  /// Kích hoạt hiệu ứng bụi lơ gậy và xung chấn phát lực khi đầu gậy chạm bi
  void addCueChalkPuff({
    required Vector2 tipPos,
    required Vector2 shotDirection,
    required double shotSpeed,
    double ballRadius = 12.0,
  }) {
    final speedRatio = (shotSpeed / 1200.0).clamp(0.25, 1.0);
    final particleCount = (5 + (speedRatio * 6).round()).clamp(5, 11);

    if (_cueHitPulses.length >= 4) {
      _cueHitPulses.removeAt(0);
    }

    // Xung chấn đầu cơ tiếp xúc bi cái
    _cueHitPulses.add(
      _CueTipHitPulse(
        position: tipPos,
        maxRadius: ballRadius * 0.95,
        intensity: speedRatio,
      ),
    );

    // Bụi lơ phun ngược về hướng sau gậy với góc xòe hình nón
    final baseDir = -shotDirection.normalized();
    final baseAngle = math.atan2(baseDir.y, baseDir.x);

    // Dọn dẹp bụi cũ nếu đã tích lũy nhiều
    if (_chalkPuffs.length > 14) {
      _chalkPuffs.removeRange(0, _chalkPuffs.length - 14);
    }

    const chalkColors = [
      Color(0xFF80DEEA), // Màu phấn Master Chalk xanh ngọc
      Color(0xFFB2EBF2),
      Color(0xFFE0F7FA),
      Color(0xFFFFFFFF),
    ];

    for (int i = 0; i < particleCount; i++) {
      final spread = (_random.nextDouble() - 0.5) * 1.3;
      final angle = baseAngle + spread;
      final pSpeed = (35.0 + _random.nextDouble() * 85.0) * speedRatio;
      final vx = math.cos(angle) * pSpeed;
      final vy = math.sin(angle) * pSpeed;
      final color = chalkColors[_random.nextInt(chalkColors.length)];

      final offsetDist = 1.5 + _random.nextDouble() * 2.5;
      final dirNorm = math.sqrt(vx * vx + vy * vy);
      final offX = dirNorm > 0 ? (vx / dirNorm) * offsetDist : 0.0;
      final offY = dirNorm > 0 ? (vy / dirNorm) * offsetDist : 0.0;

      _chalkPuffs.add(
        _ChalkDustParticle(
          startX: tipPos.x + offX,
          startY: tipPos.y + offY,
          velX: vx,
          velY: vy,
          radius: 1.0 + _random.nextDouble() * 1.8 * speedRatio,
          maxLife: 0.20 + _random.nextDouble() * 0.14,
          color: color,
        ),
      );
    }
  }

  /// Kích hoạt hiệu ứng đàn hồi nảy băng cao su theo Anime Concept của bàn đấu
  void addRailImpact({
    required Vector2 ballPos,
    required Vector2 wallStart,
    required Vector2 wallEnd,
    required double speed,
    double ballRadius = 12.0,
    TableAnimeConcept tableConcept = TableAnimeConcept.classic,
    Color? railAccentColor,
  }) {
    if (speed < 55.0) return;
    final wallVec = wallEnd - wallStart;
    final wallLen = wallVec.length;
    if (wallLen < 0.001) return;

    final tangent = wallVec.normalized();
    // Chiếu vị trí bi lên đoạn thẳng băng
    final toBall = ballPos - wallStart;
    final proj = toBall.dot(tangent).clamp(0.0, wallLen);
    final contactPos = wallStart + tangent * proj;

    if (_railRipples.length >= 6) {
      _railRipples.removeAt(0);
    }

    final intensity = (speed / 450.0).clamp(0.2, 1.0);

    // Sinh các tia hạt tiếp xúc băng nếu va chạm mạnh
    final railSparks = <_SparkSpeck>[];
    if (speed > 160.0) {
      final sparkCount = (2 + (intensity * 3).round()).clamp(2, 5);
      final normal = Vector2(-tangent.y, tangent.x);
      for (int i = 0; i < sparkCount; i++) {
        final sparkAngle = math.atan2(normal.y, normal.x) + (_random.nextDouble() - 0.5) * 1.4;
        final spSpeed = 35.0 + _random.nextDouble() * 80.0 * intensity;
        Color sparkColor;
        switch (tableConcept) {
          case TableAnimeConcept.sakuraZen:
            sparkColor = const Color(0xFFF48FB1);
            break;
          case TableAnimeConcept.cyberTokyo:
            sparkColor = const Color(0xFF00E5FF);
            break;
          case TableAnimeConcept.dragonLava:
            sparkColor = const Color(0xFFFF9100);
            break;
          case TableAnimeConcept.arcaneGrimoire:
            sparkColor = const Color(0xFFB388FF);
            break;
          case TableAnimeConcept.shadowVoid:
            sparkColor = const Color(0xFFBA68C8);
            break;
          case TableAnimeConcept.mechaEva:
            sparkColor = const Color(0xFF76FF03);
            break;
          case TableAnimeConcept.classic:
            sparkColor = railAccentColor ?? const Color(0xFFFFF9C4);
            break;
        }

        railSparks.add(
          _SparkSpeck(
            startX: contactPos.x,
            startY: contactPos.y,
            velX: math.cos(sparkAngle) * spSpeed,
            velY: math.sin(sparkAngle) * spSpeed,
            length: 3.0 + 3.0 * intensity,
            color: sparkColor,
          ),
        );
      }
    }

    _railRipples.add(
      _RailImpactRipple(
        position: contactPos,
        tangent: tangent,
        maxHalfLength: ballRadius * (1.2 + 1.1 * intensity),
        maxLife: 0.16 + 0.07 * intensity,
        intensity: intensity,
        concept: tableConcept,
        accentColor: railAccentColor,
        railSparks: railSparks,
      ),
    );
  }

  /// Kích hoạt hiệu ứng hút rơi vào miệng lỗ
  void addPocketDrop(Vector2 pocketPos, [double pocketRadius = 24.0]) {
    // Chống kích hoạt đè liên tiếp nhiều xoáy trên cùng 1 lỗ trong thời gian ngắn (< 0.25s)
    for (int i = 0; i < _pocketVortices.length; i++) {
      final pv = _pocketVortices[i];
      final dx = pv.center.dx - pocketPos.x;
      final dy = pv.center.dy - pocketPos.y;
      if (dx * dx + dy * dy < (pocketRadius * 0.6) * (pocketRadius * 0.6) && pv.age < 0.25) {
        return;
      }
    }
    if (_pocketVortices.length >= 6) {
      _pocketVortices.removeAt(0);
    }
    _pocketVortices.add(
      _PocketDropVortex(
        position: pocketPos,
        radius: pocketRadius,
      ),
    );
  }

  /// Xóa ngay lập tức vệt chuyển động của 1 quả bi khi bi lọt lỗ hoặc dừng hẳn
  void clearBallTrail(int ballId) {
    _motionTrails[ballId]?.clear();
    _motionTrails.remove(ballId);
  }

  /// Cập nhật vệt chuyển động của quả bi
  void recordBallPosition(int ballId, Vector2 pos, double speed) {
    if (speed < 340.0) {
      clearBallTrail(ballId);
      return;
    }
    final history = _motionTrails.putIfAbsent(ballId, () => _BallMotionTrailHistory());
    history.addPosition(pos.x, pos.y);
  }

  /// Xóa toàn bộ hiệu ứng khi reset rack hoặc đổi bàn
  void clearAll() {
    _shockwaves.clear();
    _chalkPuffs.clear();
    _railRipples.clear();
    _pocketVortices.clear();
    _cueHitPulses.clear();
    _animeCueContacts.clear();
    _motionTrails.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Fast early return: nếu không có bất kỳ hiệu ứng nào đang hoạt động
    if (_shockwaves.isEmpty &&
        _chalkPuffs.isEmpty &&
        _railRipples.isEmpty &&
        _pocketVortices.isEmpty &&
        _cueHitPulses.isEmpty &&
        _animeCueContacts.isEmpty &&
        _motionTrails.isEmpty) {
      return;
    }

    // Cập nhật các danh sách hiệu ứng và lọc bỏ các hiệu ứng hết hạn
    _shockwaves.removeWhere((sw) => !sw.update(dt));
    _chalkPuffs.removeWhere((cp) => !cp.update(dt));
    _railRipples.removeWhere((rr) => !rr.update(dt));
    _pocketVortices.removeWhere((pv) => !pv.update(dt));
    _cueHitPulses.removeWhere((chp) => !chp.update(dt));
    _animeCueContacts.removeWhere((acc) => !acc.update(dt));

    // Cập nhật và tiêu tán vệt mờ tốc độ cao của các bi, tự hủy khi hết điểm
    _motionTrails.removeWhere((_, history) => !history.update(dt));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fast early return: tránh gọi vòng lặp render khi không có VFX
    if (_pocketVortices.isEmpty &&
        _railRipples.isEmpty &&
        _motionTrails.isEmpty &&
        _shockwaves.isEmpty &&
        _cueHitPulses.isEmpty &&
        _animeCueContacts.isEmpty &&
        _chalkPuffs.isEmpty) {
      return;
    }

    // 1. Vẽ gợn xoáy tụ hút vào lỗ
    for (int i = 0; i < _pocketVortices.length; i++) {
      _pocketVortices[i].render(canvas, _sharedStrokePaint, _sharedGlowPaint, _sharedFillPaint);
    }

    // 2. Vẽ gợn đàn hồi băng cao su mang phong cách Anime
    for (int i = 0; i < _railRipples.length; i++) {
      _railRipples[i].render(canvas, _sharedStrokePaint, _sharedGlowPaint, _sharedSparkPaint);
    }

    // 3. Vẽ vệt mờ tốc độ cao của các bi (GPU Accelerated Dual-pass halo)
    if (_motionTrails.isNotEmpty) {
      _renderMotionTrails(canvas);
    }

    // 4. Vẽ sóng kích va chạm nảy bi
    for (int i = 0; i < _shockwaves.length; i++) {
      _shockwaves[i].render(canvas, _sharedStrokePaint, _sharedGlowPaint, _sharedFillPaint, _sharedSparkPaint);
    }

    // 5. Vẽ hiệu ứng tiếp xúc gậy cơ độc quyền Anime Concept
    for (int i = 0; i < _animeCueContacts.length; i++) {
      _animeCueContacts[i].render(canvas, _sharedStrokePaint, _sharedGlowPaint, _sharedFillPaint);
    }

    // 6. Vẽ xung chấn tiếp xúc đầu gậy cơ
    for (int i = 0; i < _cueHitPulses.length; i++) {
      _cueHitPulses[i].render(canvas, _sharedStrokePaint, _sharedGlowPaint, _sharedFillPaint);
    }

    // 7. Vẽ bụi lơ gậy cơ
    for (int i = 0; i < _chalkPuffs.length; i++) {
      _chalkPuffs[i].render(canvas, _sharedFillPaint);
    }
  }

  void _renderMotionTrails(Canvas canvas) {
    for (final entry in _motionTrails.entries) {
      final ballId = entry.key;
      final history = entry.value;
      if (history.points.length < 2) continue;

      final isCueBall = ballId == 0;
      final baseColor = isCueBall
          ? const Color(0xFF00E5FF)
          : const Color(0xFFFFD54F);

      for (int i = 0; i < history.points.length - 1; i++) {
        final p0 = history.points[i];
        final p1 = history.points[i + 1];
        final segmentFade = (p0.alphaMultiplier + p1.alphaMultiplier) * 0.5;
        final baseAlpha = (0.28 - i * 0.08).clamp(0.04, 0.35);
        final finalAlpha = (baseAlpha * segmentFade).clamp(0.0, 1.0);

        if (finalAlpha <= 0.01) continue;

        final coreW = (10.0 - i * 2.2).clamp(3.0, 11.0);

        // Pass 1: Quầng sáng mờ halo bên ngoài (100% GPU)
        _sharedTrailGlowPaint
          ..color = baseColor.withValues(alpha: (finalAlpha * 0.35).clamp(0.0, 1.0))
          ..strokeWidth = coreW * 2.2;
        canvas.drawLine(p0.offset, p1.offset, _sharedTrailGlowPaint);

        // Pass 2: Vệt tia sáng lõi sắc sảo
        _sharedTrailCorePaint
          ..color = baseColor.withValues(alpha: (finalAlpha * 0.85).clamp(0.0, 1.0))
          ..strokeWidth = coreW;
        canvas.drawLine(p0.offset, p1.offset, _sharedTrailCorePaint);
      }
    }
  }
}
