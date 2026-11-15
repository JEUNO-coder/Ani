import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_shell.dart';
import 'app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AniApp());
}

/// Root widget. Pass [state] to inject an [AppState] (tests); otherwise one
/// is created and initialised from saved settings.
class AniApp extends StatefulWidget {
  const AniApp({super.key, this.state, this.showSplash});

  final AppState? state;
  final bool? showSplash;

  @override
  State<AniApp> createState() => _AniAppState();
}

class _AniAppState extends State<AniApp> {
  late final AppState _state = widget.state ?? AppState();

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  void dispose() {
    if (widget.state == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AniTheme.light(),
          locale: _state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _Root(showSplash: widget.showSplash ?? (widget.state == null)),
        ),
      ),
    );
  }
}

/// Chooses splash / onboarding / error / shell from [AppState].
class _Root extends StatefulWidget {
  const _Root({this.showSplash = true});

  final bool showSplash;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late bool _splashDone = !widget.showSplash;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () {
          if (mounted) setState(() => _splashDone = true);
        },
      );
    }
    if (!state.initialized) return const _SplashLoading();
    if (!state.onboardingComplete) return const OnboardingScreen();
    if (state.bundle != null) return const AppShell();
    if (state.bundleError != null) return _BundleError(state: state);
    return const _SplashLoading();
  }
}

/// Loading indicator when initialized state is pending after splash.
class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AniColors.cream,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3, color: AniColors.olive),
        ),
      ),
    );
  }
}

/// Splash / starting screen with animated fade-in and fade-out of logowithtext.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onComplete,
    this.duration = const Duration(milliseconds: 2000),
  });

  final VoidCallback? onComplete;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('splash'),
      backgroundColor: AniColors.cream,
      body: Center(
        child: FadeTransition(
          key: const ValueKey('splash-fade'),
          opacity: _opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AniSpacing.xxl),
            child: Image.asset(
              'assets/icon/logowithtext.png',
              width: 260,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _BundleError extends StatelessWidget {
  const _BundleError({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('bundle-error'),
      backgroundColor: AniColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AniSpacing.xxl),
            child: AniCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.error_outline, color: AniColors.statusDelikado, size: 32),
                  const SizedBox(height: AniSpacing.md),
                  Text(
                    l.bundleLoadError,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (state.town != null) ...[
                    const SizedBox(height: AniSpacing.xs),
                    Text(
                      state.town!.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AniColors.muted),
                    ),
                  ],
                  const SizedBox(height: AniSpacing.lg),
                  PrimaryButton(
                    label: l.actionRetry,
                    icon: Icons.refresh,
                    onPressed: state.bundleLoading ? null : state.retryBundle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
