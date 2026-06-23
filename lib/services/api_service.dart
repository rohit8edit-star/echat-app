import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../models/models.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async => await _storage.read(key: 'token');
  static Future<void> saveToken(String t) async => await _storage.write(key: 'token', value: t);
  static Future<void> clearToken() async => await _storage.delete(key: 'token');

  static Future<Map<String, String>> _h({bool auth = true}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await getToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  // ── AUTH ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name, required String username,
    required String phone, required String email, required String password,
  }) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/auth/register'),
        headers: await _h(auth: false),
        body: jsonEncode({'name': name, 'username': username, 'phone': phone, 'email': email, 'password': password}));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> verifyRegisterOTP(String email, String otp) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/auth/register/verify'),
        headers: await _h(auth: false), body: jsonEncode({'email': email, 'otp': otp}));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/auth/login'),
        headers: await _h(auth: false), body: jsonEncode({'phone': phone, 'password': password}));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> verifyLoginOTP(String email, String otp) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/auth/login/verify'),
        headers: await _h(auth: false), body: jsonEncode({'email': email, 'otp': otp}));
    return jsonDecode(r.body);
  }

  static Future<void> logout() async {
    await http.post(Uri.parse('${AppConstants.baseUrl}/api/auth/logout'), headers: await _h());
    await clearToken();
  }

  // ── CONTACTS ──────────────────────────────────────────
  static Future<List<UserModel>> getContacts() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/api/contacts'), headers: await _h());
    final d = jsonDecode(r.body);
    return d['success'] ? (d['contacts'] as List).map((c) => UserModel.fromJson(c)).toList() : [];
  }

  static Future<Map<String, dynamic>> searchUser(String phone) async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/api/contacts/search?phone=$phone'), headers: await _h());
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> addContact(String contactId) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/contacts'),
        headers: await _h(), body: jsonEncode({'contact_id': contactId}));
    return jsonDecode(r.body);
  }

  static Future<List<dynamic>> getMessageRequests() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/api/contacts/requests'), headers: await _h());
    return jsonDecode(r.body)['requests'] ?? [];
  }

  static Future<Map<String, dynamic>> respondToRequest(int requestId, String action) async {
    final r = await http.put(Uri.parse('${AppConstants.baseUrl}/api/contacts/requests/respond'),
        headers: await _h(), body: jsonEncode({'request_id': requestId, 'action': action}));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> sendMessageRequest(String receiverId) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/contacts/requests'),
        headers: await _h(), body: jsonEncode({'receiver_id': receiverId}));
    return jsonDecode(r.body);
  }

  // ── CONVERSATIONS ─────────────────────────────────────
  static Future<List<ConversationModel>> getConversations() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/api/conversations'), headers: await _h());
    final d = jsonDecode(r.body);
    return d['success'] ? (d['conversations'] as List).map((c) => ConversationModel.fromJson(c)).toList() : [];
  }

  static Future<String?> getOrCreateConversation(String contactId) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/conversations'),
        headers: await _h(), body: jsonEncode({'contact_id': contactId}));
    final d = jsonDecode(r.body);
    return d['success'] ? d['conversation_id'] : null;
  }

  static Future<List<MessageModel>> getMessages(String convId, {int page = 1}) async {
    final r = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/conversations/$convId/messages?page=$page'),
        headers: await _h());
    final d = jsonDecode(r.body);
    return d['success'] ? (d['messages'] as List).map((m) => MessageModel.fromJson(m)).toList() : [];
  }

  // ── PROFILE ───────────────────────────────────────────
  static Future<UserModel?> getProfile() async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/api/users/profile'), headers: await _h());
    final d = jsonDecode(r.body);
    return d['success'] ? UserModel.fromJson(d['user']) : null;
  }

  static Future<Map<String, dynamic>> updateProfile({String? name, String? username}) async {
    final r = await http.put(Uri.parse('${AppConstants.baseUrl}/api/users/profile'),
        headers: await _h(), body: jsonEncode({'name': name, 'username': username}));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> changePassword(String oldPw, String newPw) async {
    final r = await http.put(Uri.parse('${AppConstants.baseUrl}/api/users/password'),
        headers: await _h(), body: jsonEncode({'old_password': oldPw, 'new_password': newPw}));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> blockUser(String userId) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/users/block'),
        headers: await _h(), body: jsonEncode({'user_id': userId}));
    return jsonDecode(r.body);
  }

  // ── GROUPS ────────────────────────────────────────────
  static Future<Map<String, dynamic>> createGroup(String name, List<String> memberIds) async {
    final r = await http.post(Uri.parse('${AppConstants.baseUrl}/api/groups'),
        headers: await _h(), body: jsonEncode({'name': name, 'member_ids': memberIds}));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> getGroupInfo(String convId) async {
    final r = await http.get(Uri.parse('${AppConstants.baseUrl}/api/groups/$convId'), headers: await _h());
    return jsonDecode(r.body);
  }

  // ── FCM ───────────────────────────────────────────────
  static Future<void> saveFcmToken(String token) async {
    try {
      await http.post(Uri.parse('${AppConstants.baseUrl}/api/notifications/token'),
          headers: await _h(), body: jsonEncode({'token': token, 'device': 'android'}));
    } catch (_) {}
  }

  static Future<void> deleteFcmToken(String token) async {
    try {
      await http.delete(Uri.parse('${AppConstants.baseUrl}/api/notifications/token'),
          headers: await _h(), body: jsonEncode({'token': token}));
    } catch (_) {}
  }
}
