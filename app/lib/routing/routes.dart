/// Route paths. Kept apart from the router so features can link without
/// importing GoRouter configuration.
library;

abstract final class Routes {
  static const onboarding = '/welcome';
  static const unlock = '/unlock';
  static const opening = '/opening';
  static const vault = '/';
  static const settings = '/settings';

  static String entry(String id) => '/entry/$id';

  static const entryPattern = '/entry/:id';
}
