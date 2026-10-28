import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The one avatar used everywhere: profile photo (base64 or URL) with an
/// initials fallback. A base64 photo is decoded only when it changes.
class UserAvatar extends StatefulWidget {
  final String? photo;
  final String name;
  final double size;

  /// True when drawn on the primary-coloured app bar or a gradient card.
  final bool onPrimary;

  const UserAvatar({
    super.key,
    required this.photo,
    required this.name,
    this.size = 36,
    this.onPrimary = false,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo != widget.photo) _decode();
  }

  void _decode() {
    final photo = widget.photo;
    if (photo != null && photo.startsWith('data:image')) {
      try {
        _bytes = base64Decode(photo.split(',').last);
      } catch (_) {
        _bytes = null;
      }
    } else {
      _bytes = null;
    }
  }

  String get _initials {
    final words =
        widget.name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return 'U';
    final list = words.toList();
    if (list.length == 1) return list[0][0].toUpperCase();
    return '${list[0][0]}${list[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = widget.photo;

    ImageProvider? image;
    if (_bytes != null) {
      image = MemoryImage(_bytes!);
    } else if (photo != null && photo.startsWith('http')) {
      image = NetworkImage(photo);
    }

    final background = widget.onPrimary
        ? Colors.white.withValues(alpha: 0.22)
        : theme.primaryColor.withValues(alpha: 0.15);
    final foreground = widget.onPrimary ? Colors.white : theme.primaryColor;

    Widget fallback() => Container(
          color: background,
          alignment: Alignment.center,
          child: Text(
            _initials,
            style: GoogleFonts.poppins(
              fontSize: widget.size * 0.38,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        );

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.onPrimary
              ? Colors.white70
              : theme.primaryColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: image != null
            ? Image(
                image: image,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => fallback(),
              )
            : fallback(),
      ),
    );
  }
}
