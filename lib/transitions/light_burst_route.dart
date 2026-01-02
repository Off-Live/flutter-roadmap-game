import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LightBurstRoute<T> extends PageRouteBuilder<T> {
  LightBurstRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 2000),
    Duration reverseDuration = const Duration(milliseconds: 600),
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          pageBuilder: (_, __, ___) => page,
          opaque: false, // 중요: 오버레이 보이게
          barrierColor: Colors.transparent,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 역방향 애니메이션일 때는 효과 없이 즉시 사라지게
            if (animation.status == AnimationStatus.reverse) {
              return const SizedBox.shrink();
            }

            final easeInCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInCubic,
            );
            final easeOutCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final easeInOutCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );

            // 타임라인 분리:
            // 0.00~0.25 : 빛 확산
            // 0.15~0.35 : 암전(블랙 오버레이) 올라오기
            // 0.30~1.00 : 다음 화면 페이드 인
            final burstT = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: easeInCurve, curve: const Interval(0.0, 0.4)),
            );
            final burstOpacityT = Tween<double>(begin: 1, end: 0).animate(
              CurvedAnimation(parent: easeInCurve, curve: const Interval(0.5, 0.6)),
            );
            final blackoutT = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: easeOutCurve, curve: const Interval(0.4, 0.45)),
            );
            final nextFadeT = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: easeInCurve, curve: const Interval(0.7, 1.0)),
            );

            return Stack(
              children: [
                // 블랙 오버레이
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: blackoutT,
                      builder: (_, __) => Container(
                        color: Colors.black.withOpacity(blackoutT.value),
                      ),
                    ),
                  ),
                ),

                // 이전 화면이 기본으로 깔림(이 Route는 push라서 아래에 이전 화면 존재)
                // 다음 화면(목표 화면)
                FadeTransition(
                  opacity: nextFadeT,
                  child: child,
                ),

                // 중앙 빛(원형 라디얼 그라데이션) 확산 + 배경 블러
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: burstT,
                    builder: (context, _) {
                      final size = MediaQuery.sizeOf(context);
                      // 화면 대각선 길이를 계산하여 원이 전체 화면을 덮도록 함
                      final diagonal = math.max(size.width, size.height);
                      final maxDim = diagonal * 1.2; // 여유를 두어 확실히 덮게
                      final radius = maxDim * burstT.value;

                      return SizedBox.expand(
                        child: Opacity(
                          opacity: burstOpacityT.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: radius / (size.width > size.height ? size.width : size.height),
                                colors: const [
                                  Colors.white,
                                  Colors.white,
                                  Color(0x00FFFFFF),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        )
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
}