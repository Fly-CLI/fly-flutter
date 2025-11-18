enum FeatureScreen {

  ;

  const FeatureScreen({
    required this.path,
    required this.isProtected,
    required this.semanticsLabel,
  });

  final String path;
  final bool isProtected;
  final String semanticsLabel;
}

