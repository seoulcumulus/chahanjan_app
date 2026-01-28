import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final String? initialNickname;

  const OnboardingScreen({super.key, this.initialNickname});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late TextEditingController _nicknameController;
  final List<String> _interests = ['Coffee', 'Tea', 'Dessert', 'Study', 'Chat', 'Date'];
  final List<String> _selectedInterests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a nickname')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nickname': _nicknameController.text,
        'interests': _selectedInterests,
        'is_new': false, // Mark as not new
      });

      // Update UserProvider
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        // We need to fetch the updated user data or update local state
        // Since UserProvider doesn't have a fetch method exposed easily yet, we can manually update the map
        // But better to just navigate and let MapScreen fetch it?
        // MapScreen fetches nearby users, but not "Me" explicitly in init.
        // Let's update the provider's user object manually for now.
        final updatedUser = Map<String, dynamic>.from(userProvider.user!);
        updatedUser['nickname'] = _nicknameController.text;
        updatedUser['interests'] = _selectedInterests;
        updatedUser['is_new'] = false;
        userProvider.setUser(updatedUser);

        Navigator.of(context).pushReplacementNamed('/map');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome!')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Let\'s get to know you!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Interests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              children: _interests.map((interest) {
                return FilterChip(
                  label: Text(interest),
                  selected: _selectedInterests.contains(interest),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeOnboarding,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Start ChaHanJan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
