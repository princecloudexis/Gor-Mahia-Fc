import 'package:eventsbooking/models/policy_model.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PolicyPage extends ConsumerWidget {
  final String title;
  final AutoDisposeFutureProvider<List<PolicyModel>> contentProvider;

  const PolicyPage({
    super.key,
    required this.title,
    required this.contentProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          _AppBar(title: title),

          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: contentAsync.when(
              loading: () => const _Shimmer(),
              error: (err, _) => SliverFillRemaining(child: _ErrorState()),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PolicyItem(item: list[index])
                        .animate(delay: (80 * (index % 10)).ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.08, curve: Curves.easeOut),
                    childCount: list.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APP BAR — minimal flat
// ─────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final String title;
  const _AppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          size: 20,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// POLICY ITEM — clean expansion tile
// ─────────────────────────────────────────────
class _PolicyItem extends StatefulWidget {
  final PolicyModel item;
  const _PolicyItem({required this.item});

  @override
  State<_PolicyItem> createState() => _PolicyItemState();
}

class _PolicyItemState extends State<_PolicyItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppTheme.primaryPink.withOpacity(0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          onExpansionChanged: (val) => setState(() => _expanded = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const Border(),
          collapsedShape: const Border(),
          // ── Title ──
          title: Text(
            widget.item.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _expanded
                  ? AppTheme.primaryPink
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          // ── Arrow icon ──
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _expanded
                  ? AppTheme.primaryPink.withOpacity(0.1)
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _expanded
                    ? AppTheme.primaryPink.withOpacity(0.3)
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: _expanded
                  ? AppTheme.primaryPink
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          // ── Description ──
          children: [
            Divider(height: 1, color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),
            Text(
              widget.item.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────
class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer(
          color: Theme.of(context).shadowColor,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).splashColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).splashColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
        childCount: 7,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Icon(
              Icons.description_outlined,
              size: 28,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Content Available',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Nothing to display at the moment.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 350.ms),
    );
  }
}

// ─────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentRed.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 28,
                color: AppTheme.accentRed,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Failed to Load',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 350.ms),
      ),
    );
  }
}
