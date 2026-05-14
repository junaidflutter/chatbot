import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_bot_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';

import 'package:chat_bot_app/gen/assets.gen.dart';
import 'shimmer_widget.dart';

class NetworkImageView extends StatelessWidget {
  final String? _imageUrl;
  final BoxFit fit;
  final double? height;
  final double? width;
  final Color? color;
  final bool isProfileImage;
  final bool isMainScreen;

  const NetworkImageView(
    this._imageUrl, {
    super.key,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.color,
    this.isProfileImage = false,
    this.isMainScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return (_imageUrl == null || _imageUrl.isEmpty)
        ? _buildErrorView()
        : CachedNetworkImage(
            height: height,
            width: width,
            imageUrl: _imageUrl,
            fit: fit,
            placeholder: (_, _) => const ShimmerLoadingWidget(
              isLoading: true,
              child: ColoredBox(color: Colors.black),
            ),
            errorWidget: (_, _, _) => _buildErrorView(),
          );
  }

  Widget _buildErrorView() => ColoredBox(
    color: ColorName.darkGrey,
    child: isProfileImage
        ? Container(
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              Icons.person,
              size: isMainScreen ? 28 : 80,
              color: Colors.grey.shade300,
            ),
          )
        : Assets.icons.placeHolderSvg_.svg(
            fit: BoxFit.cover,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
            height: height,
            width: width,
          ),
  );
}
