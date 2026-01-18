import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/crops_dictionary_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase - must succeed before using Firebase services
  await Firebase.initializeApp();

  // Verify Firebase is initialized
  if (Firebase.apps.isEmpty) {
    throw Exception('Firebase initialization failed');
  }
  
  // Add error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            try {
              return ThemeService();
            } catch (e) {
              return ThemeService();
            }
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            // AuthService constructor is safe and doesn't access Firebase
            return AuthService();
          },
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'Weather Crops App',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Check if Firebase is initialized before using it
        if (Firebase.apps.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text('Firebase not initialized. Please restart the app.'),
            ),
          );
        }

        // Check current user directly first - this is the most reliable check
        final currentUser = authService.currentUser;
        if (currentUser != null && authService.isAuthenticated) {
          debugPrint('User authenticated via Consumer: ${currentUser.uid}');
          return const MainScreen();
        }

        // Use authService's cached auth stream if available, otherwise show login
        final authStream = authService.authStateChanges;
        if (authStream == null) {
          debugPrint('Auth stream is null, showing login');
          return const LoginScreen();
        }

        return StreamBuilder<User?>(
          stream: authStream,
          initialData: currentUser, // Use current user as initial data
          builder: (context, snapshot) {
            // Handle errors
            if (snapshot.hasError) {
              debugPrint('Auth stream error: ${snapshot.error}');
              // Show login screen on error
              return const LoginScreen();
            }

            // Do not show a loader when connection is waiting after logout; decide by auth state only
            final user = snapshot.data ?? currentUser;
            if (user != null && authService.isAuthenticated) {
              debugPrint('User authenticated in StreamBuilder: ${user.uid}');
              return const MainScreen();
            }

            // Otherwise, show login screen
            debugPrint('User not authenticated in StreamBuilder');
            return const LoginScreen();
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Future<bool> _hasInternetConnection() async {
    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _handleDestinationSelected(int index) async {
    // Only guard Crops + Settings (Dashboard can show cached/default UI).
    if (index == 1 || index == 2) {
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please check your internet connection and try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          // If already on dashboard, allow default back
          Navigator.maybePop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Weather Crops App'),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                const DrawerHeader(
                  child: Center(
                    child: Text('Menu', style: TextStyle(fontSize: 20)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  selected: _currentIndex == 0,
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleDestinationSelected(0);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: const Text('Crops'),
                  selected: _currentIndex == 1,
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleDestinationSelected(1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  selected: _currentIndex == 2,
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleDestinationSelected(2);
                  },
                ),
                const Divider(),
                Consumer<AuthService>(
                  builder: (context, authService, _) {
                    final email = authService.currentUser?.email;
                    return ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: email != null ? Text('Signed in as $email') : null,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Confirm Logout'),
                              ],
                            ),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          try {
                            // Close the drawer first
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }

                            // Await sign out to ensure state is updated cleanly
                            await authService.signOut();

                            // Wait a moment for auth state to propagate
                            await Future.delayed(const Duration(milliseconds: 200));

                            // Navigate back to login screen
                            // Pop all routes until we reach the root (AuthWrapper)
                            // AuthWrapper will automatically show LoginScreen when user is null
                            if (context.mounted) {
                              Navigator.popUntil(context, (route) => route.isFirst);
                              
                              // If still on MainScreen, force navigation to LoginScreen
                              if (context.mounted && !authService.isAuthenticated) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              }
                            }

                            // Show a quick feedback
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logged out successfully'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error logging out: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const DashboardScreen(),
            CropsDictionaryScreen(
              onBack: () {
                if (mounted) {
                  setState(() {
                    _currentIndex = 0;
                  });
                }
              },
            ),
            SettingsScreen(
              onBack: () {
                if (mounted) {
                  setState(() {
                    _currentIndex = 0;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
