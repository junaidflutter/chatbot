class User {
  const User({required this.id, required this.email, required this.name});

  final String id;
  final String email;
  final String name;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
    'user': user.toJson(),
  };
}

class Citation {
  const Citation({
    required this.documentId,
    required this.filename,
    required this.chunkIndex,
    required this.score,
    required this.excerpt,
  });

  final String documentId;
  final String filename;
  final int chunkIndex;
  final double score;
  final String excerpt;

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      documentId: json['document_id']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      chunkIndex: int.tryParse(json['chunk_index']?.toString() ?? '') ?? 0,
      score: double.tryParse(json['score']?.toString() ?? '') ?? 0,
      excerpt: json['excerpt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'document_id': documentId,
    'filename': filename,
    'chunk_index': chunkIndex,
    'score': score,
    'excerpt': excerpt,
  };
}

class ChatReply {
  const ChatReply({
    required this.answer,
    required this.fromDocument,
    required this.fromAi,
    required this.citations,
    required this.sources,
  });

  final String answer;
  final bool fromDocument;
  final bool fromAi;
  final List<Citation> citations;
  final List<Citation> sources;

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    final rawCitations = (json['citations'] as List<dynamic>? ?? const [])
        .map(
          (item) => Citation.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final rawSources = (json['sources'] as List<dynamic>? ?? const [])
        .map(
          (item) => Citation.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    return ChatReply(
      answer: json['answer']?.toString() ?? '',
      fromDocument: json['from_document'] == true,
      fromAi: json['from_ai'] != false,
      citations: rawCitations,
      sources: rawSources,
    );
  }
}

class Message {
  const Message({
    required this.text,
    this.id = '',
    this.sessionId = '',
    this.role = '',
    this.clientId,
    this.timestamp,
    this.isFromAdmin = false,
    this.fromDocument = false,
    this.fromAi = true,
    this.isLoading = false,
    this.citations = const [],
  });

  final String id;
  final String sessionId;
  final String role;
  final String text;
  final String? clientId;
  final DateTime? timestamp;
  final bool isFromAdmin;
  final bool fromDocument;
  final bool fromAi;
  final bool isLoading;
  final List<Citation> citations;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      text: json['message']?.toString() ?? json['text']?.toString() ?? '',
      clientId: json['clientId']?.toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
      isFromAdmin:
          json['isFromAdmin'] == true ||
          json['from_admin'] == true ||
          json['sender']?.toString() == 'admin',
      fromDocument: json['from_document'] == true,
      fromAi: json['from_ai'] != false,
      isLoading: json['is_loading'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'role': role,
    'message': text,
    'clientId': clientId,
    'timestamp': timestamp?.toIso8601String(),
    'isFromAdmin': isFromAdmin,
    'from_document': fromDocument,
    'from_ai': fromAi,
    'is_loading': isLoading,
  };

  Message copyWith({
    String? id,
    String? sessionId,
    String? role,
    String? text,
    String? clientId,
    DateTime? timestamp,
    bool? isFromAdmin,
    bool? fromDocument,
    bool? fromAi,
    bool? isLoading,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      text: text ?? this.text,
      clientId: clientId ?? this.clientId,
      timestamp: timestamp ?? this.timestamp,
      isFromAdmin: isFromAdmin ?? this.isFromAdmin,
      fromDocument: fromDocument ?? this.fromDocument,
      fromAi: fromAi ?? this.fromAi,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatHistoryResponse {
  const ChatHistoryResponse({required this.sessionId, required this.messages});

  final String sessionId;
  final List<Message> messages;

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    final messages = (json['messages'] as List<dynamic>? ?? const [])
        .map(
          (item) => Message.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    return ChatHistoryResponse(
      sessionId: json['session_id']?.toString() ?? '',
      messages: messages,
    );
  }
}

class DocumentInfo {
  const DocumentInfo({
    required this.documentId,
    required this.filename,
    required this.chunkCount,
    required this.createdAt,
  });

  final String documentId;
  final String filename;
  final int chunkCount;
  final String createdAt;

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      documentId: json['document_id']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      chunkCount: int.tryParse(json['chunk_count']?.toString() ?? '') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class DocumentUploadResult {
  const DocumentUploadResult({
    required this.uploadedFiles,
    required this.totalChunks,
  });

  final List<String> uploadedFiles;
  final int totalChunks;

  factory DocumentUploadResult.fromJson(Map<String, dynamic> json) {
    return DocumentUploadResult(
      uploadedFiles: (json['uploaded_files'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      totalChunks: int.tryParse(json['total_chunks']?.toString() ?? '') ?? 0,
    );
  }
}

class SocketChatChunk {
  const SocketChatChunk({required this.sessionId, required this.chunk});

  final String sessionId;
  final String chunk;

  factory SocketChatChunk.fromJson(Map<String, dynamic> json) {
    return SocketChatChunk(
      sessionId: json['session_id']?.toString() ?? '',
      chunk: json['chunk']?.toString() ?? '',
    );
  }
}

class VoiceTranscript {
  const VoiceTranscript({required this.sessionId, required this.question});

  final String sessionId;
  final String question;

  factory VoiceTranscript.fromJson(Map<String, dynamic> json) {
    return VoiceTranscript(
      sessionId: json['session_id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
    );
  }
}
