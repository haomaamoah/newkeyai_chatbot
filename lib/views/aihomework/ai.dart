import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../providers/homework.dart';

class HomeworkSolutionScreen extends StatelessWidget {
  const HomeworkSolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeworkSolutionProvider(),
      child: const _HomeworkSolutionScreenContent(),
    );
  }
}

class _HomeworkSolutionScreenContent extends StatefulWidget {
  const _HomeworkSolutionScreenContent();

  @override
  _HomeworkSolutionScreenContentState createState() =>
      _HomeworkSolutionScreenContentState();
}

class _HomeworkSolutionScreenContentState
    extends State<_HomeworkSolutionScreenContent> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isKeyboardVisible = false;

  // Color scheme for light theme
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color secondaryColor = Color(0xFF00CEFF);
  static const Color backgroundColor = Color(0xFFF8F9FF);
  static const Color botBubbleColor = Colors.white;
  static const Color userBubbleColor = Color(0xFF6C5CE7);
  static const Color textColor = Color(0xFF2D3436);
  static const Color hintColor = Color(0xFFADADAD);

  // Design constants
  static const double _bubbleBorderRadius = 20.0;
  static const double _bubbleElevation = 2.0;
  static const EdgeInsets _bubblePadding = EdgeInsets.symmetric(
    horizontal: 18.0,
    vertical: 14.0,
  );
  static const double _avatarRadius = 18.0;

  final _appBarGradient = const LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00CEFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0) {
        _scrollToBottom();
      }
    }
  }

  @override
  void didChangeMetrics() {
    final bottomInset = PlatformDispatcher.instance.views.first.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _isKeyboardVisible) {
      setState(() => _isKeyboardVisible = newValue);
      if (_isKeyboardVisible) _scrollToBottom(delayMilliseconds: 150);
    }
  }


  void _scrollToBottom({int delayMilliseconds = 300}) {
    Future.delayed(Duration(milliseconds: delayMilliseconds), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'AI Homework Assistance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _appBarGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, size: 24),
            onPressed: () => Provider.of<HomeworkSolutionProvider>(context, listen: false).pickImage(),
            tooltip: 'Scan Homework',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8F9FF),
                    Color(0xFFEFF1FF),
                  ],
                ),
              ),
              child: Consumer<HomeworkSolutionProvider>(
                builder: (context, provider, _) {
                  if (provider.messages.isEmpty) {
                    return _buildEmptyState(provider);
                  }
                  return _buildMessageList(provider);
                },
              ),
            ),
          ),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(HomeworkSolutionProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 100,
            color: primaryColor.withValues(alpha:0.2),
          ),
          const SizedBox(height: 20),
          Text(
            'How can I help with your homework?',
            style: TextStyle(
              fontSize: 18,
              color: textColor.withValues(alpha:0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask a question or scan your assignment',
            style: TextStyle(fontSize: 14, color: hintColor),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => provider.pickImage(),
            icon: const Icon(Icons.camera_alt, size: 20),
            label: const Text('Scan Homework'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 2,
              shadowColor: primaryColor.withValues(alpha:0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(HomeworkSolutionProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        return _buildAnimatedMessageBubble(
          text: message.text,
          isUser: message.role == 'user',
          index: index,
          reactions: message.reactions,
          onAddReaction: (emoji) => provider.addReaction(index, emoji),
        );
      },
    );
  }

  Widget _buildAnimatedMessageBubble({
    required String text,
    required bool isUser,
    required int index,
    required List<String> reactions,
    required Function(String) onAddReaction,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(isUser ? 20 * (1 - clampedValue) : -20 * (1 - clampedValue), 0),
          child: Opacity(
            opacity: clampedValue,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isUser) _buildBotAvatar(),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Card(
                      elevation: _bubbleElevation,
                      color: isUser ? userBubbleColor : botBubbleColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(_bubbleBorderRadius),
                          topRight: const Radius.circular(_bubbleBorderRadius),
                          bottomLeft: Radius.circular(
                              isUser ? _bubbleBorderRadius : _bubbleBorderRadius / 4),
                          bottomRight: Radius.circular(
                              isUser ? _bubbleBorderRadius / 4 : _bubbleBorderRadius),
                        ),
                      ),
                      child: Padding(
                        padding: _bubblePadding,
                        child: _buildMessageContent(text, isUser),
                      ),
                    ),
                  ),
                ),
                if (isUser) _buildUserAvatar(),
              ],
            ),
            if (reactions.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildReactionsRow(reactions, onAddReaction),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String text, bool isUser) {
    final textParts = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: textParts.map((part) {
        if (part.startsWith('HEADING:')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              part.substring(8),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isUser ? Colors.white : primaryColor,
              ),
            ),
          );
        } else if (part.startsWith('STEP:')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: Text(
                    part.substring(5),
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (part.startsWith('FORMULA:')) {
          return Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.white.withValues(alpha:0.1)
                  : primaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              part.substring(8),
              style: TextStyle(
                fontSize: 16,
                color: isUser ? Colors.white : primaryColor,
                fontFamily: 'Courier',
              ),
            ),
          );
        } else if (part.startsWith('POINT:')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isUser ? Colors.white : secondaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    part.substring(6),
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : textColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: MarkdownBody(
              data: part,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 16,
                  color: isUser ? Colors.white : textColor,
                ),
                strong: TextStyle(
                  color: isUser ? Colors.white : primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                em: TextStyle(
                  color: isUser ? Colors.white : secondaryColor,
                  fontStyle: FontStyle.italic,
                ),
                listBullet: TextStyle(
                  color: isUser ? Colors.white : textColor,
                  fontSize: 16,
                ),
                h1: TextStyle(
                  color: isUser ? Colors.white : primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                h2: TextStyle(
                  color: isUser ? Colors.white : primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                h3: TextStyle(
                  color: isUser ? Colors.white : primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                code: TextStyle(
                  backgroundColor: isUser
                      ? Colors.white.withValues(alpha:0.2)
                      : Colors.grey[200],
                  color: isUser ? Colors.white : textColor,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildReactionsRow(List<String> reactions, Function(String) onAddReaction) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...reactions.map((emoji) => GestureDetector(
          onTap: () {}, // Could add functionality to remove reaction
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(emoji),
          ),
        )),
        GestureDetector(
          onTap: () => _showReactionMenu(onAddReaction),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Icon(Icons.add, size: 16),
          ),
        ),
      ],
    );
  }

  void _showReactionMenu(Function(String) onAddReaction) {
    final reactions = ['👍', '👎', '❤️', '😂', '😮', '😢'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: reactions.map((emoji) => GestureDetector(
            onTap: () {
              onAddReaction(emoji);
              Navigator.pop(context);
            },
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: _avatarRadius,
        backgroundColor: secondaryColor.withValues(alpha:0.1),
        child: Icon(
          Icons.school,
          size: 20,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: CircleAvatar(
        radius: _avatarRadius,
        backgroundColor: primaryColor.withValues(alpha:0.9),
        child: const Icon(
          Icons.person,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Consumer<HomeworkSolutionProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: provider.textController,
                    focusNode: _inputFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      hintStyle: const TextStyle(color: hintColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: primaryColor.withValues(alpha:0.6),
                        ),
                        onPressed: () => provider.pickImage(),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: provider.isLoading
                        ? null
                        : (text) => provider.sendMessage(text),
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: provider.isLoading
                    ? Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                )
                    : FloatingActionButton(
                  key: const ValueKey('send_button'),
                  onPressed: provider.isLoading ||
                      provider.textController.text.isEmpty
                      ? null
                      : () {
                    provider.sendMessage(provider.textController.text);
                    _inputFocusNode.unfocus();
                  },
                  backgroundColor: primaryColor,
                  elevation: 2,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}