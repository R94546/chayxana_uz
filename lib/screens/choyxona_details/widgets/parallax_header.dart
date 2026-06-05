import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/choyxona_model.dart';

class ParallaxHeader extends StatelessWidget {
  final Choyxona choyxona;
  final double scrollOffset;

  const ParallaxHeader({
    super.key,
    required this.choyxona,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    final parallaxOffset = scrollOffset * 0.5;

    return SliverAppBar(
      expandedHeight: 400,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Parallax Image
            Transform.translate(
              offset: Offset(0, -parallaxOffset),
              child: Hero(
                tag: 'choyxona_image_${choyxona.id}',
                child: choyxona.mainImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: choyxona.mainImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Icon(Icons.restaurant, size: 80),
                      ),
              ),
            ),

            // Gradient Overlays
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.transparent,
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
