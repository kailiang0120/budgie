import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/constants/routes.dart';
import '../../core/router/page_transition.dart';
import '../widgets/auth_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/animated_float_button.dart';
import 'add_expense_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _handleLogout(BuildContext context) async {
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    await viewModel.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(Routes.login);
    }
  }

  void _handleSwitchAccount(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context);
    final user = viewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
            child: user?.photoUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'User',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                AuthButton(
                  label: 'Log out',
                  leadingIcon: const Icon(Icons.logout),
                  backgroundColor: const Color(0xff1A1A19),
                  onPressed: () => _handleLogout(context),
                ),
                const SizedBox(height: 12),
                AuthButton(
                  label: 'Switch Account',
                  leadingIcon: const Icon(Icons.switch_account),
                  backgroundColor: const Color(0xff1A1A19),
                  onPressed: () => _handleSwitchAccount(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
      extendBody: true,
      floatingActionButton: AnimatedFloatButton(
        onPressed: () {
          Navigator.push(
            context,
            PageTransition(
              child: const AddExpenseScreen(),
              type: TransitionType.fadeAndSlideUp,
              settings: const RouteSettings(name: Routes.expenses),
            ),
          );
        },
        backgroundColor: const Color(0xFFF57C00),
        shape: const CircleBorder(),
        enableFeedback: true,
        reactToRouteChange: true,
        child: const Icon(Icons.add, color: Color(0xFFFBFCF8)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (idx) {
          // Navigation is handled in BottomNavBar
        },
      ),
    );
  }
}
