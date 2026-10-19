import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/storage_service.dart';
import '../chat/chat_screen.dart';

class LandlordConversationsScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const LandlordConversationsScreen({
    Key? key,
    required this.propertyId,
    required this.propertyTitle,
  }) : super(key: key);

  @override
  State<LandlordConversationsScreen> createState() => _LandlordConversationsScreenState();
}

class _LandlordConversationsScreenState extends State<LandlordConversationsScreen> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];

  String _getBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    return 'http://10.0.2.2:8000/api';
  }

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/chat/conversations/?property_id=${widget.propertyId}'),
        headers: {'Authorization': 'Bearer ${token.trim()}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _conversations = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inquiries: ${widget.propertyTitle}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No messages for this property yet.'))
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];
                    final buyerName = chat['buyer_username'] ?? 'Tenant';
                    
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(buyerName),
                      subtitle: Text(chat['last_message'] ?? 'Tap to chat...'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final token = await StorageService.getToken();
                        if (!context.mounted || token == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              conversationId: chat['id'],
                              title: widget.propertyTitle,
                              currentUserId: chat['landlord'].toString(),
                              authToken: token.trim(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}