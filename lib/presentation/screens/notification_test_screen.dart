import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../../core/services/notification_manager.dart';
import '../../di/injection_container.dart' as di;

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _notificationManager = di.sl<NotificationManager>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String _status = 'No test performed yet.';

  // Logs for tracking
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Budgie Test';
    _messageController.text =
        'Payment of RM 25.50 at Starbucks has been processed';
    _checkPermission();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission =
        await _notificationManager.checkNotificationPermission();
    final hasListenerPermission = Platform.isAndroid
        ? await _notificationManager.checkNotificationListenerPermission()
        : true;

    _addLog('Notification permission: $hasPermission');
    _addLog('Notification listener permission: $hasListenerPermission');

    setState(() {
      _status = 'Notification permission: $hasPermission\n'
          'Notification listener permission: $hasListenerPermission';
    });
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting permissions...';
    });

    try {
      final result =
          await _notificationManager.requestAllNotificationPermissions();
      _addLog('Permission request result: $result');

      setState(() {
        _status = 'Permission request result: $result';
      });

      // Re-check permissions after request
      await _checkPermission();
    } catch (e) {
      _addLog('Error requesting permissions: $e');
      setState(() {
        _status = 'Error requesting permissions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Start the notification listener service
  Future<void> _startNotificationListener() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting notification listener...';
    });

    try {
      await _notificationManager.startNotificationListener();
      final isListening = _notificationManager.isListening;
      _addLog('Notification listener started, isListening: $isListening');

      setState(() {
        _status = 'Notification listener started: $isListening';
      });
    } catch (e) {
      _addLog('Error starting notification listener: $e');
      setState(() {
        _status = 'Error starting notification listener: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test sending a notification
  Future<void> _sendTestExpenseNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Sending test expense notification...';
    });

    try {
      await _notificationManager.sendTestExpenseNotification();
      _addLog('Test expense notification sent');

      setState(() {
        _status = 'Test expense notification sent. Check if it was detected.';
      });
    } catch (e) {
      _addLog('Error sending test notification: $e');
      setState(() {
        _status = 'Error sending test notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Send custom notification
  Future<void> _sendCustomNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      setState(() {
        _status = 'Title and message cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Sending custom notification...';
    });

    try {
      await _notificationManager.sendTestCustomNotification(
        title: title,
        body: message,
      );
      _addLog('Custom notification sent: $title - $message');

      setState(() {
        _status = 'Custom notification sent. Check if it was detected.';
      });
    } catch (e) {
      _addLog('Error sending custom notification: $e');
      setState(() {
        _status = 'Error sending custom notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test the notification service without sending a notification
  Future<void> _testExpenseSimulation() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing expense simulation...';
    });

    try {
      await _notificationManager.simulateExpenseWorkflow();
      _addLog('Expense simulation completed');

      setState(() {
        _status = 'Expense simulation completed.';
      });
    } catch (e) {
      _addLog('Error in expense simulation: $e');
      setState(() {
        _status = 'Error in expense simulation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String log) {
    setState(() {
      _logs.add('[${DateTime.now().toString()}] $log');

      // Scroll to bottom after adding log
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  // Clear logs
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(_status),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permissions',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _requestPermission,
                              icon: const Icon(Icons.security),
                              label: const Text(
                                  'Request Notification Permissions'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _checkPermission,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Check Permissions'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification Service',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _startNotificationListener,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Notification Listener'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test Notifications',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _sendTestExpenseNotification,
                              icon: const Icon(Icons.notification_important),
                              label:
                                  const Text('Send Test Expense Notification'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Notification Title',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Notification Message',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _sendCustomNotification,
                              icon: const Icon(Icons.send),
                              label: const Text('Send Custom Notification'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _testExpenseSimulation,
                              icon: const Icon(Icons.run_circle),
                              label: const Text('Simulate Expense Processing'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Log',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    final text = _logs.join('\n');
                                    Clipboard.setData(
                                        ClipboardData(text: text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Logs copied to clipboard')),
                                    );
                                  },
                                  tooltip: 'Copy logs',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  controller: _logScrollController,
                                  itemCount: _logs.length,
                                  itemBuilder: (context, index) {
                                    return Text(
                                      _logs[index],
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
